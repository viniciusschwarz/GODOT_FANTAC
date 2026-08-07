extends Control

func _ready():
	$EndBattleButton.pressed.connect(_on_end_battle)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		var pause_menu = preload("res://scenes/ui/overlays/pause_menu.tscn").instantiate()
		add_child(pause_menu)

func _on_end_battle():
	# GameState.last_battle_results = ...
	SceneManager.goto_scene("res://scenes/ui/screens/post_battle_screen.tscn")
