extends Node

var frame_count: int = 0
var game: GameController

func _ready() -> void:
	game = get_parent().find_child("Game", true, false) as GameController
	print("Starting trajectory test sequence...")

func _process(_delta: float) -> void:
	frame_count += 1
	
	# Shot 1
	if frame_count == 10:
		game.blue_cannon.start_charging()
		game.red_cannon.start_charging()
	elif frame_count == 30:
		game.blue_cannon.release_and_fire()
		game.red_cannon.release_and_fire()
	
	# Shot 2 (fired after shot 1 has landed)
	elif frame_count == 110:
		game.blue_cannon.start_charging()
		game.red_cannon.start_charging()
	elif frame_count == 130:
		game.blue_cannon.release_and_fire()
		game.red_cannon.release_and_fire()
	
	# Shot 3 (fired after shot 2 has landed)
	elif frame_count == 210:
		game.blue_cannon.start_charging()
		game.red_cannon.start_charging()
	elif frame_count == 230:
		game.blue_cannon.release_and_fire()
		game.red_cannon.release_and_fire()
	
	# After shot 3 lands, capture screenshot
	elif frame_count == 320:
		var traj_count = game.trajectories_node.get_child_count()
		print("Final trajectory child count in tree: ", traj_count)
		_save_screenshot("screenshot_trajectory_verified.png")
		get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(filename)
		print("Saved screenshot: ", filename)
	else:
		printerr("Failed to grab viewport image for: ", filename)
