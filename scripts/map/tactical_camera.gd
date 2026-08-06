extends Camera2D
class_name TacticalCamera2D

@export_category("Movement")
@export var pan_speed: float = 600.0
@export var acceleration: float = 15.0
@export var deceleration: float = 10.0

@export_category("Zoom")
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.5
@export var zoom_smoothing: float = 10.0

var target_zoom: Vector2 = Vector2.ONE
var velocity: Vector2 = Vector2.ZERO
var input_vector: Vector2 = Vector2.ZERO
var current_view_z_level: int = 0

func _ready() -> void:
	target_zoom = zoom
	# Listen to centralized signals
	SignalBus.environment_bounds_changed.connect(_on_environment_bounds_changed)
	SignalBus.camera_pan_input.connect(_on_pan_input)
	SignalBus.camera_zoom_input.connect(_on_zoom_input)
	SignalBus.camera_z_level_input.connect(_on_z_level_input)

	# Ensure the initial Z-level is broadcasted
	call_deferred("_broadcast_z_level")

func _process(delta: float) -> void:
	_apply_movement(delta)
	_apply_zoom(delta)

func _on_environment_bounds_changed(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)

func _on_pan_input(direction: Vector2) -> void:
	input_vector = direction

func _on_zoom_input(zoom_change: float) -> void:
	target_zoom += Vector2.ONE * (zoom_change * zoom_speed)
	target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
	target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)

func _on_z_level_input(z_level_change: int) -> void:
	current_view_z_level += z_level_change
	current_view_z_level = max(0, current_view_z_level)
	_broadcast_z_level()

func _apply_movement(delta: float) -> void:
	if input_vector != Vector2.ZERO:
		velocity = velocity.lerp(input_vector * pan_speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, deceleration * delta)

	# Apply velocity, scaled by current zoom to keep pan speed consistent visually
	position += (velocity / zoom.x) * delta

func _apply_zoom(delta: float) -> void:
	zoom = zoom.lerp(target_zoom, zoom_smoothing * delta)

func _broadcast_z_level() -> void:
	SignalBus.camera_z_level_changed.emit(current_view_z_level)
