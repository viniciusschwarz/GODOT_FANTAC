extends Control

func _ready():
	$ReturnButton.pressed.connect(_on_return)

func _on_return():
	# Process GameState.last_battle_results here
	SignalBus.change_scene_requested.emit("war_desk")
