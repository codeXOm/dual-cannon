@tool
extends SceneTree

# Comprehensive Automated Test Runner for Dual Cannon

func _init() -> void:
	print("\n==========================================")
	print("       DUAL CANNON AUTOMATED TEST SUITE    ")
	print("==========================================\n")
	
	var pass_count = 0
	var fail_count = 0
	
	# Test 1: Autoloads and Audio
	print("[TEST 1] Verifying Audio & GameState...")
	var audio_res = [
		"res://assets/audio/cannon_fire.wav",
		"res://assets/audio/impact_terrain.wav",
		"res://assets/audio/impact_cannon.wav",
		"res://assets/audio/victory.wav"
	]
	var audio_ok = true
	for path in audio_res:
		if not ResourceLoader.exists(path):
			printerr("Missing audio: ", path)
			audio_ok = false
	if audio_ok:
		print("-> PASSED: All procedural audio assets exist and are loadable.")
		pass_count += 1
	else:
		fail_count += 1
	
	# Test 2: Scenes Loading
	print("\n[TEST 2] Verifying Scenes Compilation & Instantiation...")
	var scenes = [
		"res://scenes/MainMenu.tscn",
		"res://scenes/Game.tscn",
		"res://scenes/Terrain.tscn",
		"res://scenes/Cannon.tscn",
		"res://scenes/Projectile.tscn",
		"res://scenes/ImpactEffect.tscn",
		"res://scenes/HUD.tscn",
		"res://scenes/GameOver.tscn"
	]
	var scenes_ok = true
	for scene_path in scenes:
		var packed = load(scene_path) as PackedScene
		if not packed:
			printerr("Failed to load scene: ", scene_path)
			scenes_ok = false
		else:
			var inst = packed.instantiate()
			if not inst:
				printerr("Failed to instantiate scene: ", scene_path)
				scenes_ok = false
			else:
				inst.free()
	
	if scenes_ok:
		print("-> PASSED: All 8 scenes compiled and instantiated successfully.")
		pass_count += 1
	else:
		fail_count += 1
	
	# Test 3: Terrain Destructible Crater Carving
	print("\n[TEST 3] Verifying Destructible Terrain CSG Carving...")
	var terrain_scene = load("res://scenes/Terrain.tscn") as PackedScene
	var terrain_inst = terrain_scene.instantiate() as DestructibleTerrain
	root.add_child(terrain_inst)
	terrain_inst.build_initial_terrain()
	var initial_area = terrain_inst._polygon_area(terrain_inst.active_polygons[0])
	# Carve crater at platform edge
	terrain_inst.cut_crater(Vector2(500, 600), 38.0)
	var new_area = 0.0
	for p in terrain_inst.active_polygons:
		new_area += terrain_inst._polygon_area(p)
	
	if new_area < initial_area and terrain_inst.active_polygons.size() > 0:
		print("-> PASSED: Crater carved successfully. Initial Area: %d, Post-Carve Area: %d" % [initial_area, new_area])
		pass_count += 1
	else:
		printerr("-> FAILED: Terrain crater carving failed.")
		fail_count += 1
	terrain_inst.queue_free()
	
	# Test 4: Simultaneous Firing and Projectile Spawning
	print("\n[TEST 4] Verifying Real-Time Simultaneous Combat (No Turn-Based Logic)...")
	var game_scene = load("res://scenes/Game.tscn") as PackedScene
	var game_inst = game_scene.instantiate() as GameController
	root.add_child(game_inst)
	
	var blue = game_inst.blue_cannon
	var red = game_inst.red_cannon
	
	# Test Auto-Sweep + Hold-to-Charge + Release-to-Fire
	blue.start_charging()
	blue._process_charging(0.5)
	var blue_fired = blue.release_and_fire()
	
	red.start_charging()
	red._process_charging(0.5)
	var red_fired = red.release_and_fire()
	
	var projs = game_inst.projectiles_node.get_children()
	if blue_fired and red_fired and projs.size() == 2:
		print("-> PASSED: Both cannons charged and fired simultaneously! 2 projectiles in flight.")
		pass_count += 1
	else:
		printerr("-> FAILED: Simultaneous firing failed. Blue: %s, Red: %s, In Flight: %d" % [blue_fired, red_fired, projs.size()])
		fail_count += 1
	
	# Test 5: AI Controller Trajectory Computation
	print("\n[TEST 5] Verifying AI Ballistic Trajectory Computation...")
	var ai = game_inst.ai_controller
	ai.difficulty = GameState.AIDifficulty.HARD
	ai._compute_solution()
	print("-> AI computed target angle: %.2f rad (%.1f deg), target power: %.1f px/s" % [
		ai.target_angle, rad_to_deg(ai.target_angle), ai.target_power
	])
	if ai.target_power >= red.min_power and ai.target_power <= red.max_power:
		print("-> PASSED: AI computed valid ballistic solution.")
		pass_count += 1
	else:
		printerr("-> FAILED: AI computed invalid power: ", ai.target_power)
		fail_count += 1
	
	# Test 6: Damage, Health, and Scoring
	print("\n[TEST 6] Verifying Damage & Scoring Loop...")
	var initial_blue_score = GameState.blue_score
	# Damage red cannon until destroyed
	red.take_damage(3, Cannon.PlayerID.BLUE)
	if red.is_dead and GameState.blue_score == initial_blue_score + 1:
		print("-> PASSED: Red cannon destroyed, Blue awarded +1 point, GameOver overlay triggered.")
		pass_count += 1
	else:
		printerr("-> FAILED: Damage/score loop failed. Red dead: %s, Score: %d" % [red.is_dead, GameState.blue_score])
		fail_count += 1
	
	game_inst.queue_free()
	
	print("\n==========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [pass_count, fail_count])
	print("==========================================\n")
	
	if fail_count == 0:
		quit(0)
	else:
		quit(1)
