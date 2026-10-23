class_name LobbyVisuals
extends Node2D

# LobbyVisuals: Atmospheric background for Dual Cannon lobby featuring silhouette terrain,
# Blue and Red duel cannons with animated sweeping barrels, and glowing ballistic trajectory arcs.

var time: float = 0.0

# Cannon Mascot Positions
var blue_pos: Vector2 = Vector2(150, 592)
var blue_angle: float = deg_to_rad(-35.0)

var red_pos: Vector2 = Vector2(1130, 592)
var red_angle: float = deg_to_rad(-145.0)

# Ambient particles
var dust_particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = -5
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(28):
		dust_particles.append({
			"pos": Vector2(rng.randf_range(40.0, 1240.0), rng.randf_range(520.0, 710.0)),
			"speed": rng.randf_range(12.0, 28.0),
			"radius": rng.randf_range(1.0, 2.5),
			"alpha": rng.randf_range(0.15, 0.5),
			"color": Color(0.2, 0.85, 1.0) if i % 2 == 0 else Color(1.0, 0.45, 0.45)
		})

func _process(delta: float) -> void:
	time += delta
	# Gently sweep barrels back and forth
	blue_angle = deg_to_rad(-42.0) + sin(time * 1.6) * deg_to_rad(22.0)
	red_angle = deg_to_rad(-138.0) - sin(time * 1.5 + 0.9) * deg_to_rad(22.0)
	
	# Update dust motes
	for p in dust_particles:
		p["pos"].y -= p["speed"] * delta
		p["pos"].x += sin(time + p["pos"].y * 0.05) * 8.0 * delta
		if p["pos"].y < 460.0:
			p["pos"].y = 710.0
			p["pos"].x = randf_range(40.0, 1240.0)
	
	queue_redraw()

func _draw() -> void:
	_draw_ambient_glows()
	_draw_trajectory_arc()
	_draw_silhouette_terrain()
	_draw_cannon_mascot(blue_pos, blue_angle, Color(0.0, 0.85, 0.95), "BLUE CANNON")
	_draw_cannon_mascot(red_pos, red_angle, Color(1.0, 0.45, 0.45), "RED CANNON")
	_draw_dust_particles()

func _draw_ambient_glows() -> void:
	# Subtle ground glow behind cannons
	var glow_rad = 75.0
	var blue_glow = Color(0.0, 0.75, 0.95, 0.12 + 0.04 * sin(time * 2.5))
	var red_glow = Color(1.0, 0.35, 0.4, 0.12 + 0.04 * cos(time * 2.5))
	draw_circle(blue_pos + Vector2(0, -6), glow_rad, blue_glow)
	draw_circle(red_pos + Vector2(0, -6), glow_rad, red_glow)

func _draw_trajectory_arc() -> void:
	# Parabolic trajectory arc connecting the two cannons
	var start_pt = blue_pos + Vector2.from_angle(blue_angle) * 24.0
	var end_pt = red_pos + Vector2.from_angle(red_angle) * 24.0
	var apex_y = 170.0 + sin(time * 1.2) * 12.0
	
	var points = PackedVector2Array()
	var seg_count = 42
	for i in range(seg_count + 1):
		var t = float(i) / seg_count
		# Parabolic interpolation
		var x = lerpf(start_pt.x, end_pt.x, t)
		var base_y = lerpf(start_pt.y, end_pt.y, t)
		var arc_offset = (4.0 * t * (1.0 - t)) * (base_y - apex_y)
		var y = base_y - arc_offset
		points.append(Vector2(x, y))
	
	# Draw glowing dual-color trajectory line
	var traj_color = Color(0.7, 0.65, 0.9, 0.25 + 0.08 * sin(time * 2.0))
	draw_polyline(points, traj_color, 2.0, true)
	
	# Animated energy pulse along the arc
	var pulse_t = fmod(time * 0.45, 1.0)
	var pulse_idx = int(pulse_t * seg_count)
	if pulse_idx < points.size():
		var pulse_pt = points[pulse_idx]
		var pulse_color = Color(0.0, 0.9, 1.0, 0.8) if pulse_t < 0.5 else Color(1.0, 0.45, 0.5, 0.8)
		draw_circle(pulse_pt, 4.0, pulse_color)
		draw_circle(pulse_pt, 8.0, Color(pulse_color.r, pulse_color.g, pulse_color.b, 0.3))

