extends Node

## PlayerDeploymentManager Autoload
## Handles spawning player units during the deployment phase.
## Listens to spawn requests from the UI.

var dummy_unit_scene: PackedScene = preload("res://scenes/entities/unit/dummy_unit.tscn")
var deployed_units: Array[Node] = []

func _ready() -> void:
	SignalBus.player_deployment_requested.connect(_on_player_deployment_requested)
	SignalBus.player_deployment_confirmed.connect(_on_player_deployment_confirmed)

func _on_player_deployment_requested(unit_type: String, grid_pos: Vector2i) -> void:
	if PhaseManager.current_phase != PhaseManager.Phase.DEPLOYMENT:
		return

	if grid_pos not in MapGenerator.deployable_tiles:
		print("PlayerDeploymentManager: Cannot deploy here. Not a valid deploy zone.")
		return

	if not dummy_unit_scene:
		return

	var unit: Node = dummy_unit_scene.instantiate()
	unit.position = GridManager.get_world_position(grid_pos)

	var z: int = GridManager.get_tile_data(grid_pos)["z_height"]
	unit.position.y -= z * 16.0

	# Minimal placeholder customization based on type
	if unit.has_node("ColorRect"):
		if unit_type == "Swordsman":
			unit.get_node("ColorRect").color = Color.RED
		else:
			unit.get_node("ColorRect").color = Color.YELLOW

	# Try to find Battlefield Units container, fallback to root
	var battlefield_units: Node = null
	if SceneManager.current_scene and SceneManager.current_scene.name == "Battlefield":
		battlefield_units = SceneManager.current_scene.get_node_or_null("Units")

	if battlefield_units:
		battlefield_units.add_child(unit)
	else:
		get_tree().root.add_child(unit)

	# Initialize components via DI
	if unit.has_node("MovementComponent"):
		unit.get_node("MovementComponent").initialize(3.0)
	if unit.has_node("HealthComponent"):
		unit.get_node("HealthComponent").initialize(100)

	deployed_units.append(unit)
	print("PlayerDeploymentManager: Spawned ", unit_type, " at ", grid_pos)
	SignalBus.unit_spawned.emit(unit)

func _on_player_deployment_confirmed() -> void:
	if PhaseManager.current_phase == PhaseManager.Phase.DEPLOYMENT:
		print("PlayerDeploymentManager: Player deployment confirmed.")
		PhaseManager.end_deployment_phase()
