class_name Unit extends Node2D

## THE ACTOR CONTAINER
## Holds components and routes initialization data. Contains zero combat math.

@export var unit_id: StringName = &"unit_unassigned"

@export_category("Components")
## Strict typing for node references assigned in the Inspector
@export var health_component: HealthComponent
@export var movement_component: MovementComponent
@export var ai_evaluator: AIConditionEvaluator

## Called by a spawner (e.g., BattlefieldManager) when the unit enters the map.
## @param stats: The immutable Resource defining this unit's max capabilities.
## @param ai_tree: The player-configured AITreeData strategy.
## @param starting_coord: The Vector3i simulation coordinate.
## @param map_manager: Injected reference to query the grid.
func initialize(stats: UnitStats, ai_tree: AITreeData, starting_coord: Vector3i, map_manager: MapManager) -> void:
	if not health_component or not movement_component or not ai_evaluator:
		push_error("Unit %s is missing required components!" % unit_id)
		return

	# Route data to components via Dependency Injection
	health_component.initialize(stats.max_health, unit_id)
	movement_component.initialize(starting_coord, map_manager, stats)
	ai_evaluator.initialize(ai_tree, self)

	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.unit_spawned.emit(self)
	print("Unit %s initialized at %s." % [unit_id, starting_coord])
