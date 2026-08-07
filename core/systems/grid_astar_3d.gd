class_name GridAStar3D extends RefCounted

## Handles all 3D pathfinding mathematics.
## Wrapper for Godot's AStar3D, decoupled from any visual Nodes.

var _astar: AStar3D = AStar3D.new()
# Maps a Vector3i to an integer ID required by AStar3D
var _point_ids: Dictionary = {}
var _next_id: int = 0

## Initializes the pathfinding grid based on the injected MapData.
## @param map_data: The resource containing all tile rules.
func build_graph(map_data: MapData) -> void:
	_astar.clear()
	_point_ids.clear()
	_next_id = 0

	# 1. Add all walkable points
	for coord: Vector3i in map_data.grid_tiles.keys():
		var tile: TacticalTileData = map_data.get_tile(coord)
		if tile and tile.is_walkable:
			_point_ids[coord] = _next_id
			_astar.add_point(_next_id, Vector3(coord.x, coord.y, coord.z), tile.movement_cost)
			_next_id += 1

	# 2. Connect points (Orthogonal 2D + Vertical stairs)
	for coord: Vector3i in _point_ids.keys():
		_connect_adjacent(coord, map_data)

func _connect_adjacent(coord: Vector3i, map_data: MapData) -> void:
	var current_id: int = _point_ids[coord]
	var tile: TacticalTileData = map_data.get_tile(coord)

	# Standard 2D Orthogonal connections
	var directions: Array[Vector3i] = [
		Vector3i.RIGHT, Vector3i.LEFT, Vector3i.DOWN, Vector3i.UP
	]

	for dir: Vector3i in directions:
		var neighbor_coord: Vector3i = coord + dir
		if _point_ids.has(neighbor_coord):
			_astar.connect_points(current_id, _point_ids[neighbor_coord], false)

	# Handle vertical stair connections
	if tile.is_stairs:
		# Define stair logic (e.g., stairs connect to the tile directly "above" and "forward")
		# For this implementation, we simply check the tile directly above (z+1)
		var up_coord: Vector3i = coord + Vector3i(0, 0, 1)
		if _point_ids.has(up_coord):
			_astar.connect_points(current_id, _point_ids[up_coord], true)

## Calculates a path between two coordinates.
## @return Array[Vector3i]: An array of coordinates forming the path.
func get_path_coords(start: Vector3i, end: Vector3i) -> Array[Vector3i]:
	if not _point_ids.has(start) or not _point_ids.has(end):
		return []

	var path_3d: PackedVector3Array = _astar.get_point_path(_point_ids[start], _point_ids[end])
	var path_coords: Array[Vector3i] = []

	for vec: Vector3 in path_3d:
		path_coords.append(Vector3i(roundi(vec.x), roundi(vec.y), roundi(vec.z)))

	return path_coords
