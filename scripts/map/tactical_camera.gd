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
var current_view_z_level: int = 0

func _ready() -> void:
	target_zoom = zoom
	# Ensure the initial Z-level is broadcasted
	call_deferred("_broadcast_z_level")

func _process(delta: float) -> void:
	_handle_movement(delta)
	_handle_zoom(delta)

	# We rely on the built-in limit_left, limit_right, limit_top, limit_bottom
	# for boundary clamping, which are set via the environment bounds later.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom += Vector2.ONE * zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom -= Vector2.ONE * zoom_speed

		target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
		target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_PAGEUP or event.keycode == KEY_EQUAL:
			_change_z_level(1)
		elif event.keycode == KEY_PAGEDOWN or event.keycode == KEY_MINUS:
			_change_z_level(-1)

func _handle_movement(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_W): input_vector.y -= 1
	if Input.is_key_pressed(KEY_S): input_vector.y += 1
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1
	if Input.is_key_pressed(KEY_D): input_vector.x += 1

	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		velocity = velocity.lerp(input_vector * pan_speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, deceleration * delta)

	# Apply velocity, scaled by current zoom to keep pan speed consistent visually
	position += (velocity / zoom.x) * delta

func _handle_zoom(delta: float) -> void:
	zoom = zoom.lerp(target_zoom, zoom_smoothing * delta)

func _change_z_level(amount: int) -> void:
	current_view_z_level += amount
	# Prevent negative Z levels (or define your own range)
	current_view_z_level = max(0, current_view_z_level)
	_broadcast_z_level()

func _broadcast_z_level() -> void:
	SignalBus.camera_z_level_changed.emit(current_view_z_level)
