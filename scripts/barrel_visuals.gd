class_name BarrelVisuals
extends Node2D

@export var length: float = 24.0
@export var width: float = 7.0
@export var barrel_color: Color = Color(0.92, 0.94, 0.96)
@export var outline_color: Color = Color(0.08, 0.08, 0.12)

func _draw() -> void:
	# Draw barrel rectangle extending along +X from pivot (0, 0)
	var rect = Rect2(0.0, -width * 0.5, length, width)
	draw_rect(rect, barrel_color, true)
	draw_rect(rect, outline_color, false, 2.0)
	
	# Muzzle tip cap
	var muzzle_rect = Rect2(length - 3.0, -width * 0.5 - 1.0, 3.0, width + 2.0)
	draw_rect(muzzle_rect, Color(0.7, 0.72, 0.75), true)
	draw_rect(muzzle_rect, outline_color, false, 1.5)
	
	# Center pivot pin
	draw_circle(Vector2.ZERO, width * 0.5 + 1.0, outline_color)
	draw_circle(Vector2.ZERO, width * 0.5 - 0.5, barrel_color)
