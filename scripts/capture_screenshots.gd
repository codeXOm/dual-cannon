extends Node

var frame_count: int = 0
var game: GameController

func _ready() -> void:
	game = get_parent().find_child("Game", true, false) as GameController
	print("Starting charge up/down capture sequence...")

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 10:
		# Initial state
		_save_screenshot("screenshot_initial.png")
		# Start hold-to-charge on both cannons
		game.blue_cannon.start_charging()
		game.red_cannon.start_charging()
	
	elif frame_count == 35:
		# Capture power increasing: "48% ▲ UP"
		_save_screenshot("screenshot_charging_meter_up.png")
	
	elif frame_count == 75:
		# Capture power decreasing after 100% turnaround: "65% ▼ DN"
		_save_screenshot("screenshot_charging_meter_down.png")
		
		# Release to fire both missiles!
		game.blue_cannon.release_and_fire()
		game.red_cannon.release_and_fire()
	
	elif frame_count == 100:
		# Mid-air simultaneous flight
		_save_screenshot("screenshot_combat_flight.png")
	
	elif frame_count == 140:
		# Ground impacts & craters
		game.terrain.cut_crater(Vector2(640, 620), 45.0)
		game.terrain.cut_crater(Vector2(400, 560), 40.0)
		game.terrain.cut_crater(Vector2(880, 550), 38.0)
		var explosion = game.blue_cannon.impact_scene.instantiate() as ImpactEffect
		explosion.global_position = Vector2(640, 620)
		explosion.setup_large_explosion()
		game.add_child(explosion)
	
	elif frame_count == 150:
		_save_screenshot("screenshot_crater_carved.png")
		print("Screenshot capture complete!")
		get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(filename)
		print("Saved screenshot: ", filename)
	else:
		printerr("Failed to grab viewport image for: ", filename)
