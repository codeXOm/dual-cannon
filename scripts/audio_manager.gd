extends Node

# AudioManager: Plays sound effects for Dual Cannon with polyphony and volume/mute controls

var cannon_fire_stream: AudioStream
var impact_terrain_stream: AudioStream
var impact_cannon_stream: AudioStream
var victory_stream: AudioStream
var ui_hover_stream: AudioStream
var ui_click_stream: AudioStream

var pool_size: int = 8
var player_pool: Array[AudioStreamPlayer] = []
var pool_index: int = 0

var is_muted: bool = false
var master_volume_db: float = -4.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_sound_assets()
	_setup_player_pool()

func _load_sound_assets() -> void:
	if ResourceLoader.exists("res://assets/audio/cannon_fire.wav"):
		cannon_fire_stream = load("res://assets/audio/cannon_fire.wav")
	if ResourceLoader.exists("res://assets/audio/impact_terrain.wav"):
		impact_terrain_stream = load("res://assets/audio/impact_terrain.wav")
	if ResourceLoader.exists("res://assets/audio/impact_cannon.wav"):
		impact_cannon_stream = load("res://assets/audio/impact_cannon.wav")
	if ResourceLoader.exists("res://assets/audio/victory.wav"):
		victory_stream = load("res://assets/audio/victory.wav")
	if ResourceLoader.exists("res://assets/audio/ui_hover.wav"):
		ui_hover_stream = load("res://assets/audio/ui_hover.wav")
	if ResourceLoader.exists("res://assets/audio/ui_click.wav"):
		ui_click_stream = load("res://assets/audio/ui_click.wav")

func _setup_player_pool() -> void:
	for i in range(pool_size):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		player_pool.append(asp)

func _get_available_player() -> AudioStreamPlayer:
	# Check for non-playing player
	for p in player_pool:
		if not p.playing:
			return p
	# Fallback to round-robin
	var chosen = player_pool[pool_index]
	pool_index = (pool_index + 1) % pool_size
	return chosen

func play_cannon_fire() -> void:
	_play_stream(cannon_fire_stream, -2.0, randf_range(0.95, 1.05))

func play_impact_terrain() -> void:
	_play_stream(impact_terrain_stream, -3.0, randf_range(0.92, 1.08))

func play_impact_cannon() -> void:
	_play_stream(impact_cannon_stream, 0.0, randf_range(0.96, 1.04))

func play_victory() -> void:
	_play_stream(victory_stream, 1.0, 1.0)

func play_ui_hover() -> void:
	_play_stream(ui_hover_stream, -8.0, randf_range(0.98, 1.02))

func play_ui_click() -> void:
	_play_stream(ui_click_stream, -5.0, randf_range(0.96, 1.04))

func _play_stream(stream: AudioStream, vol_offset_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if is_muted or stream == null:
		return
	var player = _get_available_player()
	player.stream = stream
	player.volume_db = master_volume_db + vol_offset_db
	player.pitch_scale = pitch_scale
	player.play()

func toggle_mute() -> bool:
	is_muted = not is_muted
	return is_muted

func set_mute(muted: bool) -> void:
	is_muted = muted
