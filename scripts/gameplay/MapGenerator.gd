extends Node

func generate_map(board_size: Vector2, map_type: String = "Standard") -> Dictionary:
	if map_type == "Village":
		return _generate_village_map(board_size)
	else:
		return _generate_standard_map(board_size)

func _generate_standard_map(board_size: Vector2) -> Dictionary:
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

func _generate_village_map(board_size: Vector2) -> Dictionary:
	var terrain_map = {}

	# Default all to Grass
	for x in range(board_size.x):
		for y in range(board_size.y):
			terrain_map[Vector2(x, y)] = "Grass"

	# Generate a central street cross
	var mid_x = int(board_size.x / 2)
	var mid_y = int(board_size.y / 2)

	for x in range(board_size.x):
		terrain_map[Vector2(x, mid_y)] = "Street"
		if randf() > 0.8:
			terrain_map[Vector2(x, mid_y-1)] = "Street"
		if randf() > 0.8:
			terrain_map[Vector2(x, mid_y+1)] = "Street"

	for y in range(board_size.y):
		terrain_map[Vector2(mid_x, y)] = "Street"
		if randf() > 0.8:
			terrain_map[Vector2(mid_x-1, y)] = "Street"
		if randf() > 0.8:
			terrain_map[Vector2(mid_x+1, y)] = "Street"

	# Generate random houses
	var num_houses = int((board_size.x * board_size.y) / 40)
	for i in range(num_houses):
		var hx = randi() % int(board_size.x - 4) + 2
		var hy = randi() % int(board_size.y - 4) + 2

		# Place 3x3 house walls
		for x in range(hx-1, hx+2):
			for y in range(hy-1, hy+2):
				if terrain_map.has(Vector2(x, y)):
					terrain_map[Vector2(x, y)] = "Wall"

		# Punch a door randomly on one side
		var door_side = randi() % 4
		if door_side == 0:
			terrain_map[Vector2(hx, hy-1)] = "Door"
		elif door_side == 1:
			terrain_map[Vector2(hx, hy+1)] = "Door"
		elif door_side == 2:
			terrain_map[Vector2(hx-1, hy)] = "Door"
		else:
			terrain_map[Vector2(hx+1, hy)] = "Door"

		# Inside house is grass (floor)
		terrain_map[Vector2(hx, hy)] = "Grass"

	# Scatter trees and fences
	for x in range(board_size.x):
		for y in range(board_size.y):
			var pos = Vector2(x, y)
			if terrain_map[pos] == "Grass":
				var roll = randf()
				if roll < 0.05:
					terrain_map[pos] = "Tree"
				elif roll < 0.10:
					terrain_map[pos] = "Fence"

	return terrain_map
