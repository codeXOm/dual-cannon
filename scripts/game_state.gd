extends Node

# GameState: Global persistent singleton for match configuration and global state

enum GameMode {
	TWO_PLAYERS,
	PLAYER_VS_AI
}

enum AIDifficulty {
	EASY,
	NORMAL,
	HARD
}

var current_mode: GameMode = GameMode.PLAYER_VS_AI
var current_difficulty: AIDifficulty = AIDifficulty.NORMAL
var wind_enabled: bool = false
var sound_enabled: bool = true

var blue_score: int = 0
var red_score: int = 0
var current_wind: float = 0.0 # Pixels/sec^2 lateral acceleration
var current_level: int = 1

func reset_scores() -> void:
	blue_score = 0
	red_score = 0

func reset_match() -> void:
	reset_scores()
	current_level = 1

func randomize_wind(level: int = 1) -> void:
	if wind_enabled:
		# Balanced wind progression: base 40-140 px/s^2 at level 1,
		# scaling gently up to ~80-200 px/s^2 at higher levels without abrupt spikes
		var lvl_factor = clampf(float(level - 1) * 8.0, 0.0, 60.0)
		var min_w = 40.0 + lvl_factor * 0.5
		var max_w = 140.0 + lvl_factor
		var sign_val = 1.0 if randf() > 0.5 else -1.0
		current_wind = sign_val * randf_range(min_w, max_w)
	else:
		current_wind = 0.0

func get_difficulty_name() -> String:
	match current_difficulty:
		AIDifficulty.EASY: return "Easy"
		AIDifficulty.NORMAL: return "Normal"
		AIDifficulty.HARD: return "Hard"
	return "Normal"

func get_level_difficulty_name(level: int) -> String:
	match level:
		1: return "Beginner"
		2: return "Easy"
		3: return "Intermediate"
		4: return "Challenging"
		5: return "Advanced"
		_: return "Expert (Lvl %d)" % level

func get_level_description(level: int) -> String:
	match level:
		1: return "Gentle hills & stable platforms"
		2: return "Uneven ground & rolling dunes"
		3: return "Central ridge & dual valleys"
		4: return "Asymmetric heights & steep bluffs"
		5: return "Jagged crags & deep gorge"
		_: return "Dynamic procedural hazards"
