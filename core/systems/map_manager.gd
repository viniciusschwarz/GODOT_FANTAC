class_name MapManager extends Node

## The API layer for the tactical board.
## Units and UI will query this manager for paths, LoS, and valid targets.

@export var current_map_data: MapData

var _pathfinder: GridAStar3D

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Will eventually listen to EventBus for map loading events
	_pathfinder = GridAStar3D.new()
	if current_map_data:
		initialize_map(current_map_data)

## Dependency Injection: Loads a new map into the simulation.
func initialize_map(map_data: MapData) -> void:
	current_map_data = map_data
	_pathfinder.build_graph(current_map_data)
	print("MapManager: Initialized grid with %d tiles." % current_map_data.grid_tiles.size())

## Requests a path from the AStar3D system.
func request_path(start: Vector3i, end: Vector3i) -> Array[Vector3i]:
	return _pathfinder.get_path_coords(start, end)

## Calculates if a 3D line exists between two points without hitting a blocking tile.
## Uses a basic 3D Bresenham algorithm adaptation.
func is_line_of_sight_clear(start: Vector3i, target: Vector3i) -> bool:
	var current: Vector3i = start
	var diff: Vector3i = target - start
	var steps: int = maxi(maxi(abs(diff.x), abs(diff.y)), abs(diff.z))

	if steps == 0:
		return true

	var x_inc: float = diff.x / float(steps)
	var y_inc: float = diff.y / float(steps)
	var z_inc: float = diff.z / float(steps)

	var exact_pos: Vector3 = Vector3(start.x, start.y, start.z)

	for i: int in range(1, steps):
		exact_pos.x += x_inc
		exact_pos.y += y_inc
		exact_pos.z += z_inc

		var check_coord: Vector3i = Vector3i(roundi(exact_pos.x), roundi(exact_pos.y), roundi(exact_pos.z))
		var tile: TacticalTileData = current_map_data.get_tile(check_coord)

		# If the line passes through a solid blocking tile, LoS is broken
		if tile and tile.blocks_vision:
			return false

	return true

func get_tile_data(coord: Vector3i) -> TacticalTileData:	
	return current_map_data.grid_tiles.get(coord, null)
