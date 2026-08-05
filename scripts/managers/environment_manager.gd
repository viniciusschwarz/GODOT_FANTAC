extends Node2D

## ENVIRONMENT MANAGER
## Controls lighting, weather, and time of day without interfering with game logic.

@export var day_night_cycle: bool = true
@export var day_color: Color = Color.WHITE
@export var night_color: Color = Color(0.2, 0.2, 0.4, 1.0)
@export var turn_duration: float = 60.0 # Time to transition fully if driven by time

var canvas_modulate: CanvasModulate
var weather_particles: GPUParticles2D

var is_night: bool = false

func _ready() -> void:
	# Set up a CanvasModulate for Day/Night
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = day_color
	add_child(canvas_modulate)

	# Set up placeholder particles for Weather
	weather_particles = GPUParticles2D.new()
	weather_particles.emitting = false
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(1000, 1, 1)
	material.direction = Vector3(0, 1, 0)
	material.spread = 10
	material.initial_velocity_min = 200
	material.initial_velocity_max = 300
	weather_particles.process_material = material
	weather_particles.position = Vector2(500, -100) # Position above the screen
	weather_particles.amount = 100
	weather_particles.lifetime = 4.0
	add_child(weather_particles)

func transition_to_night(duration: float = 2.0) -> void:
	is_night = true
	var tween = get_tree().create_tween()
	tween.tween_property(canvas_modulate, "color", night_color, duration)

func transition_to_day(duration: float = 2.0) -> void:
	is_night = false
	var tween = get_tree().create_tween()
	tween.tween_property(canvas_modulate, "color", day_color, duration)

func start_rain() -> void:
	weather_particles.emitting = true

func stop_weather() -> void:
	weather_particles.emitting = false
