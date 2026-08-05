extends CanvasLayer

func _ready():
	$Panel/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$Panel/VBoxContainer/SurrenderButton.pressed.connect(_on_surrender_pressed)

func _on_resume_pressed():
	queue_free()

func _on_settings_pressed():
	var settings = preload("res://scenes/ui/overlays/settings_screen.tscn").instantiate()
	add_child(settings)

func _on_surrender_pressed():
	# For MVP, go back to main menu
	SceneManager.goto_scene("res://scenes/ui/screens/main_menu_screen.tscn")
	queue_free()
