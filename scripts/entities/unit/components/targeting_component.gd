class_name TargetingComponent
extends Node2D
## Performs line-of-sight checks and target detection across Z-levels.

var unit_owner: Node

func _ready() -> void:
	pass

func initialize(unit: Node) -> void:
	unit_owner = unit

## Finds the nearest valid enemy within a given range.
func get_nearest_target(max_range: float, elevation: int) -> Node:
	# Placeholder for AIManager querying
	return null

## Checks if there is clear line of sight to the target, considering Z-levels and obstacles
func has_line_of_sight(target: Node) -> bool:
	if not target or not is_instance_valid(target) or not unit_owner:
		return false

	var start_pos = unit_owner.global_position
	var target_pos = target.global_position

	var start_elevation = 0
	if "current_elevation" in unit_owner:
		start_elevation = unit_owner.current_elevation

	var target_elevation = 0
	if "current_elevation" in target:
		target_elevation = target.current_elevation

	var start_grid = GridManager.get_grid_position(start_pos, start_elevation)
	var target_grid = GridManager.get_grid_position(target_pos, target_elevation)

	return GridManager.check_line_of_sight(start_grid, target_grid)
