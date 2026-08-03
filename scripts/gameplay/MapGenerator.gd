extends Node

func generate_map(board_size: Vector2) -> Dictionary:
	var terrain_map = {}

	# Simple procedural generation
	# e.g., 70% grass, 20% water, 10% mountain
	for x in range(board_size.x):
		for y in range(board_size.y):
			var grid_pos = Vector2(x, y)
			var roll = randf()

			if roll < 0.7:
				terrain_map[grid_pos] = "Grass"
			elif roll < 0.9:
				terrain_map[grid_pos] = "Water"
			else:
				terrain_map[grid_pos] = "Mountain"

	return terrain_map
