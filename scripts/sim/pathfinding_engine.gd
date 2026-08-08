class_name PathfindingEngine extends RefCounted

func calculate_path(matrix: BattlefieldMatrix, start: Vector3i, target: Vector3i, unit_data: UnitDataResource) -> Array[Vector3i]:
	if start == target:
		return [start]

	# A* Implementation restricted to 4-directional cardinal steps (N, S, E, W)
	var open_set: Array[Vector3i] = [start]
	var came_from: Dictionary = {}

	# g_score: actual cost from start to node
	var g_score: Dictionary = {}
	g_score[start] = 0.0

	# f_score: g_score + heuristic (Manhattan distance)
	var f_score: Dictionary = {}
	f_score[start] = _heuristic(start, target)

	var directions: Array[Vector3i] = [
		Vector3i(0, -1, 0), # N
		Vector3i(0, 1, 0),  # S
		Vector3i(1, 0, 0),  # E
		Vector3i(-1, 0, 0)  # W
	]

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
			return _reconstruct_path(came_from, current)

		open_set.remove_at(current_index)

		for dir in directions:
			# Calculate lateral neighbor coordinate (ignoring z first to check passable)
			var lateral_neighbor = current + dir

			# We need to determine the correct Z coordinate of the neighbor.
			# is_cardinal_passable will validate the transition, but we have to pass it
			# the exact coordinates including Z.
			#
			# Rules for Z:
			# ASCENDING (Z0 -> Z1): Moving in the direction of the connector
			# DESCENDING (Z1 -> Z0): Moving in the OPPOSITE direction of the connector from Z1

			var current_tile = matrix.get_tile(current)
			if not current_tile:
				continue

			var neighbor_z = current.z
			var neighbor = Vector3i(lateral_neighbor.x, lateral_neighbor.y, neighbor_z)

			if current.z == 0:
				# Check for ascending
				var expected_up_connector: TileSpatialNodeResource.VerticalConnectorType = TileSpatialNodeResource.VerticalConnectorType.NONE
				if dir == Vector3i(0, -1, 0): expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
				elif dir == Vector3i(0, 1, 0): expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
				elif dir == Vector3i(1, 0, 0): expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
				elif dir == Vector3i(-1, 0, 0): expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W

				if current_tile.vertical_connector_type == expected_up_connector:
					neighbor_z = 1
					neighbor.z = 1

			elif current.z == 1:
				# Check for descending (tile below current has the connector pointing opposite)
				var expected_down_connector: TileSpatialNodeResource.VerticalConnectorType = TileSpatialNodeResource.VerticalConnectorType.NONE
				if dir == Vector3i(0, -1, 0): expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
				elif dir == Vector3i(0, 1, 0): expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
				elif dir == Vector3i(1, 0, 0): expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W
				elif dir == Vector3i(-1, 0, 0): expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E

				var tile_below = matrix.get_tile(Vector3i(current.x, current.y, 0))
				if tile_below and tile_below.vertical_connector_type == expected_down_connector:
					neighbor_z = 0
					neighbor.z = 0

			# Check passability using the matrix
			if not matrix.is_cardinal_passable(current, neighbor):
				continue

			var neighbor_tile = matrix.get_tile(neighbor)
			if not neighbor_tile:
				continue

			# Calculate cost
			var cost: float = neighbor_tile.base_traversal_cost # Normal: 1.0, Rubble: 2.0

			# Staircase cost applies if transitioning Z
			if current.z != neighbor.z:
				cost = 1.5

			# Static Occupied Tile Penalty
			if neighbor_tile.occupying_unit_id != -1 and neighbor_tile.occupying_unit_id != unit_data.unit_id:
				cost += 50.0

			var tentative_g_score = g_score.get(current, INF) + cost

			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, target)

				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# Path calculation failed
	unit_data.recalculation_cooldown_ticks = 5
	return []

func _heuristic(a: Vector3i, b: Vector3i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z) * 1.5 # Z transitions are more expensive

func _reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
