class_name GameController
extends Node2D

# GameController: Manages real-time simultaneous artillery combat match

@onready var background: StarryBackground = $Background
@onready var terrain: DestructibleTerrain = $Terrain
@onready var trajectories_node: Node2D = $Trajectories
@onready var blue_cannon: Cannon = $Cannons/BlueCannon
@onready var red_cannon: Cannon = $Cannons/RedCannon
@onready var projectiles_node: Node2D = $Projectiles
@onready var ai_controller: AIController = $AIController
@onready var hud: HUD = $HUD
@onready var game_over: GameOver = $GameOver

@export var one_trajectory_per_player: bool = true

var is_round_over: bool = false
var last_trajectory_blue: Line2D = null
var last_trajectory_red: Line2D = null

func _ready() -> void:
	# Connect cannon destruction signals
	blue_cannon.destroyed.connect(_on_cannon_destroyed)
	red_cannon.destroyed.connect(_on_cannon_destroyed)
	
	# Connect HUD signals
	hud.exit_pressed.connect(_on_exit_to_menu)
	hud.restart_pressed.connect(_on_restart_match)
	
	# Connect GameOver signals
	game_over.next_round_pressed.connect(_on_next_round)
	game_over.restart_pressed.connect(_on_restart_match)
	game_over.menu_pressed.connect(_on_exit_to_menu)
	
	# When terrain is destroyed, wake up cannon gravity immediately
	terrain.terrain_damaged.connect(_on_terrain_damaged)
	
	# Setup match with progressive level terrain
	_load_level(GameState.current_level if GameState else 1)

func _on_terrain_damaged(_pos: Vector2, _radius: float) -> void:
	# CharacterBody2D re-evaluates is_on_floor() every move_and_slide() call,
	# so we just need to ensure velocity.y is non-zero so the cannon attempts to
	# move. Give it a tiny downward nudge so move_and_slide fires this frame.
	if not blue_cannon.is_dead and blue_cannon.is_on_floor() == false:
		blue_cannon.velocity.y = maxf(blue_cannon.velocity.y, 1.0)
	if not red_cannon.is_dead and red_cannon.is_on_floor() == false:
		red_cannon.velocity.y = maxf(red_cannon.velocity.y, 1.0)

func _setup_match() -> void:
	_load_level(GameState.current_level if GameState else 1)

## Loads a new level: generates distinct progressive terrain, positions cannons on valid ground,
## coordinates balanced wind, and shows the level transition banner.
func _load_level(level: int) -> void:
	is_round_over = false
	game_over.visible = false
	
	_clear_projectiles()
	_clear_trajectories()
	
	# 1. Generate progressive terrain geometry and rebuild collision shapes
	terrain.generate_level(level)
	
	# 2. Position cannons firmly on valid ground of their respective platforms
	blue_cannon.global_position = terrain.get_spawn_position(Cannon.PlayerID.BLUE)
	red_cannon.global_position = terrain.get_spawn_position(Cannon.PlayerID.RED)
	blue_cannon.reset_cannon()
	red_cannon.reset_cannon()
	
	# 3. Coordinate wind progression with level
	if GameState:
		GameState.randomize_wind(level)
	
	# 4. Update HUD and display level banner
	var diff_name = GameState.get_level_difficulty_name(level) if GameState else "Beginner"
	hud.update_level_display(level, diff_name)
	hud.update_wind_display()
	hud.update_scores(GameState.blue_score if GameState else 0, GameState.red_score if GameState else 0)
	hud.show_level_transition(level, diff_name)
	
	# 5. Configure AI
	if GameState and GameState.current_mode == GameState.GameMode.PLAYER_VS_AI:
		red_cannon.is_ai_controlled = true
		ai_controller.cannon = red_cannon
		ai_controller.target_cannon = blue_cannon
		ai_controller.difficulty = GameState.current_difficulty
		ai_controller.set_process(true)
	else:
		red_cannon.is_ai_controlled = false
		ai_controller.set_process(false)

func _on_cannon_destroyed(cannon: Cannon) -> void:
	if is_round_over:
		return
	is_round_over = true
	
	# Disable AI while round over
	ai_controller.set_process(false)
	
	AudioManager.play_victory()
	
	var next_lvl = (GameState.current_level if GameState else 1) + 1
	if cannon == blue_cannon:
		if GameState:
			GameState.red_score += 1
			hud.update_scores(GameState.blue_score, GameState.red_score)
		game_over.show_winner("Red", Color(1.0, 0.38, 0.38), next_lvl)
	else:
		if GameState:
			GameState.blue_score += 1
			hud.update_scores(GameState.blue_score, GameState.red_score)
		game_over.show_winner("Blue", Color(0.0, 0.82, 0.95), next_lvl)

func _clear_projectiles() -> void:
	for child in projectiles_node.get_children():
		child.queue_free()

func record_last_trajectory(player_id: Cannon.PlayerID, path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	
	if not is_instance_valid(trajectories_node):
		return
	
	if not one_trajectory_per_player:
		# If single global trajectory across whole game, clear any existing lines
		_clear_trajectories()
	
	var line_color: Color
	if player_id == Cannon.PlayerID.BLUE:
		if is_instance_valid(last_trajectory_blue):
			if last_trajectory_blue.get_parent():
				last_trajectory_blue.get_parent().remove_child(last_trajectory_blue)
			last_trajectory_blue.queue_free()
			last_trajectory_blue = null
		line_color = Color(0.25, 0.88, 1.0, 0.55) # Soft luminous cyan for Blue
	else:
		if is_instance_valid(last_trajectory_red):
			if last_trajectory_red.get_parent():
				last_trajectory_red.get_parent().remove_child(last_trajectory_red)
			last_trajectory_red.queue_free()
			last_trajectory_red = null
		line_color = Color(1.0, 0.48, 0.48, 0.55) # Soft luminous coral for Red
	
	var traj_line = Line2D.new()
	traj_line.width = 2.8
	traj_line.default_color = line_color
	traj_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	traj_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	traj_line.joint_mode = Line2D.LINE_JOINT_ROUND
	traj_line.antialiased = true
	
	# Gradient along the flight path: soft origin, solid body towards impact
	var grad = Gradient.new()
	grad.set_color(0, Color(line_color.r, line_color.g, line_color.b, 0.15))
	grad.set_color(1, line_color)
	traj_line.gradient = grad
	
	traj_line.points = path
	trajectories_node.add_child(traj_line)
	
	if player_id == Cannon.PlayerID.BLUE:
		last_trajectory_blue = traj_line
	else:
		last_trajectory_red = traj_line

func _clear_trajectories() -> void:
	if is_instance_valid(last_trajectory_blue):
		if last_trajectory_blue.get_parent():
			last_trajectory_blue.get_parent().remove_child(last_trajectory_blue)
		last_trajectory_blue.queue_free()
		last_trajectory_blue = null
	if is_instance_valid(last_trajectory_red):
		if last_trajectory_red.get_parent():
			last_trajectory_red.get_parent().remove_child(last_trajectory_red)
		last_trajectory_red.queue_free()
		last_trajectory_red = null
	if is_instance_valid(trajectories_node):
		for child in trajectories_node.get_children():
			trajectories_node.remove_child(child)
			child.queue_free()

func _on_next_round() -> void:
	if GameState:
		GameState.current_level += 1
	_load_level(GameState.current_level if GameState else 1)

func _on_restart_match() -> void:
	if GameState:
		GameState.reset_match()
	_load_level(1)

func _on_exit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
