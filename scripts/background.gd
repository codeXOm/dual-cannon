class_name StarryBackground
extends Node2D

# StarryBackground: Procedural minimalist dark navy-purple sky with subtle twinkling stars

@export var bg_color: Color = Color(0.075, 0.055, 0.145, 1.0)
@export var star_count: int = 70

var stars: Array[Dictionary] = []

func _ready() -> void:
	z_index = -10
	var rng = RandomNumberGenerator.new()
	rng.seed = 42 # Deterministic star placement
	for i in range(star_count):
		var pos = Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 520.0))
		var radius = rng.randf_range(1.0, 2.2)
		var base_alpha = rng.randf_range(0.2, 0.75)
		var speed = rng.randf_range(0.8, 2.5)
		var phase = rng.randf_range(0.0, TAU)
		stars.append({
			"pos": pos,
			"radius": radius,
			"base_alpha": base_alpha,
			"speed": speed,
			"phase": phase
		})

func _process(delta: float) -> void:
	for s in stars:
		s["phase"] += s["speed"] * delta
	queue_redraw()

func _draw() -> void:
	# Solid dark navy-purple background
	draw_rect(Rect2(0, 0, 1280, 720), bg_color, true)
	
	# Draw subtle stars
	for s in stars:
		var alpha = s["base_alpha"] * (0.7 + 0.3 * sin(s["phase"]))
		var col = Color(0.85, 0.88, 1.0, alpha)
		draw_circle(s["pos"], s["radius"], col)
