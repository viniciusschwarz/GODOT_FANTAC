extends CanvasLayer

@export var settings_scene: PackedScene = preload("res://scenes/ui/overlays/settings_screen.tscn")

func _ready() -> void:
	$Panel/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$Panel/VBoxContainer/SurrenderButton.pressed.connect(_on_surrender_pressed)

func _on_resume_pressed() -> void:
	queue_free()

func _on_settings_pressed() -> void:
	if settings_scene:
		var settings = settings_scene.instantiate()
		add_child(settings)

func _on_surrender_pressed() -> void:
	# For MVP, go back to main menu
	SceneManager.goto_scene("res://scenes/ui/screens/main_menu_screen.tscn")
	queue_free()
