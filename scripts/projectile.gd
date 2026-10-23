class_name Projectile
extends Node2D

# Projectile: Independent ballistic rocket with gravity, wind, particle trail, and continuous swept collision

@export var gravity: float = 720.0 # Pixels/sec^2
@export var crater_radius: float = 38.0
@export var max_lifetime: float = 12.0 # Seconds

var velocity: Vector2 = Vector2.ZERO
var firing_player: Cannon.PlayerID = Cannon.PlayerID.BLUE
var owner_cannon: Cannon = null
var wind_force: float = 0.0

var elapsed_time: float = 0.0
var has_impacted: bool = false

# Visuals
@onready var rocket_body: Node2D = $Visuals/RocketMesh
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var trail_line: Line2D = $TrailLine

var impact_scene: PackedScene = preload("res://scenes/ImpactEffect.tscn")
var max_trail_points: int = 40
var trail_history: Array[Vector2] = []
var full_trajectory_path: PackedVector2Array = PackedVector2Array()
var min_record_dist_sq: float = 16.0 # Record point every ~4px

func setup(start_pos: Vector2, initial_velocity: Vector2, shooter_id: Cannon.PlayerID, shooter_cannon: Cannon) -> void:
	global_position = start_pos
	velocity = initial_velocity
	firing_player = shooter_id
	owner_cannon = shooter_cannon
	rotation = velocity.angle()
	
	full_trajectory_path.clear()
	full_trajectory_path.append(start_pos)
	
	# Fetch current wind from GameState
	if GameState.wind_enabled:
		wind_force = GameState.current_wind
	else:
		wind_force = 0.0

func _ready() -> void:
	top_level = true # Free from parent transforms
	if trail_line:
		trail_line.top_level = true
		trail_line.clear_points()

func _physics_process(delta: float) -> void:
	if has_impacted:
		return
	
	elapsed_time += delta
	if elapsed_time > max_lifetime:
		_cleanup()
		return
	
	# Apply ballistic physics
	velocity.y += gravity * delta
	velocity.x += wind_force * delta
	
	var next_pos = global_position + velocity * delta
	rotation = velocity.angle()
	
	# Record points for full flight trajectory
	if full_trajectory_path.is_empty() or next_pos.distance_squared_to(full_trajectory_path[full_trajectory_path.size() - 1]) >= min_record_dist_sq:
		full_trajectory_path.append(next_pos)
	
	# Update visual trail ribbon
	_update_trail()
	
	# Swept continuous raycast collision to prevent tunnelling
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, next_pos)
	query.collision_mask = 3 # Layer 1: Terrain, Layer 2: Cannons
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var exclude_rids: Array[RID] = []
	if owner_cannon and is_instance_valid(owner_cannon):
		exclude_rids.append(owner_cannon.get_rid())
	query.exclude = exclude_rids
	
	var result = space_state.intersect_ray(query)
	if result:
		_handle_collision(result.collider, result.position, result.normal)
	else:
		global_position = next_pos
		# Bounds check
		if global_position.y > 850.0 or global_position.x < -300.0 or global_position.x > 1580.0:
			_cleanup()

func _update_trail() -> void:
	if not trail_line:
		return
	trail_history.push_front(global_position)
	if trail_history.size() > max_trail_points:
		trail_history.pop_back()
	
	trail_line.clear_points()
	for pt in trail_history:
		trail_line.add_point(pt)

func _handle_collision(collider: Object, hit_pos: Vector2, hit_normal: Vector2) -> void:
	has_impacted = true
	full_trajectory_path.append(hit_pos)
	
	if collider is Cannon:
		var target_cannon = collider as Cannon
		if target_cannon != owner_cannon:
			target_cannon.take_damage(1, firing_player)
			_spawn_impact(hit_pos, hit_normal, true)
	else:
		# Hit terrain (or static body)
		var terrain = get_tree().current_scene.find_child("Terrain", true, false)
		if terrain and terrain.has_method("cut_crater"):
			terrain.cut_crater(hit_pos, crater_radius)
		AudioManager.play_impact_terrain()
		_spawn_impact(hit_pos, hit_normal, false)
	
	_cleanup()

func _spawn_impact(pos: Vector2, normal: Vector2, is_cannon_hit: bool) -> void:
	var effect = impact_scene.instantiate() as ImpactEffect
	effect.global_position = pos
	effect.rotation = normal.angle()
	if is_cannon_hit:
		effect.setup_large_explosion()
	else:
		effect.setup_terrain_burst()
	
	var game_root = get_tree().current_scene
	if game_root:
		game_root.add_child(effect)
	else:
		get_tree().root.add_child(effect)

func _cleanup() -> void:
	# Hand off completed trajectory path to GameController to display only the previous last trajectory
	if full_trajectory_path.size() >= 2 and not is_queued_for_deletion():
		var game_ctrl: GameController = null
		if owner_cannon and is_instance_valid(owner_cannon):
			var node = owner_cannon.get_parent()
			while node:
				if node is GameController:
					game_ctrl = node as GameController
					break
				node = node.get_parent()
		
		if not game_ctrl and get_tree() and get_tree().current_scene:
			if get_tree().current_scene is GameController:
				game_ctrl = get_tree().current_scene as GameController
			else:
				game_ctrl = get_tree().current_scene.find_child("Game", true, false) as GameController
		
		if game_ctrl and game_ctrl.has_method("record_last_trajectory"):
			game_ctrl.record_last_trajectory(firing_player, full_trajectory_path)
	
	# Active in-flight trail ribbon and particles are freed cleanly with queue_free()
	queue_free()
