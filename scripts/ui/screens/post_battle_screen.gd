extends Control

func _ready():
	$ReturnButton.pressed.connect(_on_return)

	if has_node("ResultLabel"):
		var result = GameState.last_battle_results.get("result", "unknown")
		if result == "victory":
			$ResultLabel.text = "Victory!"
		elif result == "defeat":
			$ResultLabel.text = "Defeat!"
		else:
			$ResultLabel.text = "Battle Ended"

func _on_return():
	# Clear active deployment and results to prep for next mission
	GameState.active_deployment_list.clear()
	GameState.last_battle_results.clear()
	GameState.current_mission = null

	SignalBus.change_scene_requested.emit("war_desk")
