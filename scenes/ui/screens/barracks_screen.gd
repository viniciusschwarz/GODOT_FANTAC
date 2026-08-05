extends Control

func _ready():
	$ReturnButton.pressed.connect(_on_return)

func _on_return():
	SceneManager.goto_scene("res://scenes/ui/screens/war_desk_screen.tscn")
