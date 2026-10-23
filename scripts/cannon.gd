class_name Cannon
extends CharacterBody2D

# Cannon: Automatic barrel sweep + Hold-to-charge + Release-to-fire 2D artillery cannon
# Gravity: CharacterBody2D with move_and_slide() so the cannon falls when terrain is destroyed.

signal fired(projectile_instance: Node)
signal health_changed(current: int, maximum: int)
signal destroyed(cannon_instance: Cannon)

enum PlayerID { BLUE = 1, RED = 2 }

@export var player_id: PlayerID = PlayerID.BLUE
@export var is_ai_controlled: bool = false
@export var max_health: int = 3
@export var min_power: float = 380.0
@export var max_power: float = 960.0
@export var sweep_speed: float = 1.35 # Radians/sec (~2.3s to sweep 180 degrees)
@export var charge_speed: float = 1.15 # 0% to 100% in ~0.87s, full cycle in ~1.74s
@export var fire_cooldown: float = 0.75 # Seconds

# Physics
const GRAVITY: float = 900.0   # px/s² downward — same order as projectile gravity
const MAX_FALL_SPEED: float = 1200.0
const OOB_Y: float = 760.0     # Below this y the cannon has fallen off the map

# Colors
@export var hull_color: Color = Color(0.0, 0.85, 0.95) # Cyan for Blue
@export var outline_color: Color = Color(0.08, 0.08, 0.12)
@export var barrel_color: Color = Color(0.92, 0.93, 0.95)
@export var health_pip_color: Color = Color(0.2, 0.95, 0.45)
@export var health_pip_empty_color: Color = Color(0.2, 0.25, 0.3, 0.6)

# State
var current_health: int = 3
var current_power: float = 380.0
var cooldown_timer: float = 0.0
var is_dead: bool = false

# Automatic sweep variables (180 degree aiming arc: -180 deg to 0 deg)
var min_angle: float = -PI # -180 deg (horizontal left)
var max_angle: float = 0.0  # 0 deg (horizontal right)
var sweep_direction: float = 1.0 # +1.0 = clockwise (down-right), -1.0 = counter-clockwise (up-left)

# Hold-to-charge state
var is_charging: bool = false
var charge_pct: float = 0.0
var is_charge_increasing: bool = true
var locked_angle: float = -PI * 0.25 # Angle locked when key is pressed

# Designated input action
var fire_action: String = "blue_fire"

@onready var barrel_pivot: Node2D = $BarrelPivot
@onready var barrel_mesh: Node2D = $BarrelPivot/Barrel
@onready var muzzle: Marker2D = $BarrelPivot/Barrel/Muzzle
@onready var visuals: Node2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Projectile preloaded scene
var projectile_scene: PackedScene = preload("res://scenes/Projectile.tscn")
var impact_scene: PackedScene = preload("res://scenes/ImpactEffect.tscn")

func _ready() -> void:
	current_health = max_health
	if player_id == PlayerID.BLUE:
		hull_color = Color(0.0, 0.82, 0.95) # Cyan / Turquoise
		fire_action = "blue_fire"
		# Blue starts at -25 deg, sweeping upwards towards -180 deg
		barrel_pivot.rotation = deg_to_rad(-25.0)
		sweep_direction = -1.0
	else:
		hull_color = Color(1.0, 0.38, 0.38) # Coral / Orange-Red
		fire_action = "red_fire"
		# Red starts at -155 deg, sweeping upwards towards 0 deg
		barrel_pivot.rotation = deg_to_rad(-155.0)
		sweep_direction = 1.0
	
	health_changed.emit(current_health, max_health)
	visuals.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead or is_ai_controlled or get_tree().paused:
		return
	
	if event.is_echo():
		return
	
	if event.is_action_pressed(fire_action):
		start_charging()
	elif event.is_action_released(fire_action):
		release_and_fire()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_charging:
		cancel_charging()

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	if is_dead:
		return
	
	# --- Gravity & terrain support ---
	# Always apply gravity unless standing on terrain (is_on_floor()).
	# CharacterBody2D.move_and_slide() uses `velocity` and handles collision vs
	# the terrain StaticBody2D (collision layer 1, cannon mask 1).
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	else:
		velocity.y = 0.0
	
	# No horizontal movement from physics; cannon only moves vertically.
	velocity.x = 0.0
	move_and_slide()
	
	# Out-of-bounds safety: cannon fell off the bottom of the map
	if global_position.y > OOB_Y and not is_dead:
		# Treat as lethal damage (fallen into the abyss)
		take_damage(max_health, PlayerID.BLUE if player_id == PlayerID.RED else PlayerID.RED)
		return
	
	if is_charging:
		# Angle is locked! Update the charging meter smoothly up and down
		_process_charging(delta)
	else:
		# Automatic barrel sweep through configured 180-degree arc
		_process_sweeping(delta)
	
	visuals.queue_redraw()

