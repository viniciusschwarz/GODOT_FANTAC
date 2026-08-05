extends Control

func _ready():
	$StartButton.pressed.connect(_on_start)

func _on_start():
	# GameState.active_deployment_list = ...
	SceneManager.goto_scene("res://scenes/ui/screens/battle_screen.tscn")
