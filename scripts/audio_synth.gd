@tool
extends SceneTree

# Generates procedural 16-bit PCM WAV sound effects for Dual Cannon
func _init() -> void:
	print("Generating procedural audio assets...")
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	
	create_cannon_fire_wav("res://assets/audio/cannon_fire.wav")
	create_impact_terrain_wav("res://assets/audio/impact_terrain.wav")
	create_impact_cannon_wav("res://assets/audio/impact_cannon.wav")
	create_victory_wav("res://assets/audio/victory.wav")
	create_ui_hover_wav("res://assets/audio/ui_hover.wav")
	create_ui_click_wav("res://assets/audio/ui_click.wav")
	
	print("Audio generation complete!")
	quit(0)

func create_wav_file(path: String, samples: PackedByteArray, sample_rate: int = 22050) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open file for writing: ", path)
		return
	
	var data_size = samples.size()
	var chunk_size = 36 + data_size
	
	# RIFF chunk descriptor
	file.store_string("RIFF")
	file.store_32(chunk_size)
	file.store_string("WAVE")
	
	# "fmt " sub-chunk
	file.store_string("fmt ")
	file.store_32(16) # Subchunk1Size for PCM
	file.store_16(1)  # AudioFormat 1 = PCM
	file.store_16(1)  # NumChannels 1 = Mono
	file.store_32(sample_rate) # SampleRate
	file.store_32(sample_rate * 2) # ByteRate (SampleRate * NumChannels * BitsPerSample/8)
	file.store_16(2)  # BlockAlign (NumChannels * BitsPerSample/8)
	file.store_16(16) # BitsPerSample
	
	# "data" sub-chunk
	file.store_string("data")
	file.store_32(data_size)
	file.store_buffer(samples)
	file.close()
	print("Wrote audio file: ", path, " (", data_size, " bytes)")

# 1. Cannon Fire: Low punch boom with exponential pitch drop and noise pop
func create_cannon_fire_wav(path: String) -> void:
	var rate = 22050
	var duration = 0.35
	var num_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / rate
		var env = exp(-t * 14.0)
		# Pitch drops from 220 Hz down to 45 Hz
		var freq = 45.0 + 175.0 * exp(-t * 22.0)
		phase += freq * TAU / rate
		var sine_val = sin(phase)
		var noise_val = (randf() * 2.0 - 1.0) * exp(-t * 30.0) * 0.4
		var sample_f = clampf((sine_val * 0.8 + noise_val) * env, -1.0, 1.0)
		var sample_i = int(sample_f * 32767.0)
		bytes.encode_s16(i * 2, sample_i)
	
	create_wav_file(path, bytes, rate)

# 2. Impact Terrain: Muffled crunchy thud
func create_impact_terrain_wav(path: String) -> void:
	var rate = 22050
	var duration = 0.3
	var num_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var lp = 0.0
	for i in range(num_samples):
		var t = float(i) / rate
		var env = exp(-t * 18.0)
		var white = (randf() * 2.0 - 1.0)
		# Simple low-pass filter for dirt/ground thud
		lp += (white - lp) * 0.25
		var sine_thud = sin(t * 90.0 * TAU) * exp(-t * 25.0)
		var sample_f = clampf((lp * 0.6 + sine_thud * 0.4) * env, -1.0, 1.0)
		var sample_i = int(sample_f * 32767.0)
		bytes.encode_s16(i * 2, sample_i)
	
	create_wav_file(path, bytes, rate)

# 3. Impact Cannon: Heavy metallic crunchy explosion
func create_impact_cannon_wav(path: String) -> void:
	var rate = 22050
	var duration = 0.45
	var num_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(num_samples):
		var t = float(i) / rate
		var env = exp(-t * 9.0)
		var noise = (randf() * 2.0 - 1.0) * exp(-t * 15.0)
		phase1 += (180.0 * exp(-t * 10.0)) * TAU / rate
		phase2 += 340.0 * TAU / rate # metallic ring
		var metal = sin(phase2) * exp(-t * 12.0) * 0.3
		var boom = sin(phase1) * 0.5
		var sample_f = clampf((boom + noise * 0.5 + metal) * env, -1.0, 1.0)
		var sample_i = int(sample_f * 32767.0)
		bytes.encode_s16(i * 2, sample_i)
	
	create_wav_file(path, bytes, rate)

# 4. Victory Chime: Joyful ascending triad chime
func create_victory_wav(path: String) -> void:
	var rate = 22050
	var duration = 0.8
	var num_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var note_dur = 0.18
	
	for i in range(num_samples):
		var t = float(i) / rate
		var note_idx = int(t / note_dur)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var note_t = fmod(t, note_dur)
		var freq = notes[note_idx]
		var env = exp(-note_t * 6.0)
		var sine = sin(t * freq * TAU)
		var harmonic = sin(t * freq * 2.0 * TAU) * 0.25
		var sample_f = clampf((sine + harmonic) * env * 0.7, -1.0, 1.0)
		var sample_i = int(sample_f * 32767.0)
		bytes.encode_s16(i * 2, sample_i)
	
	create_wav_file(path, bytes, rate)

# 5. UI Hover: Short soft high-frequency chime
func create_ui_hover_wav(path: String) -> void:
	var rate = 22050
	var duration = 0.06
	var num_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / rate
		var env = exp(-t * 60.0)
		var sine = sin(t * 880.0 * TAU)
		var sample_f = clampf(sine * env * 0.35, -1.0, 1.0)
		var sample_i = int(sample_f * 32767.0)
		bytes.encode_s16(i * 2, sample_i)
	
	create_wav_file(path, bytes, rate)

# 6. UI Click: Snappy high-frequency tactile blip
func create_ui_click_wav(path: String) -> void:
	var rate = 22050
	var duration = 0.08
	var num_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / rate
		var env = exp(-t * 45.0)
		# Quick rising pitch blip 520Hz -> 1040Hz
		var freq = 520.0 + t * 6500.0
		var sine = sin(t * freq * TAU)
		var sample_f = clampf(sine * env * 0.5, -1.0, 1.0)
		var sample_i = int(sample_f * 32767.0)
		bytes.encode_s16(i * 2, sample_i)
	
	create_wav_file(path, bytes, rate)
