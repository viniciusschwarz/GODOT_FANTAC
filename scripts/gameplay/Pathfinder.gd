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
func get_walkable_path(start_pos: Vector2, target_pos: Vector2, max_steps: int) -> Array[Vector2]:
	_update_obstacles(start_pos, target_pos)
	
	# FIXED: We now use round() before converting to integers to perfectly match the GameHub!
	var start_i = Vector2i(round(start_pos.x), round(start_pos.y))
	var target_i = Vector2i(round(target_pos.x), round(target_pos.y))
	
	var id_path = astar.get_id_path(start_i, target_i)
	var final_path: Array[Vector2] = []
	
	if id_path.size() > 1:
		for i in range(1, min(id_path.size(), max_steps + 1)):
			var step = Vector2(id_path[i].x, id_path[i].y)
			
			if not GameHub.is_cell_empty(step):
				break
				
			final_path.append(step)
			
	return final_path

# ==========================================
# 3. INTERNAL HELPERS
# ==========================================
func _update_obstacles(start_pos: Vector2, target_pos: Vector2):
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
			elif GameHub.grid_positions.has(cell) and cell != safe_target and cell != safe_start:
				is_solid = true
				
			var cell_i = Vector2i(int(x), int(y))
			astar.set_point_solid(cell_i, is_solid)
			astar.set_point_weight_scale(cell_i, weight_scale)