extends Node

var frame_count: int = 0
var game: GameController
var current_step: int = 0

func _ready() -> void:
	game = get_parent().find_child("Game", true, false) as GameController
	print("Starting progressive terrain levels capture...")

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 15:
		# Level 1: Beginner
		_save_screenshot("res://screenshot_level1.png")
		_copy_to_artifact("screenshot_level1.png")
		
		# Transition to Level 2
		game._load_level(2)
	
	elif frame_count == 35:
		_save_screenshot("res://screenshot_level2.png")
		_copy_to_artifact("screenshot_level2.png")
		
		# Transition to Level 3
		game._load_level(3)
	
	elif frame_count == 55:
		_save_screenshot("res://screenshot_level3.png")
		_copy_to_artifact("screenshot_level3.png")
		
		# Transition to Level 4 (Challenging Mesa)
		game._load_level(4)
	
	elif frame_count == 75:
		_save_screenshot("res://screenshot_level4.png")
		_copy_to_artifact("screenshot_level4.png")
		
		# Transition to Level 5 (Advanced Twin Peaks)
		game._load_level(5)
	
	elif frame_count == 95:
		_save_screenshot("res://screenshot_level5.png")
		_copy_to_artifact("screenshot_level5.png")
		
		# Transition to Level 7 (Expert Procedural)
		game._load_level(7)
	
	elif frame_count == 115:
		_save_screenshot("res://screenshot_level7.png")
		_copy_to_artifact("screenshot_level7.png")
		print("All level screenshots captured successfully!")
		get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(filename)
		print("Saved screenshot: ", filename)

func _copy_to_artifact(src_name: String) -> void:
	var target_dir = "C:/Users/HP/.gemini/antigravity/brain/5b7ef927-875e-487a-8379-d4662c0951ba/"
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(target_dir + src_name)
