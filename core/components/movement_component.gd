# File: res://core/components/movement_component.gd
class_name MovementComponent extends Node

## THE PHYSICAL LOCATOR
## Holds the unit's mathematical coordinate and grid references.

var current_coord: Vector3i
var map_manager: MapManager
var _base_stats: UnitStats

## Injected by the Unit container upon initialization.
func initialize(starting_coord: Vector3i, injected_map_manager: MapManager, stats: UnitStats) -> void:
	current_coord = starting_coord
	map_manager = injected_map_manager
	_base_stats = stats

## Updates the mathematical coordinate of the unit.
## Called by ActionData during the Execution Phase.
func update_position(new_coord: Vector3i) -> void:
	current_coord = new_coord
