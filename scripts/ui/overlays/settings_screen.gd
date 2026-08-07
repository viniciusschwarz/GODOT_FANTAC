extends WindowBase

func _ready() -> void:

	# Keep the old apply button functional if there was logic, but we can hook it here later
	var apply_btn = $BackgroundPanel/VBoxContainer/Body/VBoxContainer/HBoxContainer/ApplyButton
	if apply_btn:
		apply_btn.pressed.connect(_on_apply_pressed)

func _on_apply_pressed() -> void:
	print("Settings applied.")
