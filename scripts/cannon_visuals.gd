class_name CannonVisuals
extends Node2D

@onready var cannon: Cannon = get_parent()

func _draw() -> void:
	if not cannon:
		return
	
	# Draw Base Track (Rounded capsule)
	var track_rect = Rect2(-24, -2, 48, 12)
	draw_rect(track_rect, Color(0.12, 0.12, 0.16), true)
	draw_rect(track_rect, Color(0.06, 0.06, 0.08), false, 2.0)
	
	# Draw 3 Road Wheels
	var wheel_radius = 4.5
	var wheel_xs = [-14.0, 0.0, 14.0]
	for wx in wheel_xs:
		var wheel_pos = Vector2(wx, 4.0)
		draw_circle(wheel_pos, wheel_radius, Color(0.25, 0.26, 0.32))
		draw_arc(wheel_pos, wheel_radius, 0.0, TAU, 16, Color(0.06, 0.06, 0.08), 1.5)
		draw_circle(wheel_pos, 1.8, Color(0.12, 0.12, 0.16))
	
	# Draw Dome Hull (Semicircle above track)
	var dome_radius = 16.0
	var dome_center = Vector2(0, -2)
	var dome_points = PackedVector2Array()
	var outline_points = PackedVector2Array()
	dome_points.append(dome_center)
	
	var segments = 20
	for i in range(segments + 1):
		var angle = -PI + (float(i) / segments) * PI
		var pt = dome_center + Vector2(cos(angle), sin(angle)) * dome_radius
		dome_points.append(pt)
		outline_points.append(pt)
	
	# Fill dome with player color
	draw_polygon(dome_points, [cannon.hull_color])
	# Dark outline around the dome
	draw_polyline(outline_points, cannon.outline_color, 2.5, true)
	
	# Draw Health Pips above the cannon
	_draw_health_pips()
	
	# Draw Power Meter or Sweep Hint
	if cannon.is_charging:
		_draw_active_charge_meter()
	else:
		_draw_idle_prompt()

func _draw_health_pips() -> void:
	var pip_radius = 3.5
	var start_y = -24.0
	var pip_spacing = 9.0
	var total_width = (cannon.max_health - 1) * pip_spacing
	var start_x = -total_width * 0.5
	
	for i in range(cannon.max_health):
		var pos = Vector2(start_x + i * pip_spacing, start_y)
		var is_active = (i < cannon.current_health)
		var col = cannon.health_pip_color if is_active else cannon.health_pip_empty_color
		
		# Draw pip dot
		draw_circle(pos, pip_radius, col)
		draw_arc(pos, pip_radius, 0.0, TAU, 12, Color(0.08, 0.08, 0.12), 1.2)
		if is_active:
			draw_circle(pos + Vector2(-1, -1), 1.0, Color.WHITE)

func _draw_active_charge_meter() -> void:
	var font = ThemeDB.fallback_font
	var pct_int = int(round(cannon.charge_pct * 100.0))
	var is_up = cannon.is_charge_increasing
	
	# 1. Badge container at Y = -56
	var badge_w = 78.0
	var badge_h = 22.0
	var badge_rect = Rect2(-badge_w * 0.5, -66.0, badge_w, badge_h)
	draw_rect(badge_rect, Color(0.08, 0.06, 0.16, 0.95), true)
	draw_rect(badge_rect, Color(0.38, 0.32, 0.55), false, 1.8)
	
	# Text: e.g. "75% ▲ UP" or "75% ▼ DN"
	var marker_str = "▲ UP" if is_up else "▼ DN"
	var text_str = "%d%% %s" % [pct_int, marker_str]
	var text_col = Color(0.25, 0.95, 0.45) if is_up else Color(1.0, 0.45, 0.35)
	if font:
		draw_string(font, Vector2(-badge_w * 0.5, -50.0), text_str, HORIZONTAL_ALIGNMENT_CENTER, badge_w, 12, text_col)
	
	# 2. Horizontal progress bar at Y = -40
	var bar_w = 72.0
	var bar_h = 6.0
	var bar_rect = Rect2(-bar_w * 0.5, -42.0, bar_w, bar_h)
	draw_rect(bar_rect, Color(0.06, 0.05, 0.1, 0.9), true)
	draw_rect(bar_rect, Color(0.2, 0.18, 0.3), false, 1.2)
	
	# Fill level
	var fill_w = (bar_w - 2.0) * cannon.charge_pct
	if fill_w > 0.5:
		var fill_rect = Rect2(-bar_w * 0.5 + 1.0, -41.0, fill_w, bar_h - 2.0)
		var fill_col: Color
		if cannon.charge_pct < 0.5:
			fill_col = Color(0.2, 0.9, 0.4).lerp(Color(1.0, 0.85, 0.2), cannon.charge_pct * 2.0)
		else:
			fill_col = Color(1.0, 0.85, 0.2).lerp(Color(1.0, 0.3, 0.2), (cannon.charge_pct - 0.5) * 2.0)
		draw_rect(fill_rect, fill_col, true)
		
		# White needle tick at current point
		var tick_x = -bar_w * 0.5 + 1.0 + fill_w
		draw_line(Vector2(tick_x, -43.0), Vector2(tick_x, -35.0), Color.WHITE, 1.5)
	
	# 3. Trajectory line indicating locked angle
	var fire_dir = Vector2.from_angle(cannon.locked_angle)
	var muzzle_offset = Vector2(0, -4) + fire_dir * 25.0
	var line_end = muzzle_offset + fire_dir * 50.0
	draw_dashed_line(muzzle_offset, line_end, Color(1.0, 1.0, 1.0, 0.65), 1.5, 4.0)

func _draw_idle_prompt() -> void:
	if cannon.is_dead:
		return
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	var prompt_str = "HOLD [SPACE]" if cannon.player_id == Cannon.PlayerID.BLUE else "HOLD [ENTER]"
	if cannon.is_ai_controlled:
		prompt_str = "AI AUTO"
	
	var col = Color(0.65, 0.7, 0.85, 0.45)
	draw_string(font, Vector2(-40, -36), prompt_str, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, col)
