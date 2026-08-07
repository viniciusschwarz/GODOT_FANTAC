class_name TacticalCamera extends Camera2D

## THE PLAYER'S EYE
## Handles panning, zooming, and Z-level focus.
## Emits changes globally so the Renderer can slice the visual elevation.

@export_category("Camera Settings")
@export var pan_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var max_z_level: int = 3

var current_z_level: int = 0
var _target_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	_target_zoom = zoom
	# Ensure the initial state is broadcasted
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.camera_z_level_changed.emit(current_z_level)

func _process(delta: float) -> void:
	_handle_panning(delta)

	# Smoothly interpolate zoom
	zoom = zoom.lerp(_target_zoom, 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	_handle_zooming(event)
	_handle_z_level_slicing(event)

func _handle_panning(delta: float) -> void:
	var move_vec: Vector2 = Vector2.ZERO

	# Assumes standard InputMap actions are defined in Project Settings
	if Input.is_action_pressed("camera_up"): move_vec.y -= 1
	if Input.is_action_pressed("camera_down"): move_vec.y += 1
	if Input.is_action_pressed("camera_left"): move_vec.x -= 1
	if Input.is_action_pressed("camera_right"): move_vec.x += 1

	position += move_vec.normalized() * pan_speed * delta * (1.0 / zoom.x)

func _handle_zooming(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		_target_zoom += Vector2(zoom_speed, zoom_speed)
	elif event.is_action_pressed("camera_zoom_out"):
		_target_zoom -= Vector2(zoom_speed, zoom_speed)

	_target_zoom.x = clampf(_target_zoom.x, min_zoom, max_zoom)
	_target_zoom.y = clampf(_target_zoom.y, min_zoom, max_zoom)

func _handle_z_level_slicing(event: InputEvent) -> void:
	var z_changed: bool = false

	if event.is_action_pressed("camera_elevation_up") and current_z_level < max_z_level:
		current_z_level += 1
		z_changed = true
	elif event.is_action_pressed("camera_elevation_down") and current_z_level > 0:
		current_z_level -= 1
		z_changed = true

	if z_changed:
		print("TacticalCamera: Z-Level Focus changed to %d" % current_z_level)
		# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
		EventBus.camera_z_level_changed.emit(current_z_level)
