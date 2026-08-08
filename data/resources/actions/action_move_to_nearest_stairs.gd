# File: res://data/resources/actions/action_move_to_nearest_stairs.gd
class_name ActionMoveToNearestStairs extends ActionData

## TACTICAL MOVEMENT ACTION (A* UPDATE)
## Queries the MapManager's AStar graph to navigate around obstacles and find stairs.

func _init() -> void:
	execution_phase = ExecutionPhase.MOVEMENT
	target_required = false

func execute(unit: Node, _target_pos: Vector3i, _blackboard: Dictionary) -> void:
	var move_comp: MovementComponent = unit.get("movement_component")
	if not move_comp or not move_comp.map_manager:
		return
		
	var current_coord: Vector3i = move_comp.current_coord
	
	# EXTERNAL ACCESS NOTE: Querying the MapManager for stair locations
	var nearest_stairs: Vector3i = _find_nearest_stairs(current_coord, move_comp.map_manager)
	
	if nearest_stairs != Vector3i(-1, -1, -1):
		# 1. Check for Ascension
		if current_coord == nearest_stairs:
			var next_step: Vector3i = Vector3i(current_coord.x, current_coord.y, current_coord.z + 1)
			move_comp.update_position(next_step)
			
			# EXTERNAL ACCESS NOTE: Emit to EventBus for the visual tween
			EventBus.unit_moved.emit(unit, current_coord, next_step)
			print("COMBAT LOG: %s ascends the stairs to Z-Level %d!" % [unit.name, next_step.z])
			return
			
		# 2. Request A* Pathfinding
		# EXTERNAL ACCESS NOTE: Querying the MapManager's Pathfinder API
		var path: Array[Vector3i] = move_comp.map_manager.request_path(current_coord, nearest_stairs)
		
		# A valid path array usually contains the start node at index 0 and the next step at index 1
		if path.size() > 1:
			var next_step: Vector3i = path[1]
			
			move_comp.update_position(next_step)
			EventBus.unit_moved.emit(unit, current_coord, next_step)
			print("COMBAT LOG: %s moves towards stairs (Current: %s)" % [unit.name, next_step])
		else:
			print("COMBAT LOG: %s is blocked and cannot find a valid path to the stairs!" % unit.name)
			
	else:
		print("COMBAT LOG: %s found no stairs." % unit.name)

func _find_nearest_stairs(origin: Vector3i, map_manager: MapManager) -> Vector3i:
	var closest_coord: Vector3i = Vector3i(-1, -1, -1)
	var closest_dist: float = 99999.0
	
	var map_data: MapData = map_manager.current_map_data
	if not map_data: return closest_coord
		
	for coord: Vector3i in map_data.grid_tiles.keys():
		var tile: TacticalTileData = map_data.grid_tiles[coord]
		# Only look for stairs on the same Z-level to prevent confusion
		if tile and tile.is_stairs and coord.z == origin.z:
			var dist: float = _calculate_3d_distance(origin, coord)
			if dist < closest_dist:
				closest_dist = dist
				closest_coord = coord
				
	return closest_coord

func _calculate_3d_distance(a: Vector3i, b: Vector3i) -> float:
	var dx: float = float(a.x - b.x)
	var dy: float = float(a.y - b.y)
	var dz: float = float(a.z - b.z)
	return sqrt((dx * dx) + (dy * dy) + (dz * dz))
