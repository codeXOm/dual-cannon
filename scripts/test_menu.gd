extends Node

# Verifies MainMenu initialization and transition

func _ready() -> void:
	print("[TEST MENU] Testing MainMenu initialization...")
	var menu = get_parent().find_child("MainMenu", true, false) as MainMenu
	if not menu:
		printerr("Current scene is not MainMenu")
		get_tree().quit(1)
		return
	
	print("Checking mode button switches...")
	menu.mode_2p_btn.pressed.emit()
	if GameState.current_mode != GameState.GameMode.TWO_PLAYERS:
		printerr("Failed to set TWO_PLAYERS mode")
		get_tree().quit(1)
		return
	
	menu.mode_ai_btn.pressed.emit()
	if GameState.current_mode != GameState.GameMode.PLAYER_VS_AI:
		printerr("Failed to set PLAYER_VS_AI mode")
		get_tree().quit(1)
		return
	
	print("Checking difficulty switch...")
	menu.diff_hard_btn.pressed.emit()
	if GameState.current_difficulty != GameState.AIDifficulty.HARD:
		printerr("Failed to set HARD difficulty")
		get_tree().quit(1)
		return
	
	print("Checking wind toggle...")
	menu.wind_toggle_btn.pressed.emit()
	if not GameState.wind_enabled:
		printerr("Failed to toggle wind")
		get_tree().quit(1)
		return
	
	print("MainMenu tests passed successfully!")
	get_tree().quit(0)
