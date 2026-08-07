extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	SignalBus.player_deployment_finished.connect(_on_player_deployment_finished)
	SignalBus.combat_ended.connect(_on_combat_ended)

	if tilemap:
		EnvironmentManager.generate_map(tilemap)

		# Broadcast environment bounds to decouple camera setup
		var bounds: Rect2 = EnvironmentManager.get_map_bounds()
		SignalBus.environment_bounds_changed.emit(bounds)

	PhaseManager.start_combat()

func _on_player_deployment_finished() -> void:
	# Hide Deployment UI
	var deployment_ui = canvas_layer.get_node_or_null("DeploymentUI")
	if deployment_ui:
		deployment_ui.visible = false

	# Player done -> tell CombatManager (or directly AIManager) to deploy enemies
	var roster: Array = []
	if GameState.current_mission and GameState.current_mission is MissionData:
		roster = GameState.current_mission.enemy_roster
	else:
		print("CombatManager: No current mission found, using empty roster for deployment.")

	var enemy_zones = EnvironmentManager.get_enemy_deployment_zones()
	SignalBus.enemy_deployment_requested.emit(roster, enemy_zones)

func _on_combat_ended(result: String) -> void:
	# Show result modal and then change scene
	var modal = AcceptDialog.new()
	if result == "victory":
		modal.title = "Victory!"
		modal.dialog_text = "You have defeated all enemies."
	else:
		modal.title = "Defeat!"
		modal.dialog_text = "Your forces have been routed."

	canvas_layer.add_child(modal)
	modal.popup_centered()
	modal.confirmed.connect(func(): SignalBus.change_scene_requested.emit("post_battle"))
