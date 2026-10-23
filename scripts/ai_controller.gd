class_name AIController
extends Node

# AIController: Real-time autonomous AI using Automatic Aim + Hold-to-Charge + Release-to-Fire

@export var cannon: Cannon
@export var target_cannon: Cannon

var difficulty: GameState.AIDifficulty = GameState.AIDifficulty.NORMAL

var decision_timer: float = 0.0
var decision_interval: float = 0.3 # Periodic recalculation of optimal ballistic target

var target_angle: float = deg_to_rad(-140.0)
var target_power_pct: float = 0.55

# Aim & release timing parameters per difficulty
var angle_window: float = deg_to_rad(3.5)
var power_window: float = 0.04
var cooldown_between_shots: float = 0.8
var shot_cooldown_timer: float = 0.0

func _ready() -> void:
	difficulty = GameState.current_difficulty
	_setup_difficulty_parameters()
	_compute_solution()

func _setup_difficulty_parameters() -> void:
	match difficulty:
		GameState.AIDifficulty.EASY:
			angle_window = deg_to_rad(6.0)
			power_window = 0.08
			cooldown_between_shots = randf_range(1.2, 1.8)
		GameState.AIDifficulty.NORMAL:
			angle_window = deg_to_rad(3.5)
			power_window = 0.04
			cooldown_between_shots = randf_range(0.8, 1.2)
		GameState.AIDifficulty.HARD:
			angle_window = deg_to_rad(1.8)
			power_window = 0.02
			cooldown_between_shots = randf_range(0.5, 0.8)

func _physics_process(delta: float) -> void:
	if not cannon or cannon.is_dead or not target_cannon or target_cannon.is_dead:
		return
	
	if shot_cooldown_timer > 0.0:
		shot_cooldown_timer -= delta
		return
	
	decision_timer -= delta
	if decision_timer <= 0.0:
		decision_timer = decision_interval
		_compute_solution()
	
	if not cannon.is_charging:
		# Check if the sweeping barrel is pointing close enough to our target angle
		var cur_rot = cannon.barrel_pivot.rotation
		var diff = abs(wrapf(cur_rot - target_angle, -PI, PI))
		
		if diff <= angle_window and cannon.can_fire():
			# Press and hold! Locks barrel angle and begins charging at 0%
			cannon.start_charging()
	else:
		# Currently charging! Monitor power meter oscillating between 0% and 100%
		var cur_pct = cannon.charge_pct
		var is_up = cannon.is_charge_increasing
		
		# Check if power has reached the target power percentage
		var ready_to_release = false
		if is_up and cur_pct >= target_power_pct:
			ready_to_release = true
		elif not is_up and cur_pct <= target_power_pct:
			ready_to_release = true
		elif abs(cur_pct - target_power_pct) <= power_window:
			ready_to_release = true
		
		if ready_to_release:
			cannon.release_and_fire()
			_setup_difficulty_parameters()
			shot_cooldown_timer = cooldown_between_shots

func _compute_solution() -> void:
	if not cannon or not target_cannon:
		return
	
	var start_pos = cannon.muzzle.global_position
	var target_pos = target_cannon.global_position + Vector2(0, -10)
	
	var delta_pos = target_pos - start_pos
	var g = 720.0
	var w = GameState.current_wind if GameState.wind_enabled else 0.0
	
	var best_angle = deg_to_rad(-145.0)
	var best_power = 650.0
	var min_miss = 99999.0
	
	# Sample angles in playable arc (-170 deg to -105 deg for Red facing left)
	for deg in range(-168, -102, 3):
		var angle = deg_to_rad(float(deg))
		var cos_a = cos(angle)
		var sin_a = sin(angle)
		
		for pow_val in range(int(cannon.min_power), int(cannon.max_power), 25):
			var v = float(pow_val)
			var vx = v * cos_a
			var vy = v * sin_a
			
			var t = 0.0
			if abs(w) < 0.1:
				if abs(vx) > 1.0:
					t = delta_pos.x / vx
			else:
				var disc = vx * vx + 2.0 * w * delta_pos.x
				if disc >= 0.0:
					var t1 = (-vx - sqrt(disc)) / w
					var t2 = (-vx + sqrt(disc)) / w
					if t1 > 0.05:
						t = t1
					elif t2 > 0.05:
						t = t2
			
			if t > 0.2 and t < 4.0:
				var sim_y = vy * t + 0.5 * g * t * t
				var miss = abs(sim_y - delta_pos.y)
				if miss < min_miss:
					min_miss = miss
					best_angle = angle
					best_power = v
	
	# Add difficulty noise
	var angle_noise = 0.0
	var power_noise_pct = 0.0
	
	match difficulty:
		GameState.AIDifficulty.EASY:
			angle_noise = deg_to_rad(randf_range(-12.0, 12.0))
			power_noise_pct = randf_range(-0.15, 0.15)
		GameState.AIDifficulty.NORMAL:
			angle_noise = deg_to_rad(randf_range(-4.0, 4.0))
			power_noise_pct = randf_range(-0.05, 0.05)
		GameState.AIDifficulty.HARD:
			angle_noise = deg_to_rad(randf_range(-1.2, 1.2))
			power_noise_pct = randf_range(-0.015, 0.015)
	
	target_angle = clampf(best_angle + angle_noise, cannon.min_angle, cannon.max_angle)
	var raw_pct = (best_power - cannon.min_power) / (cannon.max_power - cannon.min_power)
	target_power_pct = clampf(raw_pct + power_noise_pct, 0.05, 0.98)
