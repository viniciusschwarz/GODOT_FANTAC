extends Node

# AStarGrid2D is Godot's built-in tool for 2D grid pathfinding
var astar = AStarGrid2D.new()

# ==========================================
# 1. INITIALIZATION
# ==========================================
func setup_grid(board_size: Vector2):
	astar.region = Rect2i(0, 0, int(board_size.x), int(board_size.y))
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	print("Pathfinder: Grid configured with size ", board_size)

# ==========================================
# 2. PATH CALCULATION
# ==========================================
func get_walkable_path(start_pos: Vector2, target_pos: Vector2, max_steps: int, attack_range: int = 1) -> Array[Vector2]:
	_update_obstacles(start_pos, target_pos, false)
	
	# FIXED: We now use round() before converting to integers to perfectly match the GameHub!
	var start_i = Vector2i(round(start_pos.x), round(start_pos.y))
	var target_i = Vector2i(round(target_pos.x), round(target_pos.y))
	
	# Check if target is solid (blocked by something other than a unit).
	# If target is solid, get_id_path might return empty.
	# But in our game, targets are usually units, which we marked as non-solid in _update_obstacles.
	var id_path = astar.get_id_path(start_i, target_i)
	var final_path: Array[Vector2] = []
	
	# If no path, try finding a path to a neighboring tile of the target
	if id_path.is_empty() and start_i != target_i:
		var best_neighbor = _find_closest_walkable_neighbor(target_i, start_i, attack_range)
		if best_neighbor != target_i:
			id_path = astar.get_id_path(start_i, best_neighbor)

	# If STILL empty, it means the path is completely blocked by units (since terrain wouldn't change).
	# We temporarily ignore units to find a path that moves towards the target as much as possible.
	if id_path.is_empty() and start_i != target_i:
		_update_obstacles(start_pos, target_pos, true)
		id_path = astar.get_id_path(start_i, target_i)
		_update_obstacles(start_pos, target_pos, false) # Restore for future calls

	if id_path.size() > 1:
		for i in range(1, min(id_path.size(), max_steps + 1)):
			var step = Vector2(id_path[i].x, id_path[i].y)
			
			# Stop if the step is occupied (and it's not the target tile)
			if not GameHub.is_cell_empty(step) and step != target_pos:
				break
				
			# Only break for target tile if our intent was to attack it. If we are pathing to an empty tile (kiting), it's fine.
			# We can check if GameHub.is_cell_empty(target_pos) to know if we are kiting vs attacking.
			if step == target_pos and not GameHub.is_cell_empty(target_pos):
				break

			final_path.append(step)
			
			# Stop prematurely if this step is within attack range of the target,
			# BUT only if we are actually attacking (target is occupied). If kiting, we want to go exactly to the target tile.
			if not GameHub.is_cell_empty(target_pos) and _get_grid_distance(step, target_pos) <= attack_range:
				break

	return final_path

func _find_closest_walkable_neighbor(target_i: Vector2i, start_i: Vector2i, attack_range: int) -> Vector2i:
	var best_neighbor = target_i
	var shortest_dist = 999999

	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			var dist = max(abs(x), abs(y))
			if dist > attack_range or dist == 0:
				continue
			var neighbor = target_i + Vector2i(x, y)
			if not astar.is_in_bounds(neighbor.x, neighbor.y) or astar.is_point_solid(neighbor):
				continue

			# Check if there is actually a path to this neighbor
			var path_to_neighbor = astar.get_id_path(start_i, neighbor)
			if not path_to_neighbor.is_empty():
				# We want a neighbor that is reachable and closest to start (or shortest path)
				if path_to_neighbor.size() < shortest_dist:
					shortest_dist = path_to_neighbor.size()
					best_neighbor = neighbor

	return best_neighbor

func _get_grid_distance(pos1: Vector2, pos2: Vector2) -> int:
	var dist_x = abs(pos1.x - pos2.x)
	var dist_y = abs(pos1.y - pos2.y)
	return int(max(dist_x, dist_y))

# ==========================================
# 3. INTERNAL HELPERS
# ==========================================
func _update_obstacles(start_pos: Vector2, target_pos: Vector2, ignore_units: bool = false):
	# FIXED: Create safe, rounded references for our mathematical comparisons
	var safe_start = start_pos.round()
	var safe_target = target_pos.round()

	for x in range(astar.region.size.x):
		for y in range(astar.region.size.y):
			var cell = Vector2(x, y)
			var is_solid = false
			var weight_scale = 1.0
			
			if GameHub.terrain_cells.has(cell):
				var terrain_key = GameHub.terrain_cells[cell]
				var terrain_stats = TerrainDatabase.get_terrain_stats(terrain_key)
				if not terrain_stats.get("walkable", true):
					is_solid = true
				else:
					weight_scale = terrain_stats.get("cost", 1.0)
				
			# FIXED: We now compare against the safe_target and safe_start!
			elif not ignore_units and GameHub.grid_positions.has(cell) and cell != safe_target and cell != safe_start:
				is_solid = true
				
			var cell_i = Vector2i(int(x), int(y))
			astar.set_point_solid(cell_i, is_solid)
			astar.set_point_weight_scale(cell_i, weight_scale)