func _process_sweeping(delta: float) -> void:
	var next_rot = barrel_pivot.rotation + sweep_direction * sweep_speed * delta
	if next_rot >= max_angle:
		next_rot = max_angle
		sweep_direction = -1.0 # Reverse to counter-clockwise
	elif next_rot <= min_angle:
		next_rot = min_angle
		sweep_direction = 1.0  # Reverse to clockwise
	
	barrel_pivot.rotation = next_rot

func _process_charging(delta: float) -> void:
	if is_charge_increasing:
		charge_pct += charge_speed * delta
		if charge_pct >= 1.0:
			charge_pct = 1.0
			is_charge_increasing = false # Reverse: start decreasing
	else:
		charge_pct -= charge_speed * delta
		if charge_pct <= 0.0:
			charge_pct = 0.0
			is_charge_increasing = true  # Reverse: start increasing
	
	current_power = lerpf(min_power, max_power, charge_pct)

func can_fire() -> bool:
	return cooldown_timer <= 0.0 and not is_dead and not is_charging

func start_charging() -> bool:
	if cooldown_timer > 0.0 or is_dead or is_charging:
		return false
	
	# 3. Immediately stop automatic barrel rotation and lock current barrel angle
	locked_angle = barrel_pivot.rotation
	is_charging = true
	# 4. Start charging meter at 0% on initial key press
	charge_pct = 0.0
	is_charge_increasing = true
	current_power = min_power
	visuals.queue_redraw()
	return true

func release_and_fire() -> bool:
	if not is_charging or is_dead:
		return false
	
	# Calculate final power at precise moment of release
	current_power = lerpf(min_power, max_power, charge_pct)
	barrel_pivot.rotation = locked_angle
	
	# 6. Immediately fire exactly one missile using locked angle and current power
	var fired_proj = _spawn_missile()
	
	# 7. After firing, reset charging state and resume automatic barrel rotation
	is_charging = false
	charge_pct = 0.0
	is_charge_increasing = true
	cooldown_timer = fire_cooldown
	
	visuals.queue_redraw()
	return fired_proj != null

func cancel_charging() -> void:
	is_charging = false
	charge_pct = 0.0
	is_charge_increasing = true
	visuals.queue_redraw()

func _spawn_missile() -> Projectile:
	var proj = projectile_scene.instantiate() as Projectile
	var fire_dir = Vector2.from_angle(locked_angle)
	var spawn_pos = muzzle.global_position
	
	proj.setup(spawn_pos, fire_dir * current_power, player_id, self)
	
	var game_root = get_tree().current_scene
	var projectiles_container = game_root.find_child("Projectiles", true, false)
	if projectiles_container:
		projectiles_container.add_child(proj)
	else:
		get_parent().add_child(proj)
	
	_play_recoil()
	AudioManager.play_cannon_fire()
	fired.emit(proj)
	return proj

func _play_recoil() -> void:
	var tween = create_tween()
	var original_pos = barrel_mesh.position
	var recoil_offset = Vector2(-7.0, 0.0) # Kick back along barrel axis
	barrel_mesh.position = original_pos + recoil_offset
	tween.tween_property(barrel_mesh, "position", original_pos, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func take_damage(amount: int = 1, _attacker: PlayerID = PlayerID.BLUE) -> void:
	if is_dead:
		return
	
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	AudioManager.play_impact_cannon()
	_play_hit_flash()
	
	if current_health <= 0:
		is_dead = true
		cancel_charging()
		_explode()
		destroyed.emit(self)

func _play_hit_flash() -> void:
	var tween = create_tween()
	modulate = Color(2.5, 2.5, 2.5)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)

func _explode() -> void:
	var explosion = impact_scene.instantiate() as ImpactEffect
	explosion.global_position = global_position
	explosion.setup_large_explosion()
	get_parent().add_child(explosion)
	visuals.visible = false
	collision_shape.set_deferred("disabled", true)

func reset_cannon() -> void:
	is_dead = false
	current_health = max_health
	cooldown_timer = 0.0
	is_charging = false
	charge_pct = 0.0
	is_charge_increasing = true
	velocity = Vector2.ZERO
	visuals.visible = true
	modulate = Color.WHITE
	collision_shape.set_deferred("disabled", false)
	
	if player_id == PlayerID.BLUE:
		barrel_pivot.rotation = deg_to_rad(-25.0)
		sweep_direction = -1.0
	else:
		barrel_pivot.rotation = deg_to_rad(-155.0)
		sweep_direction = 1.0
	
	current_power = min_power
	health_changed.emit(current_health, max_health)
	visuals.queue_redraw()
