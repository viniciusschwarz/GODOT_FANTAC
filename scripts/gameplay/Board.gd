extends Node2D

@export var tile_size: Vector2 = Vector2(64, 64) 
@export var board_size: Vector2 = Vector2(8, 8)  

var terrain_map = {}

func _ready():
	pass # Initialization moved to generate_new_board

func generate_new_board(new_size: Vector2, map_type: String = "Standard"):
	board_size = new_size
	GameHub.clear_board_state()
	terrain_map = MapGenerator.generate_map(board_size, map_type)
	GameHub.register_board_size(board_size)

	for grid_pos in terrain_map:
		GameHub.register_terrain_cell(grid_pos, terrain_map[grid_pos])
	
	# NEW: This tells Godot to run the _draw() function to paint the board
	queue_redraw()
	_spawn_lights_and_occluders()

# ==========================================
# NEW: VISUALIZING THE BOARD
# ==========================================
# This built-in function runs when queue_redraw() is called.
func _draw():
	for grid_pos in terrain_map:
		# Calculate where to draw the square
		var pixel_pos = grid_pos * tile_size
		var rect = Rect2(pixel_pos, tile_size)
		
		var terrain_key = terrain_map[grid_pos]
		var terrain_stats = TerrainDatabase.get_terrain_stats(terrain_key)

		var hex_color = "336633" # Default grass green
		if terrain_stats.has("color"):
			hex_color = terrain_stats["color"]

		draw_rect(rect, Color(hex_color))
			
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

func _spawn_lights_and_occluders():
	# Clean up old light and occluder nodes
	for child in get_children():
		if child is PointLight2D or child is LightOccluder2D:
			child.queue_free()

	for grid_pos in terrain_map:
		var terrain_key = terrain_map[grid_pos]
		var pixel_pos = grid_to_pixel(grid_pos)

		# Add occluders for high obstacles like Walls, Mountains, Trees
		if terrain_key in ["Wall", "Mountain", "Tree"]:
			var occluder = LightOccluder2D.new()
			var poly = OccluderPolygon2D.new()

			# Create a square polygon matching the tile size
			var half_w = tile_size.x / 2.0
			var half_h = tile_size.y / 2.0
			poly.polygon = PackedVector2Array([
				Vector2(-half_w, -half_h),
				Vector2(half_w, -half_h),
				Vector2(half_w, half_h),
				Vector2(-half_w, half_h)
			])

			occluder.occluder = poly
			occluder.position = pixel_pos
			add_child(occluder)

		# Add lights on certain objects like Doors (lanterns) or specific Street lamps (randomized)
		if terrain_key == "Door" or (terrain_key == "Street" and randf() < 0.1):
			var light = PointLight2D.new()

			# Use a placeholder texture for the light gradient (we can use the built-in radial gradient or an image)
			# Since we don't have an explicit light texture, we will create a gradient texture dynamically
			var gradient = Gradient.new()
			gradient.add_point(0.0, Color(1, 0.9, 0.5, 1.0)) # Warm yellow center
			gradient.add_point(1.0, Color(1, 0.9, 0.5, 0.0)) # Fade out

			var grad_tex = GradientTexture2D.new()
			grad_tex.gradient = gradient
			grad_tex.fill = GradientTexture2D.FILL_RADIAL
			grad_tex.fill_from = Vector2(0.5, 0.5)
			grad_tex.fill_to = Vector2(1.0, 0.5)
			grad_tex.width = int(tile_size.x * 4) # Spread light across 4 tiles
			grad_tex.height = int(tile_size.y * 4)

			light.texture = grad_tex
			light.position = pixel_pos
			light.shadow_enabled = true
			light.energy = 1.5
			add_child(light)
