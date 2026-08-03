extends Node2D

@export var tile_size: Vector2 = Vector2(64, 64) 
@export var board_size: Vector2 = Vector2(8, 8)  

enum TerrainType {
	GRASS,   
	MOUNTAIN, 
	WATER     
}

var terrain_map = {}

func _ready():
	generate_basic_board()
	print("Board initialized with size: ", board_size)
	# NEW: Register the size with the Hub!
	GameHub.register_board_size(board_size)

func generate_basic_board():
	for x in range(board_size.x):
		for y in range(board_size.y):
			var grid_pos = Vector2(x, y)
			
			# By default, everything is grass
			terrain_map[grid_pos] = TerrainType.GRASS
			
			# Let's create a small wall of mountains in the middle
			if x == 4 and (y == 3 or y == 4 or y == 5):
				terrain_map[grid_pos] = TerrainType.MOUNTAIN
				# NEW: Tell the Hub that this tile blocks movement!
				GameHub.register_unwalkable_cell(grid_pos)
	
	# NEW: This tells Godot to run the _draw() function to paint the board
	queue_redraw()

# ==========================================
# NEW: VISUALIZING THE BOARD
# ==========================================
# This built-in function runs when queue_redraw() is called.
func _draw():
	for grid_pos in terrain_map:
		# Calculate where to draw the square
		var pixel_pos = grid_pos * tile_size
		var rect = Rect2(pixel_pos, tile_size)
		
		# Pick a color based on the terrain type
		if terrain_map[grid_pos] == TerrainType.MOUNTAIN:
			draw_rect(rect, Color(0.3, 0.3, 0.3)) # Dark Gray
		else:
			draw_rect(rect, Color(0.2, 0.4, 0.2)) # Dark Green
			
		# Draw a thin black border around every tile so it looks like a grid
		draw_rect(rect, Color(0, 0, 0, 0.5), false, 2.0)

# ==========================================
# HELPER FUNCTIONS 
# ==========================================
func grid_to_pixel(grid_position: Vector2) -> Vector2:
	var pixel_x = grid_position.x * tile_size.x
	var pixel_y = grid_position.y * tile_size.y
	var center_offset = tile_size / 2 
	return Vector2(pixel_x, pixel_y) + center_offset

func pixel_to_grid(pixel_position: Vector2) -> Vector2:
	var grid_x = floor(pixel_position.x / tile_size.x)
	var grid_y = floor(pixel_position.y / tile_size.y)
	return Vector2(grid_x, grid_y)

# Checks if a specific coordinate is actually inside our board limits.
func is_within_bounds(grid_position: Vector2) -> bool:
	var is_x_valid = grid_position.x >= 0 and grid_position.x < board_size.x
	var is_y_valid = grid_position.y >= 0 and grid_position.y < board_size.y
	return is_x_valid and is_y_valid	
