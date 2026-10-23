class_name MainMenu
extends Control

# MainMenu: Highly attractive modern arcade duel lobby with dynamic mode selection,
# AI difficulty tuning, wind/sound modifiers, animated mascot showcase, and interactive audio feedback.

@onready var mode_2p_btn: Button = find_child("Mode2PButton", true, false)
@onready var mode_ai_btn: Button = find_child("ModeAIButton", true, false)

@onready var diff_container: Control = find_child("DifficultyContainer", true, false)
@onready var diff_easy_btn: Button = find_child("DiffEasyButton", true, false)
@onready var diff_norm_btn: Button = find_child("DiffNormButton", true, false)
@onready var diff_hard_btn: Button = find_child("DiffHardButton", true, false)

@onready var wind_toggle_btn: Button = find_child("WindToggleButton", true, false)
@onready var sound_toggle_btn: Button = find_child("SoundToggleButton", true, false)

@onready var start_button: Button = find_child("StartButton", true, false)
@onready var exit_button: Button = find_child("ExitButton", true, false)

# Dynamic Controls Panel Labels
@onready var red_pill_label: Label = find_child("RedPillLabel", true, false)
@onready var red_keycap_panel: Control = find_child("RedKeycapPanel", true, false)
@onready var red_desc_label: Label = find_child("RedDescLabel", true, false)

var start_btn_tween: Tween

func _ready() -> void:
	# Mode Selection
	mode_2p_btn.pressed.connect(func(): 
		_set_mode(GameState.GameMode.TWO_PLAYERS)
		AudioManager.play_ui_click()
	)
	mode_ai_btn.pressed.connect(func(): 
		_set_mode(GameState.GameMode.PLAYER_VS_AI)
		AudioManager.play_ui_click()
	)
	
	# AI Difficulty
	diff_easy_btn.pressed.connect(func(): 
		_set_difficulty(GameState.AIDifficulty.EASY)
		AudioManager.play_ui_click()
	)
	diff_norm_btn.pressed.connect(func(): 
		_set_difficulty(GameState.AIDifficulty.NORMAL)
		AudioManager.play_ui_click()
	)
	diff_hard_btn.pressed.connect(func(): 
		_set_difficulty(GameState.AIDifficulty.HARD)
		AudioManager.play_ui_click()
	)
	
	# Toggles
	wind_toggle_btn.pressed.connect(func():
		_on_wind_toggle()
		AudioManager.play_ui_click()
	)
	sound_toggle_btn.pressed.connect(func():
		_on_sound_toggle()
		AudioManager.play_ui_click()
	)
	
	# Action buttons
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(func():
		AudioManager.play_ui_click()
		_on_exit_pressed()
	)
	
	# Register hover audio and tactile scale animations on all interactive buttons
	_setup_button_hover_effects([
		mode_ai_btn, mode_2p_btn,
		diff_easy_btn, diff_norm_btn, diff_hard_btn,
		wind_toggle_btn, sound_toggle_btn,
		start_button, exit_button
	])
	
	# Start pulsing glow animation on Start Button
	_start_start_button_pulse()
	
	_update_ui_state()

func _setup_button_hover_effects(buttons: Array[Button]) -> void:
	for btn in buttons:
		if not btn:
			continue
		btn.pivot_offset = btn.size * 0.5
		btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
		
		btn.mouse_entered.connect(func():
			AudioManager.play_ui_hover()
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn, "scale", Vector2(1.025, 1.025), 0.12)
		)
		btn.mouse_exited.connect(func():
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
		)

func _start_start_button_pulse() -> void:
	if not start_button:
		return
	start_button.pivot_offset = start_button.size * 0.5
	start_button.resized.connect(func(): start_button.pivot_offset = start_button.size * 0.5)
	
	if start_btn_tween:
		start_btn_tween.kill()
	
	start_btn_tween = create_tween().set_loops()
	start_btn_tween.tween_property(start_button, "modulate", Color(1.05, 1.05, 1.1), 0.8).set_trans(Tween.TRANS_SINE)
	start_btn_tween.tween_property(start_button, "modulate", Color(0.95, 0.95, 0.98), 0.8).set_trans(Tween.TRANS_SINE)

func _set_mode(mode: GameState.GameMode) -> void:
	GameState.current_mode = mode
	_update_ui_state()

func _set_difficulty(diff: GameState.AIDifficulty) -> void:
	GameState.current_difficulty = diff
	_update_ui_state()

func _on_wind_toggle() -> void:
	GameState.wind_enabled = not GameState.wind_enabled
	_update_ui_state()

func _on_sound_toggle() -> void:
	AudioManager.toggle_mute()
	_update_ui_state()

