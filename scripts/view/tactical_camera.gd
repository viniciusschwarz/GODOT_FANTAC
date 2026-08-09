class_name TacticalCamera
extends Camera2D

@export var base_pan_speed: float = 800.0
@export var pan_smoothing: float = 15.0
@export var zoom_step: float = 0.15
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.5
@export var zoom_smoothing: float = 15.0

var target_zoom: float = 1.0
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	make_current()
	target_zoom = 1.0
	zoom = Vector2(target_zoom, target_zoom)

func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_dir.x += 1

	if input_dir.length_squared() > 0:
		input_dir = input_dir.normalized()

	var current_pan_speed: float = base_pan_speed / max(zoom.x, 0.01)
	var target_velocity: Vector2 = input_dir * current_pan_speed

	velocity = velocity.lerp(target_velocity, pan_smoothing * delta)
	position += velocity * delta

	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), zoom_smoothing * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom += zoom_step
			target_zoom = clampf(target_zoom, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom -= zoom_step
			target_zoom = clampf(target_zoom, min_zoom, max_zoom)
