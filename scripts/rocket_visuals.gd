class_name RocketVisuals
extends Node2D

# RocketVisuals: Clean vector rocket matching the reference video

@export var body_color: Color = Color(0.95, 0.95, 0.98) # Crisp white
@export var nose_color: Color = Color(1.0, 0.25, 0.25) # Vibrant red cone
@export var outline_color: Color = Color(0.08, 0.08, 0.12)

func _draw() -> void:
	# Rocket Body (Rectangle centered at local origin, pointing +X)
	# Tail is at X = -7, nose base is at X = +5, nose tip is at X = +11
	var body_rect = Rect2(-7.0, -3.0, 12.0, 6.0)
	draw_rect(body_rect, body_color, true)
	
	# Red Conical Nose Tip
	var nose_points = PackedVector2Array([
		Vector2(5.0, -3.0),
		Vector2(11.0, 0.0),
		Vector2(5.0, 3.0)
	])
	draw_colored_polygon(nose_points, nose_color)
	
	# Tail Fins
	var fin_top = PackedVector2Array([
		Vector2(-7.0, -3.0),
		Vector2(-9.0, -5.5),
		Vector2(-5.0, -3.0)
	])
	draw_colored_polygon(fin_top, Color(0.3, 0.35, 0.4))
	
	var fin_bot = PackedVector2Array([
		Vector2(-7.0, 3.0),
		Vector2(-9.0, 5.5),
		Vector2(-5.0, 3.0)
	])
	draw_colored_polygon(fin_bot, Color(0.3, 0.35, 0.4))
	
	# Crisp Outlines
	draw_rect(body_rect, outline_color, false, 1.2)
	draw_polyline(nose_points, outline_color, 1.2, true)
