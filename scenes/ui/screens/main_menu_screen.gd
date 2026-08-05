extends Control

func _ready():
	$VBoxContainer/NewCampaignButton.pressed.connect(_on_new_campaign)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)

	$VBoxContainer/ContinueButton.disabled = not SaveManager.has_save_file()

func _on_new_campaign():
	GameState.clear_state()
	SceneManager.goto_scene("res://scenes/ui/screens/war_desk_screen.tscn")

func _on_continue():
	SceneManager.goto_scene("res://scenes/ui/screens/war_desk_screen.tscn")

func _on_settings():
	var settings = preload("res://scenes/ui/overlays/settings_screen.tscn").instantiate()
	add_child(settings)

func _on_quit():
	get_tree().quit()