func _update_ui_state() -> void:
	var is_2p = (GameState.current_mode == GameState.GameMode.TWO_PLAYERS)
	
	# 1. Mode Cards
	_style_mode_card(mode_ai_btn, not is_2p, true)
	_style_mode_card(mode_2p_btn, is_2p, false)
	
	# 2. AI Difficulty Container & Buttons
	diff_container.visible = not is_2p
	_style_diff_btn(diff_easy_btn, GameState.current_difficulty == GameState.AIDifficulty.EASY, Color(0.1, 0.65, 0.4), Color(0.25, 0.95, 0.55))
	_style_diff_btn(diff_norm_btn, GameState.current_difficulty == GameState.AIDifficulty.NORMAL, Color(0.08, 0.52, 0.8), Color(0.2, 0.85, 1.0))
	_style_diff_btn(diff_hard_btn, GameState.current_difficulty == GameState.AIDifficulty.HARD, Color(0.75, 0.18, 0.28), Color(1.0, 0.45, 0.45))
	
	# 3. Wind Button
	_style_wind_button()
	
	# 4. Sound Button
	_style_sound_button()
	
	# 5. Dynamic Controls Description
	if red_pill_label and red_desc_label:
		if is_2p:
			red_pill_label.text = "P2 RED"
			if red_keycap_panel:
				red_keycap_panel.visible = true
			red_desc_label.text = "Hold to Lock Angle & Charge  ➜  Release to Fire"
			red_desc_label.modulate = Color(1.0, 0.8, 0.8)
		else:
			red_pill_label.text = "AI RED"
			if red_keycap_panel:
				red_keycap_panel.visible = false
			red_desc_label.text = "Auto-evaluates ballistic trajectory & fires simultaneously"
			red_desc_label.modulate = Color(0.88, 0.82, 0.95)

func _style_mode_card(btn: Button, active: bool, is_ai_card: bool) -> void:
	if not btn:
		return
	
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	
	if active:
		if is_ai_card:
			# Electric Cyan Active Style
			sb.bg_color = Color(0.06, 0.16, 0.28, 0.95)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.0, 0.9, 1.0, 1.0)
			sb.shadow_color = Color(0.0, 0.85, 1.0, 0.35)
			sb.shadow_size = 10
			btn.text = "🤖  PLAYER VS AI  [ACTIVE]"
			btn.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
		else:
			# Fiery Coral Active Style
			sb.bg_color = Color(0.26, 0.08, 0.12, 0.95)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(1.0, 0.42, 0.45, 1.0)
			sb.shadow_color = Color(1.0, 0.4, 0.4, 0.35)
			sb.shadow_size = 10
			btn.text = "👥  2 PLAYERS (LOCAL)  [ACTIVE]"
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
	else:
		# Sleek Inactive Dark Glass Style
		sb.bg_color = Color(0.10, 0.08, 0.18, 0.75)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.28, 0.24, 0.42, 0.65)
		btn.add_theme_color_override("font_color", Color(0.65, 0.62, 0.75))
		if is_ai_card:
			btn.text = "🤖  PLAYER VS AI"
		else:
			btn.text = "👥  2 PLAYERS (LOCAL)"
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _style_diff_btn(btn: Button, active: bool, bg_active: Color, border_active: Color) -> void:
	if not btn:
		return
	
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	
	if active:
		sb.bg_color = bg_active
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = border_active
		sb.shadow_color = Color(border_active.r, border_active.g, border_active.b, 0.35)
		sb.shadow_size = 6
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.bg_color = Color(0.12, 0.1, 0.2, 0.8)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.26, 0.22, 0.38, 0.5)
		btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _style_wind_button() -> void:
	if not wind_toggle_btn:
		return
	
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	
	if GameState.wind_enabled:
		sb.bg_color = Color(0.08, 0.18, 0.3, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.0, 0.85, 1.0, 0.8)
		sb.shadow_color = Color(0.0, 0.85, 1.0, 0.25)
		sb.shadow_size = 6
		wind_toggle_btn.text = "💨  WIND: DYNAMIC  [ON]"
		wind_toggle_btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	else:
		sb.bg_color = Color(0.11, 0.09, 0.18, 0.75)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.28, 0.24, 0.42, 0.6)
		wind_toggle_btn.text = "🍃  WIND: CALM (NO WIND)"
		wind_toggle_btn.add_theme_color_override("font_color", Color(0.68, 0.65, 0.78))
	
	wind_toggle_btn.add_theme_stylebox_override("normal", sb)
	wind_toggle_btn.add_theme_stylebox_override("hover", sb)
	wind_toggle_btn.add_theme_stylebox_override("pressed", sb)

func _style_sound_button() -> void:
	if not sound_toggle_btn:
		return
	
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	
	if not AudioManager.is_muted:
		sb.bg_color = Color(0.08, 0.2, 0.16, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.2, 0.88, 0.5, 0.8)
		sb.shadow_color = Color(0.2, 0.88, 0.5, 0.25)
		sb.shadow_size = 6
		sound_toggle_btn.text = "🔊  AUDIO: ENABLED"
		sound_toggle_btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	else:
		sb.bg_color = Color(0.2, 0.1, 0.12, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.9, 0.35, 0.35, 0.8)
		sound_toggle_btn.text = "🔇  AUDIO: MUTED"
		sound_toggle_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	
	sound_toggle_btn.add_theme_stylebox_override("normal", sb)
	sound_toggle_btn.add_theme_stylebox_override("hover", sb)
	sound_toggle_btn.add_theme_stylebox_override("pressed", sb)

func _on_start_pressed() -> void:
	AudioManager.play_ui_click()
	AudioManager.play_cannon_fire()
	GameState.reset_scores()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
