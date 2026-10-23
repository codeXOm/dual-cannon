class_name ImpactEffect
extends Node2D

# ImpactEffect: Handles particle explosion bursts for terrain hits and cannon impacts

@onready var flash_circle: Node2D = $Flash
@onready var spark_particles: CPUParticles2D = $SparkParticles
@onready var smoke_particles: CPUParticles2D = $SmokeParticles

var is_large: bool = false
var lifetime_timer: float = 0.8

func _ready() -> void:
	spark_particles.emitting = true
	smoke_particles.emitting = true
	
	# Flash animation
	var tween = create_tween()
	flash_circle.scale = Vector2.ZERO
	var target_scale = Vector2(2.5, 2.5) if is_large else Vector2(1.2, 1.2)
	tween.tween_property(flash_circle, "scale", target_scale, 0.08).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(flash_circle, "modulate:a", 0.0, 0.22)

func setup_terrain_burst() -> void:
	is_large = false
	if is_inside_tree():
		_apply_terrain_style()

func setup_large_explosion() -> void:
	is_large = true
	if is_inside_tree():
		_apply_explosion_style()

func _apply_terrain_style() -> void:
	spark_particles.amount = 18
	spark_particles.color = Color(0.7, 0.45, 0.6) # Magenta/rose dust
	spark_particles.initial_velocity_min = 60.0
	spark_particles.initial_velocity_max = 140.0
	smoke_particles.amount = 12
	smoke_particles.scale_amount_max = 6.0

func _apply_explosion_style() -> void:
	spark_particles.amount = 36
	spark_particles.color = Color(1.0, 0.75, 0.2) # Fiery gold/orange
	spark_particles.initial_velocity_min = 90.0
	spark_particles.initial_velocity_max = 220.0
	smoke_particles.amount = 20
	smoke_particles.scale_amount_max = 12.0
	lifetime_timer = 1.2

func _process(delta: float) -> void:
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()
