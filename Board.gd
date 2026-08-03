extends Node2D
# We extend Node2D because the Board exists in the 2D game world and has a position.

# ==========================================
# 1. GRID CONFIGURATION
# ==========================================
# 'export' allows us to change these values directly in the Godot Inspector panel
# without having to open the code every time.
@export var tile_size: Vector2 = Vector2(64, 64) # Each tile is 64x64 pixels
@export var board_size: Vector2 = Vector2(8, 8)  # The board is 8 tiles wide and 8 tiles high

# ==========================================
# 2. TERRAIN DATA
# ==========================================
# We use an Enum to define our terrain types clearly.
enum TerrainType {
	GRASS,    # Normal movement
	MOUNTAIN, # Blocks movement or slows it down
	WATER     # Unpassable
}

# A Dictionary to store the terrain type for specific grid coordinates.
# Key: Vector2 (Grid coordinates like 0,0)
# Value: TerrainType (e.g., TerrainType.GRASS)
var terrain_map = {}

# ==========================================
# 3. INITIALIZATION
# ==========================================
func _ready():
	# _ready() is a built-in Godot function that runs once when the node enters the game.
	generate_basic_board()
	print("Board initialized with size: ", board_size)

# A simple function to fill our board with grass, just so we have a starting point.
func generate_basic_board():
	# We use a nested loop to go through every X and Y coordinate on our board.
	for x in range(board_size.x):
		for y in range(board_size.y):
			var grid_pos = Vector2(x, y)
			# By default, we make everything grass
			terrain_map[grid_pos] = TerrainType.GRASS
			
			# Let's add a small mountain in the middle for testing later
			if x == 4 and y == 4:
				terrain_map[grid_pos] = TerrainType.MOUNTAIN

# ==========================================
# 4. HELPER FUNCTIONS (The Translators)
# ==========================================

# Converts a grid coordinate (like 2, 3) into a screen pixel position (like 128, 192).
# We use this to tell the 2D sprites where to draw themselves on the screen.
func grid_to_pixel(grid_position: Vector2) -> Vector2:
	var pixel_x = grid_position.x * tile_size.x
	var pixel_y = grid_position.y * tile_size.y
	
	# We add half a tile size to center the unit perfectly in the middle of the tile!
	var center_offset = tile_size / 2 
	
	return Vector2(pixel_x, pixel_y) + center_offset

# Converts a screen pixel position (like a mouse click) back into a grid coordinate.
func pixel_to_grid(pixel_position: Vector2) -> Vector2:
	# 'floor()' rounds down to the nearest whole number. 
	# If we click pixel 70, and tiles are 64, 70/64 = 1.09. Floor makes it 1.
	var grid_x = floor(pixel_position.x / tile_size.x)
	var grid_y = floor(pixel_position.y / tile_size.y)
	
	return Vector2(grid_x, grid_y)

# Checks if a specific coordinate is actually inside our board limits.
func is_within_bounds(grid_position: Vector2) -> bool:
	var is_x_valid = grid_position.x >= 0 and grid_position.x < board_size.x
	var is_y_valid = grid_position.y >= 0 and grid_position.y < board_size.y
	return is_x_valid and is_y_valid

# Returns the terrain type of a tile. We can use this later to see if a unit can walk here.
func get_terrain_at(grid_position: Vector2):
	if terrain_map.has(grid_position):
		return terrain_map[grid_position]
	return null # Returns null if the tile doesn't exist
