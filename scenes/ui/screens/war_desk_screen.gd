extends Control

func _ready():
	SaveManager.save_game("auto_save", {})
	$HBoxContainer/BarracksButton.pressed.connect(_on_barracks)
	$HBoxContainer/AcceptButton.pressed.connect(_on_accept)
	$HBoxContainer/SaveExitButton.pressed.connect(_on_save_exit)

func _on_barracks():
	SceneManager.goto_scene("res://scenes/ui/screens/barracks_screen.tscn")

func _on_accept():
	# GameState.current_mission = selected_mission
	SceneManager.goto_scene("res://scenes/ui/screens/deployment_screen.tscn")

func _on_save_exit():
	SaveManager.save_game("auto_save", {})
	SceneManager.goto_scene("res://scenes/ui/screens/main_menu_screen.tscn")
