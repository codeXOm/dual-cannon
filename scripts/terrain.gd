class_name DestructibleTerrain
extends Node2D

# DestructibleTerrain: Progressive procedural terrain generation + boolean CSG crater deformation
# Generates distinct, balanced, and difficulty-scaled terrain patterns for each level.

signal terrain_damaged(pos: Vector2, radius: float)

@export var terrain_color: Color = Color(0.44, 0.21, 0.36, 1.0) # Dusty magenta / muted rose
@export var border_color: Color = Color(0.22, 0.08, 0.18, 1.0)
@export var border_width: float = 3.0

var base_polygon: PackedVector2Array = []
var active_polygons: Array[PackedVector2Array] = []

var current_generated_level: int = 1
var blue_platform_y: float = 510.0
var red_platform_y: float = 510.0

@onready var visual_container: Node2D = $Visuals
@onready var static_body: StaticBody2D = $StaticBody2D

func _ready() -> void:
	build_initial_terrain()

func build_initial_terrain() -> void:
	generate_level(GameState.current_level if GameState else 1)

## Generates a unique, fair, and difficulty-appropriate ground pattern for the specified level.
func generate_level(level: int) -> void:
	current_generated_level = level
	base_polygon.clear()
	
	var points: Array[Vector2] = []
	
	# Determine platform elevations based on level difficulty
	match level:
		1:
			# Beginner: Perfectly matched heights, stable flat positions
			blue_platform_y = 510.0
			red_platform_y = 510.0
		2:
			# Easy: Minor elevation difference (10px)
			blue_platform_y = 515.0
			red_platform_y = 505.0
		3:
			# Intermediate: Moderate elevation difference (30px)
			blue_platform_y = 525.0
			red_platform_y = 495.0
		4:
			# Challenging: Significant elevation difference (70px) - Blue on high bluff
			blue_platform_y = 465.0
			red_platform_y = 535.0
		5:
			# Advanced: Twin peaks setup, balanced platforms
			blue_platform_y = 515.0
			red_platform_y = 515.0
		_:
			# Level 6+ (Expert & Endless): Deterministic pseudo-random platform heights
			var rng = RandomNumberGenerator.new()
			rng.seed = hash("dc_lvl_plat_%d" % level)
			var delta_h = rng.randf_range(-45.0, 45.0)
			blue_platform_y = clampf(490.0 - delta_h * 0.5, 450.0, 540.0)
			red_platform_y = clampf(490.0 + delta_h * 0.5, 450.0, 540.0)
	
	# --- 1. Left Platform (Blue Cannon: X=190) ---
	# Guaranteed flat zone from X=-10 to X=280
	points.append(Vector2(-10.0, blue_platform_y))
	points.append(Vector2(80.0, blue_platform_y))
	points.append(Vector2(160.0, blue_platform_y))
	points.append(Vector2(220.0, blue_platform_y))
	points.append(Vector2(280.0, blue_platform_y))
	
	# --- 2. Central Playable Region (X=280 to X=1000) ---
	var step_x = 24.0
	var cur_x = 280.0 + step_x
	while cur_x < 1000.0:
		var t = (cur_x - 280.0) / (1000.0 - 280.0) # 0.0 at left, 1.0 at right
		var curve_y = _evaluate_center_height(cur_x, t, level)
		
		# Smoothly blend central curve into left platform (X=280..350)
		# and right platform (X=930..1000) using Hermite smoothstep
		var final_y = curve_y
		if cur_x < 350.0:
			var blend_l = _smoothstep(280.0, 350.0, cur_x)
			final_y = lerpf(blue_platform_y, curve_y, blend_l)
		elif cur_x > 930.0:
			var blend_r = _smoothstep(930.0, 1000.0, cur_x)
			final_y = lerpf(curve_y, red_platform_y, blend_r)
		
		points.append(Vector2(cur_x, final_y))
		cur_x += step_x
	
	# --- 3. Right Platform (Red Cannon: X=1090) ---
	# Guaranteed flat zone from X=1000 to X=1290
	points.append(Vector2(1000.0, red_platform_y))
	points.append(Vector2(1060.0, red_platform_y))
	points.append(Vector2(1120.0, red_platform_y))
	points.append(Vector2(1200.0, red_platform_y))
	points.append(Vector2(1290.0, red_platform_y))
	
	# --- 4. Seal Bottom and Sides (Screen height is 720) ---
	points.append(Vector2(1290.0, 730.0))
	points.append(Vector2(-10.0, 730.0))
	
	base_polygon = PackedVector2Array(points)
	reset_terrain()

