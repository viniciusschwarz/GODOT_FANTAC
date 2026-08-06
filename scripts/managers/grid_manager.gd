extends Node
## Handles spatial calculations for a 2D battlefield with multi-floor structures (Z-levels).

## Scale multiplier for height differences when calculating effective distance.
const FLOOR_HEIGHT_SCALE: float = 2.0
const TILE_SIZE: float = 64.0

var astar: AStar2D
var grid_size: Vector2i = Vector2i(32, 32)
var tile_data: Dictionary = {} # Vector2i -> { "z_height": int, "move_penalty": float, "static_los_block": bool, "cover_bonus": float, "los_block_height": int, "id": int }

var _next_point_id: int = 0

func initialize_grid(size: Vector2i) -> void:
	grid_size = size
	astar = AStar2D.new()
	tile_data.clear()
	_next_point_id = 0

func set_tile_data(grid_pos: Vector2i, z_height: int, move_penalty: float, static_los_block: bool) -> void:
	if not tile_data.has(grid_pos):
		var id: int = _next_point_id
		_next_point_id += 1
		tile_data[grid_pos] = {
			"z_height": 0,
			"move_penalty": 1.0,
			"static_los_block": false,
			"cover_bonus": 0.0,
			"los_block_height": 0,
			"id": id,
			"solid": false
		}
		var world_pos: Vector2 = get_world_position(grid_pos)
		astar.add_point(id, world_pos, 1.0)

	tile_data[grid_pos]["z_height"] = z_height
	tile_data[grid_pos]["move_penalty"] = move_penalty
	tile_data[grid_pos]["static_los_block"] = static_los_block

	astar.set_point_weight_scale(tile_data[grid_pos]["id"], move_penalty)

func _connect_grid_neighbors() -> void:
	# Connect all adjacent tiles, respecting Z-level constraints (max difference of 1)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos: Vector2i = Vector2i(x, y)
			if not tile_data.has(pos) or tile_data[pos]["solid"]:
				continue

			var id: int = tile_data[pos]["id"]
			var z: int = tile_data[pos]["z_height"]

			# Check right and down to avoid double connections
			var neighbors: Array[Vector2i] = [Vector2i(x + 1, y), Vector2i(x, y + 1)]
			for n in neighbors:
				if tile_data.has(n) and not tile_data[n]["solid"]:
					var n_id: int = tile_data[n]["id"]
					var n_z: int = tile_data[n]["z_height"]

					# Only connect if height difference is <= 1
					if abs(z - n_z) <= 1:
						astar.connect_points(id, n_id, true)

func add_map_object(grid_pos: Vector2i, object_data: MapObjectData) -> void:
	if not tile_data.has(grid_pos):
		return

	if object_data.blocks_pathing:
		tile_data[grid_pos]["solid"] = true
		astar.set_point_disabled(tile_data[grid_pos]["id"], true)

	tile_data[grid_pos]["move_penalty"] *= object_data.movement_cost
	astar.set_point_weight_scale(tile_data[grid_pos]["id"], tile_data[grid_pos]["move_penalty"])

	if object_data.cover_bonus > tile_data[grid_pos]["cover_bonus"]:
		tile_data[grid_pos]["cover_bonus"] = object_data.cover_bonus

	if object_data.los_block_height > tile_data[grid_pos]["los_block_height"]:
		tile_data[grid_pos]["los_block_height"] = object_data.los_block_height

func finalize_grid() -> void:
	_connect_grid_neighbors()

func get_tile_data(grid_pos: Vector2i) -> Dictionary:
	if tile_data.has(grid_pos):
		return tile_data[grid_pos]
	return { "z_height": 0, "move_penalty": 1.0, "static_los_block": false, "cover_bonus": 0.0, "los_block_height": 0, "id": -1, "solid": false }

func get_grid_position2d(world_pos: Vector2) -> Vector2i:
	var grid_x: float = floor(world_pos.x / TILE_SIZE)
	var grid_y: float = floor(world_pos.y / TILE_SIZE)
	return Vector2i(grid_x, grid_y)

func get_grid_position(world_pos: Vector2, elevation: int = 0) -> Vector3i:
	var grid_pos: Vector2i = get_grid_position2d(world_pos)
	var z = elevation
	if tile_data.has(grid_pos):
		z = tile_data[grid_pos]["z_height"]
	return Vector3i(grid_pos.x, grid_pos.y, z)

func get_world_position(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2, grid_pos.y * TILE_SIZE + TILE_SIZE/2)

func get_effective_distance(pos_a: Vector3i, pos_b: Vector3i) -> float:
	var delta_x: int = pos_b.x - pos_a.x
	var delta_y: int = pos_b.y - pos_a.y
	var delta_z: int = pos_b.z - pos_a.z
	var effective_z: float = delta_z * FLOOR_HEIGHT_SCALE
	return sqrt((delta_x * delta_x) + (delta_y * delta_y) + (effective_z * effective_z))

## Returns a path (array of `Vector2i`) between two grid positions using A*.
func get_grid_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not astar or not tile_data.has(start) or not tile_data.has(end):
		return []

	var start_id: int = tile_data[start]["id"]
	var end_id: int = tile_data[end]["id"]

	var point_path: PackedInt64Array = astar.get_id_path(start_id, end_id)
	var grid_path: Array[Vector2i] = []

	for id in point_path:
		# Find the grid_pos for this ID
		for pos in tile_data:
			if tile_data[pos]["id"] == id:
				grid_path.append(pos)
				break

	return grid_path

func check_line_of_sight(pos_a: Vector3i, pos_b: Vector3i) -> bool:
	var x0: int = pos_a.x
	var y0: int = pos_a.y
	var x1: int = pos_b.x
	var y1: int = pos_b.y

	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy

	while true:
		if x0 == x1 and y0 == y1:
			break

		if not (x0 == pos_a.x and y0 == pos_a.y):
			var check_pos: Vector2i = Vector2i(x0, y0)
			if tile_data.has(check_pos):
				var data: Dictionary = tile_data[check_pos]

				if data["static_los_block"]:
					return false

				var max_sight_height: int = max(pos_a.z, pos_b.z)
				if data["z_height"] + data["los_block_height"] > max_sight_height:
					return false

		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return true
