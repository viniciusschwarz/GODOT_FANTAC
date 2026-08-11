class_name PathfindingEngine extends RefCounted

func calculate_path(matrix: BattlefieldMatrix, start: Vector3i, target: Vector3i, unit_data: UnitDataResource) -> Dictionary:
	if start == target:
		return {"path": [] as Array[Vector3i], "reason": "Target equals start"}

	# Pre-Flight Target Checks
	var target_tile = matrix.get_tile(target)
	if target_tile:
		if target_tile.base_traversal_cost >= INF or target_tile.prop_id != -1:
			var prop_msg = "Target tile blocked by structure"
			if target_tile.prop_id != -1:
				prop_msg = "Path blocked by terrain/prop " + str(target_tile.prop_id)
			return {"path": [] as Array[Vector3i], "reason": prop_msg}
	else:
		return {"path": [] as Array[Vector3i], "reason": "Target tile is out of bounds"}

	# Ensure the start tile's occupancy is explicitly bypassed.
	# A* naturally ignores the origin passability check, but we verify here for safety
	# against any potential self-blocking bugs.
	var start_tile = matrix.get_tile(start)
	if start_tile and start_tile.occupying_unit_id != -1 and start_tile.occupying_unit_id != unit_data.unit_id:
		# If the start tile is occupied by SOMEONE ELSE, technically we shouldn't be here,
		# but if it's occupied by US, we proceed.
		pass


	# A* Implementation restricted to 4-directional cardinal steps (N, S, E, W)
	var open_set: Array[Vector3i] = [start]
	var came_from: Dictionary = {}

	# g_score: actual cost from start to node
	var g_score: Dictionary = {}
	g_score[start] = 0.0

	# f_score: g_score + heuristic (Manhattan distance)
	var f_score: Dictionary = {}
	f_score[start] = _heuristic(start, target)

	while open_set.size() > 0:
		# Get node in open_set with lowest f_score
		var current: Vector3i = open_set[0]
		var current_index: int = 0
		var min_f: float = f_score.get(current, INF)

		for i in range(1, open_set.size()):
			var node = open_set[i]
			var f = f_score.get(node, INF)
			if f < min_f:
				min_f = f
				current = node
				current_index = i

		if current == target:
			return {"path": _reconstruct_path(came_from, current, matrix), "reason": ""}

		open_set.remove_at(current_index)

		var valid_neighbors = _get_valid_neighbors(matrix, current, unit_data.unit_id, target)
		for neighbor in valid_neighbors:
			var neighbor_tile = matrix.get_tile(neighbor)

			# Calculate cost
			var cost: float = neighbor_tile.base_traversal_cost # Normal: 1.0, Rubble: 2.0

			# Staircase cost applies if transitioning Z
			if current.z != neighbor.z:
				cost = 1.5

			var tentative_g_score = g_score.get(current, INF) + cost

			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, target)

				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# Path calculation failed
	unit_data.recalculation_cooldown_ticks = 5
	return {"path": [] as Array[Vector3i], "reason": "No valid traversal/Z-connector found to target"}

func _get_valid_neighbors(matrix: BattlefieldMatrix, current: Vector3i, unit_id: int, target: Vector3i) -> Array[Vector3i]:
	var valid_neighbors: Array[Vector3i] = []
	var directions: Array[Vector3i] = [
		Vector3i(0, -1, 0), # N
		Vector3i(0, 1, 0),  # S
		Vector3i(1, 0, 0),  # E
		Vector3i(-1, 0, 0)  # W
	]

	for dir in directions:
		for dz in [-1, 0, 1]:
			var neighbor = current + dir + Vector3i(0, 0, dz)

			# Check passability using the matrix
			if not matrix.is_cardinal_passable(current, neighbor):
				continue

			var neighbor_tile = matrix.get_tile(neighbor)
			if not neighbor_tile:
				continue

			# Static Occupied Tile Penalty
			# If the target is an enemy for melee, it will be occupied. Allow pathing to the target itself.
			# We will strip the final occupied node in _reconstruct_path.
			# A* naturally doesn't block on the start node because it doesn't get evaluated as a neighbor of itself.
			if neighbor_tile.occupying_unit_id != -1 and neighbor_tile.occupying_unit_id != unit_id:
				if neighbor != target:
					continue

			valid_neighbors.append(neighbor)

	return valid_neighbors

func _heuristic(a: Vector3i, b: Vector3i) -> float:
	# Use standard 3D Manhattan distance without infinite penalty on Z
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)

func _reconstruct_path(came_from: Dictionary, current: Vector3i, matrix: BattlefieldMatrix) -> Array[Vector3i]:
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

	return path

func _is_cardinal_adjacent(current: Vector3i, target: Vector3i, matrix: BattlefieldMatrix) -> bool:
	return matrix.is_cardinal_passable(current, target)