## Evaluates the procedural height for the central region between X=280 and X=1000
func _evaluate_center_height(x: float, t: float, level: int) -> float:
	match level:
		1:
			# Beginner: Broad gentle valley dipping smoothly to Y ≈ 595 at center (X=640)
			# Wide open line of sight, minimal shot obstruction
			return 510.0 + 85.0 * sin(t * PI)
		2:
			# Easy: Rolling dunes with two moderate dips (Y ≈ 585) and gentle central swell (Y ≈ 555)
			var base_h = lerpf(515.0, 505.0, t)
			return base_h + 65.0 * sin(t * PI) - 35.0 * sin(t * 3.0 * PI)
		3:
			# Intermediate: Prominent central ridge (Y ≈ 470 at X=640) flanked by deep gullies (Y ≈ 615)
			# Requires higher elevation arcs or intentional tunneling
			var base_h = lerpf(525.0, 495.0, t)
			var ridge = -45.0 * sin(t * PI)
			var dips = 95.0 * (1.0 - cos(t * TAU * 2.0)) * 0.5
			return base_h + dips + ridge
		4:
			# Challenging: Asymmetric stepped mesa (Y ≈ 435 at X=570..710) with steep drop-offs into deep canyons (Y ≈ 625)
			var base_h = lerpf(465.0, 535.0, t)
			var mesa_center = 0.5
			var dist = abs(t - mesa_center)
			var mesa = 0.0
			if dist < 0.12:
				mesa = -70.0 # High mesa top
			elif dist < 0.22:
				var edge_t = (dist - 0.12) / 0.10
				mesa = lerpf(-70.0, 80.0, edge_t) # Steep plunge into canyon
			else:
				mesa = 80.0 * (1.0 - (dist - 0.22) / 0.28)
			return base_h + mesa
		5:
			# Advanced: Twin sharp jagged peaks (Y ≈ 410 at X=460 and X=820) and deep central gorge (Y ≈ 640 at X=640)
			# Direct line of sight completely obstructed; master mortar trajectories required
			var peak1 = -105.0 * exp(-pow((t - 0.25) / 0.08, 2.0))
			var peak2 = -105.0 * exp(-pow((t - 0.75) / 0.08, 2.0))
			var gorge = 125.0 * exp(-pow((t - 0.50) / 0.10, 2.0))
			return 515.0 + peak1 + peak2 + gorge
		_:
			# Level 6+ (Expert & Endless Progression):
			# Deterministic multi-octave harmonic synthesis seeded by level number
			var rng = RandomNumberGenerator.new()
			rng.seed = hash("dc_lvl_harmonics_%d" % level)
			
			var base_h = lerpf(blue_platform_y, red_platform_y, t)
			var harmonic_count = 3 + (level % 3)
			var val = 0.0
			
			for h in range(harmonic_count):
				var freq = float(h + 1) * PI
				var amp = rng.randf_range(25.0, 80.0) / (1.0 + float(h) * 0.4)
				var phase = rng.randf_range(0.0, TAU)
				val += amp * sin(t * freq + phase)
			
			# Ensure terrain stays in playable bounds (at least 350px sky clearance, above screen bottom 720)
			var raw_y = base_h + val
			return clampf(raw_y, 360.0, 640.0)

func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

## Returns the exact stable spawn position for the requested player cannon on current terrain
func get_spawn_position(player_id: Cannon.PlayerID) -> Vector2:
	if player_id == Cannon.PlayerID.BLUE:
		return Vector2(190.0, blue_platform_y - 10.0)
	else:
		return Vector2(1090.0, red_platform_y - 10.0)

## Queries the top surface Y coordinate of the terrain at any given X position
func get_surface_y_at(x: float) -> float:
	if base_polygon.size() < 4:
		return 510.0
	for i in range(base_polygon.size() - 3):
		var p1 = base_polygon[i]
		var p2 = base_polygon[i + 1]
		if x >= p1.x and x <= p2.x:
			var t = (x - p1.x) / maxf(p2.x - p1.x, 0.001)
			return lerpf(p1.y, p2.y, t)
	return blue_platform_y

func reset_terrain() -> void:
	active_polygons = [base_polygon.duplicate()]
	_rebuild_nodes()

func cut_crater(hit_pos: Vector2, radius: float = 38.0) -> void:
	# Generate a smooth circular cutout polygon
	var circle_poly = PackedVector2Array()
	var segments = 24
	for i in range(segments):
		var angle = (i * TAU) / segments
		circle_poly.append(hit_pos + Vector2(cos(angle), sin(angle)) * radius)
	
	var updated_polys: Array[PackedVector2Array] = []
	var clipped_any = false
	
	for poly in active_polygons:
		var clipped = Geometry2D.clip_polygons(poly, circle_poly)
		if clipped.size() > 0:
			var poly_cw = Geometry2D.is_polygon_clockwise(poly)
			for piece in clipped:
				# Discard tiny slivers
				if piece.size() >= 3 and _polygon_area(piece) > 80.0:
					# Discard hole contours (Clipper returns inner holes with opposite orientation)
					if Geometry2D.is_polygon_clockwise(piece) == poly_cw:
						updated_polys.append(piece)
			clipped_any = true
		else:
			# If completely vaporized or no overlap, keep or drop
			if Geometry2D.is_point_in_polygon(hit_pos, poly):
				clipped_any = true
			else:
				updated_polys.append(poly)
	
	if clipped_any and updated_polys.size() > 0:
		active_polygons = updated_polys
		_rebuild_nodes()
		terrain_damaged.emit(hit_pos, radius)

func _polygon_area(poly: PackedVector2Array) -> float:
	var area = 0.0
	var n = poly.size()
	for i in range(n):
		var p1 = poly[i]
		var p2 = poly[(i + 1) % n]
		area += (p1.x * p2.y - p2.x * p1.y)
	return abs(area) * 0.5

func _rebuild_nodes() -> void:
	# Clear previous visuals and colliders
	for child in visual_container.get_children():
		child.queue_free()
	for child in static_body.get_children():
		child.queue_free()
	
	# Generate new Polygon2D and CollisionPolygon2D for each active piece
	for poly in active_polygons:
		var poly2d = Polygon2D.new()
		poly2d.polygon = poly
		poly2d.color = terrain_color
		visual_container.add_child(poly2d)
		
		# Collision shape
		var col_poly = CollisionPolygon2D.new()
		col_poly.polygon = poly
		static_body.add_child(col_poly)
	
	queue_redraw()

func _draw() -> void:
	# Draw crisp border around top contours
	for poly in active_polygons:
		if poly.size() < 2:
			continue
		# Draw outline around each polygon
		var pts = Array(poly)
		pts.append(poly[0])
		draw_polyline(PackedVector2Array(pts), border_color, border_width, true)
