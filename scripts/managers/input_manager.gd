extends Node

## InputManager Autoload
## Handles global input events and translates them into semantic signals
## avoiding direct input querying in individual scripts like TacticalCamera2D or DeploymentUI.

func _process(_delta: float) -> void:
	_handle_camera_pan()

func _input(event: InputEvent) -> void:
	_handle_camera_zoom(event)
	_handle_z_level(event)
	_handle_mouse_clicks(event)

func _handle_camera_pan() -> void:
	var input_vector: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_W): input_vector.y -= 1
	if Input.is_key_pressed(KEY_S): input_vector.y += 1
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1
	if Input.is_key_pressed(KEY_D): input_vector.x += 1

	if input_vector != Vector2.ZERO:
		SignalBus.camera_pan_input.emit(input_vector.normalized())
	else:
		SignalBus.camera_pan_input.emit(Vector2.ZERO)

func _handle_camera_zoom(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			SignalBus.camera_zoom_input.emit(1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			SignalBus.camera_zoom_input.emit(-1.0)

func _handle_z_level(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_PAGEUP or event.keycode == KEY_EQUAL:
			SignalBus.camera_z_level_input.emit(1)
		elif event.keycode == KEY_PAGEDOWN or event.keycode == KEY_MINUS:
			SignalBus.camera_z_level_input.emit(-1)

func _handle_mouse_clicks(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Since we don't have the camera, we emit the raw viewport position or get the global position if we can.
		# However, InputEventMouseButton position is relative to viewport.
		# A better approach for 2D world clicks is to have a listener in the active scene that maps viewport to global.
		# Or emit the raw event and let interested listeners convert it using their canvas transform.
		# For simplicity, we can emit viewport position. Listeners that are CanvasItems can use get_global_mouse_position() directly when this fires.
		SignalBus.map_clicked.emit(event.position)