func _draw_silhouette_terrain() -> void:
	# Backdrop layer (dark silhouette)
	var bg_pts = PackedVector2Array([
		Vector2(0, 720),
		Vector2(0, 620),
		Vector2(120, 585),
		Vector2(260, 600),
		Vector2(380, 645),
		Vector2(640, 665),
		Vector2(900, 645),
		Vector2(1020, 600),
		Vector2(1160, 585),
		Vector2(1280, 620),
		Vector2(1280, 720)
	])
	draw_polygon(bg_pts, [Color(0.14, 0.09, 0.19, 0.95)])
	
	# Foreground styled terrain (dusty rose with scalloped cuts)
	var fg_pts = PackedVector2Array([
		Vector2(0, 720),
		Vector2(0, 630),
		Vector2(70, 602),
		Vector2(220, 596), # Blue platform
		Vector2(320, 632),
		Vector2(440, 668), # Center dip
		Vector2(640, 680),
		Vector2(840, 668),
		Vector2(960, 632),
		Vector2(1060, 596), # Red platform
		Vector2(1210, 602),
		Vector2(1280, 630),
		Vector2(1280, 720)
	])
	var terrain_color = Color(0.38, 0.16, 0.28, 1.0)
	draw_polygon(fg_pts, [terrain_color])
	
	# Crisp outline on top edge
	var outline_pts = PackedVector2Array([
		Vector2(0, 630),
		Vector2(70, 602),
		Vector2(220, 596),
		Vector2(320, 632),
		Vector2(440, 668),
		Vector2(640, 680),
		Vector2(840, 668),
		Vector2(960, 632),
		Vector2(1060, 596),
		Vector2(1210, 602),
		Vector2(1280, 630)
	])
	draw_polyline(outline_pts, Color(0.55, 0.25, 0.42, 1.0), 3.0, true)

func _draw_cannon_mascot(pos: Vector2, angle: float, hull_col: Color, _label: String) -> void:
	# 1. Base Track (Rounded capsule)
	var track_rect = Rect2(pos.x - 24, pos.y - 2, 48, 12)
	draw_rect(track_rect, Color(0.12, 0.12, 0.16), true)
	draw_rect(track_rect, Color(0.06, 0.06, 0.08), false, 2.0)
	
	# 2. Road Wheels
	var wheel_xs = [-14.0, 0.0, 14.0]
	for wx in wheel_xs:
		var w_pos = Vector2(pos.x + wx, pos.y + 4.0)
		draw_circle(w_pos, 4.5, Color(0.25, 0.26, 0.32))
		draw_arc(w_pos, 4.5, 0.0, TAU, 14, Color(0.06, 0.06, 0.08), 1.5)
		draw_circle(w_pos, 1.8, Color(0.12, 0.12, 0.16))
	
	# 3. Rotating Barrel (drawn behind dome)
	var pivot_pos = pos + Vector2(0, -4)
	var barrel_dir = Vector2.from_angle(angle)
	var barrel_len = 25.0
	var barrel_thickness = 7.0
	var barrel_normal = Vector2(-barrel_dir.y, barrel_dir.x) * (barrel_thickness * 0.5)
	var b_p1 = pivot_pos + barrel_normal
	var b_p2 = pivot_pos - barrel_normal
	var b_p3 = pivot_pos + barrel_dir * barrel_len - barrel_normal
	var b_p4 = pivot_pos + barrel_dir * barrel_len + barrel_normal
	draw_polygon(PackedVector2Array([b_p1, b_p2, b_p3, b_p4]), [Color(0.92, 0.93, 0.96)])
	draw_polyline(PackedVector2Array([b_p1, b_p4, b_p3, b_p2]), Color(0.1, 0.1, 0.14), 1.8, true)
	
	# Muzzle tip accent
	var muzzle_pos = pivot_pos + barrel_dir * barrel_len
	draw_line(muzzle_pos + barrel_normal * 1.1, muzzle_pos - barrel_normal * 1.1, Color(0.85, 0.25, 0.3) if hull_col.r > 0.5 else Color(0.0, 0.75, 0.95), 2.5)
	
	# 4. Dome Hull (Semicircle above track)
	var dome_radius = 16.0
	var dome_center = pos + Vector2(0, -2)
	var dome_points = PackedVector2Array()
	var outline_points = PackedVector2Array()
	dome_points.append(dome_center)
	var segments = 18
	for i in range(segments + 1):
		var a = -PI + (float(i) / segments) * PI
		var pt = dome_center + Vector2(cos(a), sin(a)) * dome_radius
		dome_points.append(pt)
		outline_points.append(pt)
	draw_polygon(dome_points, [hull_col])
	draw_polyline(outline_points, Color(0.08, 0.08, 0.12), 2.5, true)
	
	# Center pivot ring
	draw_circle(dome_center, 4.0, Color(0.95, 0.95, 0.98))
	draw_arc(dome_center, 4.0, 0.0, TAU, 12, Color(0.1, 0.1, 0.15), 1.5)
	
	# 5. Bright Green Health Pips above cannon
	var pip_spacing = 9.0
	var start_x = pos.x - pip_spacing
	var pip_y = pos.y - 25.0
	for i in range(3):
		var pip_pos = Vector2(start_x + i * pip_spacing, pip_y)
		draw_circle(pip_pos, 3.2, Color(0.2, 0.95, 0.45))
		draw_arc(pip_pos, 3.2, 0.0, TAU, 12, Color(0.08, 0.08, 0.12), 1.2)

func _draw_dust_particles() -> void:
	for p in dust_particles:
		var alpha = p["alpha"] * (0.6 + 0.4 * sin(time * 3.0 + p["pos"].y))
		var col = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		draw_circle(p["pos"], p["radius"], col)
