class_name HUD
extends CanvasLayer

signal exit_pressed
signal pause_pressed
signal restart_pressed

@onready var score_label: Label = $TopBar/CenterBox/ScorePill/Margin/ScoreLabel
@onready var wind_label: Label = $TopBar/CenterBox/WindPill/Margin/WindLabel
@onready var level_label: Label = $TopBar/CenterBox/LevelPill/Margin/LevelLabel
@onready var fps_label: Label = $TopBar/FPSLabel
@onready var exit_button: Button = $TopBar/RightButtons/ExitButton
@onready var pause_button: Button = $TopBar/RightButtons/PauseButton
@onready var mode_label: Label = $BottomBar/ModeLabel

@onready var level_banner: Control = $LevelBanner
@onready var banner_level_title: Label = $LevelBanner/Panel/Margin/VBox/BannerLevelTitle
@onready var banner_difficulty: Label = $LevelBanner/Panel/Margin/VBox/BannerDifficulty
@onready var banner_desc: Label = $LevelBanner/Panel/Margin/VBox/BannerDesc

@onready var pause_overlay: PanelContainer = $PauseOverlay
@onready var resume_btn: Button = $PauseOverlay/VBox/ResumeButton
@onready var restart_btn: Button = $PauseOverlay/VBox/RestartButton
@onready var menu_btn: Button = $PauseOverlay/VBox/MenuButton
@onready var sound_toggle_btn: Button = $PauseOverlay/VBox/SoundToggleButton

var banner_tween: Tween = null

func _ready() -> void:
	exit_button.pressed.connect(func(): exit_pressed.emit())
	pause_button.pressed.connect(func(): _toggle_pause())
	
	resume_btn.pressed.connect(func(): _toggle_pause(false))
	restart_btn.pressed.connect(func(): 
		_toggle_pause(false)
		restart_pressed.emit()
	)
	menu_btn.pressed.connect(func():
		_toggle_pause(false)
		exit_pressed.emit()
	)
	sound_toggle_btn.pressed.connect(_on_sound_toggle_pressed)
	_update_sound_button_label()
	
	pause_overlay.visible = false
	level_banner.modulate = Color(1, 1, 1, 0)
	
	var lvl = GameState.current_level if GameState else 1
	var diff_name = GameState.get_level_difficulty_name(lvl) if GameState else "Beginner"
	update_level_display(lvl, diff_name)
	update_scores(GameState.blue_score, GameState.red_score)
	update_wind_display()
	_update_mode_label()

func _process(_delta: float) -> void:
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	
	if Input.is_action_just_pressed("pause_game"):
		_toggle_pause()

func update_level_display(level: int, diff_name: String) -> void:
	level_label.text = "LVL %d - %s" % [level, diff_name.to_upper()]

func show_level_transition(level: int, diff_name: String, desc: String = "") -> void:
	banner_level_title.text = "LEVEL %d" % level
	banner_difficulty.text = "%s TERRAIN" % diff_name.to_upper()
	if desc.is_empty() and GameState:
		desc = GameState.get_level_description(level)
	banner_desc.text = desc
	
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
	
	level_banner.modulate = Color(1, 1, 1, 0.0)
	level_banner.position.y = (720.0 - 106.0) * 0.5 - 20.0
	
	banner_tween = create_tween()
	banner_tween.set_parallel(true)
	banner_tween.tween_property(level_banner, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	banner_tween.tween_property(level_banner, "position:y", (720.0 - 106.0) * 0.5, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Hold for 1.3 seconds, then fade out smoothly
	banner_tween.chain().tween_interval(1.3)
	banner_tween.chain().tween_property(level_banner, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func update_scores(blue: int, red: int) -> void:
	score_label.text = "%d - %d" % [blue, red]

func update_wind_display() -> void:
	if not GameState.wind_enabled or abs(GameState.current_wind) < 5.0:
		wind_label.text = "NO WIND"
		wind_label.modulate = Color(0.85, 0.85, 0.9)
	else:
		var dir_str = ">>>" if GameState.current_wind > 0 else "<<<"
		var speed_val = int(abs(GameState.current_wind))
		wind_label.text = "WIND %s %d" % [dir_str, speed_val]
		wind_label.modulate = Color(0.4, 0.9, 1.0) if GameState.current_wind > 0 else Color(1.0, 0.7, 0.4)

func _update_mode_label() -> void:
	if GameState.current_mode == GameState.GameMode.TWO_PLAYERS:
		mode_label.text = "LOCAL 2-PLAYER"
	else:
		mode_label.text = "VS AI (%s)" % GameState.get_difficulty_name().to_upper()

func _toggle_pause(forced_state: Variant = null) -> void:
	if forced_state != null:
		pause_overlay.visible = forced_state
	else:
		pause_overlay.visible = not pause_overlay.visible
	
	get_tree().paused = pause_overlay.visible

func _on_sound_toggle_pressed() -> void:
	AudioManager.toggle_mute()
	_update_sound_button_label()

func _update_sound_button_label() -> void:
	sound_toggle_btn.text = "SOUND: OFF" if AudioManager.is_muted else "SOUND: ON"
