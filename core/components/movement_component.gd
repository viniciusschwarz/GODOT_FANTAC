class_name MovementComponent extends Node

## Translates pathfinding data into coordinate changes.
## Operates entirely in Vector3i simulation space.

var current_coord: Vector3i = Vector3i.ZERO
var _map_manager: MapManager
var _stats: UnitStats

## Injected by the Unit container.
func initialize(start_coord: Vector3i, map_manager: MapManager, stats: UnitStats) -> void:
	current_coord = start_coord
	_map_manager = map_manager
	_stats = stats

## Evaluates if a target coordinate is within the unit's movement range limit.
func can_reach(target_coord: Vector3i, available_ap: int) -> bool:
	# EXTERNAL ACCESS NOTE: Querying the injected MapManager reference
	var path: Array[Vector3i] = _map_manager.request_path(current_coord, target_coord)

	if path.is_empty():
		return false

	# Simple AP calculation (can be expanded based on tile weight)
	var max_tiles_allowed: int = available_ap * _stats.base_movement_speed

	# -1 because the path array includes the starting tile
	return (path.size() - 1) <= max_tiles_allowed

## Instantly updates the logical coordinate.
## Visual interpolation (walking animations) will be handled by a separate visual system.
func move_to_coord(target_coord: Vector3i) -> void:
	# EXTERNAL ACCESS NOTE: Querying the injected MapManager reference
	var path: Array[Vector3i] = _map_manager.request_path(current_coord, target_coord)

	if path.is_empty():
		push_warning("MovementComponent: No valid path to %s" % target_coord)
		return

	# In a WeGo system, execution is instant logically, but visually tweened.
	# For the simulation, we simply update to the final destination.
	current_coord = target_coord

	print("Unit moved logically to %s." % current_coord)
