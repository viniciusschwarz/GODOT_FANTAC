# File: res://core/components/los_component.gd
class_name LOSComponent extends Node

## TACTICAL VISION MATH
## Calculates 3D grid line-of-sight using linear interpolation voxel traversal.

var _map_manager: MapManager
var _unit_coord: Vector3i

## Injected by the Unit container upon initialization.
func initialize(map_manager: MapManager, starting_coord: Vector3i) -> void:
	_map_manager = map_manager
	_unit_coord = starting_coord

## Updates the unit's internal position tracker (called by MovementComponent).
func update_position(new_coord: Vector3i) -> void:
	_unit_coord = new_coord

## Evaluates if a clear line exists from this unit to a target coordinate.
func has_line_of_sight(target_coord: Vector3i) -> bool:
	if not _map_manager:
		push_error("LOSComponent: MapManager reference is missing!")
		return false

	var start: Vector3i = _unit_coord
	var end: Vector3i = target_coord
	
	var dx: int = abs(end.x - start.x)
	var dy: int = abs(end.y - start.y)
	var dz: int = abs(end.z - start.z)
	
	# The maximum number of grid steps required to reach the target
	var steps: int = max(dx, max(dy, dz))
	
	if steps == 0:
		return true # Target is on the exact same tile
		
	# Traverse the grid mathematically
	for i: int in range(1, steps):
		var t: float = float(i) / float(steps)
		
		# Interpolate to find the next grid voxel
		var check_x: int = roundi(lerpf(float(start.x), float(end.x), t))
		var check_y: int = roundi(lerpf(float(start.y), float(end.y), t))
		var check_z: int = roundi(lerpf(float(start.z), float(end.z), t))
		var check_coord: Vector3i = Vector3i(check_x, check_y, check_z)
		
		# EXTERNAL ACCESS NOTE: Querying the MapManager for tile data
		var tile: TacticalTileData = _map_manager.get_tile_data(check_coord)
		
		if tile and tile.blocks_vision:
			# If the ray hits a blocking tile, LoS is immediately broken
			return false
			
	return true