with open("scripts/sim/pathfinding_engine.gd", "r") as f:
    content = f.read()

# Replace Occupied Tile Penalty
old_penalty = """			# Static Occupied Tile Penalty
			if neighbor_tile.occupying_unit_id != -1 and neighbor_tile.occupying_unit_id != unit_data.unit_id:
				continue"""

new_penalty = """			# Static Occupied Tile Penalty
			# If the target is an enemy for melee, it will be occupied. Allow pathing to the target itself.
			# We will strip the final occupied node in _reconstruct_path.
			# A* naturally doesn't block on the start node because it doesn't get evaluated as a neighbor of itself.
			if neighbor_tile.occupying_unit_id != -1 and neighbor_tile.occupying_unit_id != unit_data.unit_id:
				if neighbor != target:
					continue"""

content = content.replace(old_penalty, new_penalty)

old_reconstruct = """func _reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	if path.size() > 1:
		path.pop_front() # Remove start node
	elif path.size() == 1:
		path.clear()
	return path"""

new_reconstruct = """func _reconstruct_path(came_from: Dictionary, current: Vector3i, matrix: BattlefieldMatrix) -> Array[Vector3i]:
	var path: Array[Vector3i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)

	if path.size() > 1:
		path.pop_front() # Remove start node

		# If the final destination is occupied, it means we pathfound directly TO an enemy (melee adjacency).
		# Strip the final node so the unit stops adjacent to the target.
		if path.size() > 0:
			var final_node = path[path.size() - 1]
			var final_tile = matrix.get_tile(final_node)
			if final_tile and final_tile.occupying_unit_id != -1:
				path.pop_back()

	elif path.size() == 1:
		path.clear()

	return path"""

content = content.replace(old_reconstruct, new_reconstruct)

# Also replace the call to _reconstruct_path
content = content.replace("return _reconstruct_path(came_from, current)", "return _reconstruct_path(came_from, current, matrix)")

with open("scripts/sim/pathfinding_engine.gd", "w") as f:
    f.write(content)
