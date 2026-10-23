extends Node

var frame_count: int = 0
var main_menu: MainMenu

func _ready() -> void:
	main_menu = get_parent().find_child("MainMenu", true, false) as MainMenu

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count == 16:
		var img = get_viewport().get_texture().get_image()
		if img:
			img.save_png("screenshot_main_menu.png")
			print("Saved screenshot_main_menu.png")
		
		# Now switch to 2-Player mode to test 2P layout
		if main_menu:
			main_menu.mode_2p_btn.emit_signal("pressed")
	
	elif frame_count == 28:
		var img2 = get_viewport().get_texture().get_image()
		if img2:
			img2.save_png("screenshot_main_menu_2p.png")
			print("Saved screenshot_main_menu_2p.png")
		get_tree().quit(0)
