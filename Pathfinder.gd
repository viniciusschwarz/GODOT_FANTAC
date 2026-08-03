extends Node

# AStarGrid2D is Godot's built-in tool for 2D grid pathfinding
var astar = AStarGrid2D.new()

# ==========================================
# 1. INITIALIZATION
# ==========================================
# This is called by the GameHub when the board is created
func setup_grid(board_size: Vector2):
	# Define the size of the grid (starting from 0,0)
	astar.region = Rect2i(0, 0, int(board_size.x), int(board_size.y))
	
	# We use 1x1 cells logically (not 64x64 pixels) because our GameHub uses grid coordinates!
	astar.cell_size = Vector2(1, 1)
	
	# In tactical games, we only want Up, Down, Left, Right movement
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	# Apply the configuration
	astar.update()
	print("Pathfinder: Grid configured with size ", board_size)

# ==========================================
# 2. PATH CALCULATION
# ==========================================
func get_next_step(start_pos: Vector2, target_pos: Vector2) -> Vector2:
	# 1. Refresh the obstacles before calculating!
	_update_obstacles(start_pos, target_pos)
	
	# 2. Convert Vector2 to Vector2i (Integers) because AStarGrid2D requires whole numbers
	var start_i = Vector2i(int(start_pos.x), int(start_pos.y))
	var target_i = Vector2i(int(target_pos.x), int(target_pos.y))
	
	# 3. Ask Godot to calculate the path
	var path = astar.get_id_path(start_i, target_i)
	
	# 4. Analyze the result
	# path[0] is the tile we are currently standing on.
	# path[1] is the very next step we need to take.
	if path.size() > 1:
		return Vector2(path[1].x, path[1].y)
		
	# If no path is found, return the start position (don't move)
	return start_pos

# ==========================================
# 3. INTERNAL HELPERS
# ==========================================
func _update_obstacles(start_pos: Vector2, target_pos: Vector2):
	# Loop through every single tile on the board
	for x in range(astar.region.size.x):
		for y in range(astar.region.size.y):
			var cell = Vector2(x, y)
			var is_solid = false
			
			# Check with our GameHub: Is there a mountain here?
			if GameHub.unwalkable_cells.has(cell):
				is_solid = true
				
			# Check with our GameHub: Is there a unit blocking the way?
			# IMPORTANT: We do NOT mark our target as solid, otherwise we could never walk up to them!
			# We also do NOT mark our own starting position as solid.
			elif GameHub.grid_positions.has(cell) and cell != target_pos and cell != start_pos:
				is_solid = true
				
			# Tell the AStar grid if this specific tile is blocked
			astar.set_point_solid(Vector2i(int(x), int(y)), is_solid)
