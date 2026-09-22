class_name FlowFieldSolver
extends RefCounted

const SpatialNavGraphRegistry = preload("res://framework/pathfinding/graph/spatial_nav_graph_registry.gd")
const NavigationProfileDefinition = preload("res://framework/pathfinding/graph/navigation_profile_definition.gd")
const GridTopologyAdapter = preload("res://framework/pathfinding/topology/grid_topology_adapter.gd")
const TraversalCostEvaluator = preload("res://framework/pathfinding/evaluators/traversal_cost_evaluator.gd")
const NavTopologyContract = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd")

class DijkstraNode:
	extends RefCounted
	var coord: Vector2i
	var cost: float = 0.0

	func _init(c: Vector2i, p_cost: float):
		coord = c
		cost = p_cost

class MinHeap:
	extends RefCounted
	var _array: Array[DijkstraNode] = []

	func size() -> int:
		return _array.size()

	func push(node: DijkstraNode) -> void:
		_array.append(node)
		_upheap(_array.size() - 1)

	func pop() -> DijkstraNode:
		if _array.is_empty():
			return null
		if _array.size() == 1:
			return _array.pop_back()

		var root = _array[0]
		_array[0] = _array.pop_back()
		_downheap(0)
		return root

	func _upheap(idx: int) -> void:
		var node = _array[idx]
		while idx > 0:
			var parent_idx = (idx - 1) / 2
			var parent = _array[parent_idx]
			if node.cost < parent.cost:
				_array[idx] = parent
				idx = parent_idx
			else:
				break
		_array[idx] = node

	func _downheap(idx: int) -> void:
		var size = _array.size()
		var node = _array[idx]
		while true:
			var min_idx = idx
			var left_idx = 2 * idx + 1
			var right_idx = 2 * idx + 2

			if left_idx < size and _array[left_idx].cost < _array[min_idx].cost:
				min_idx = left_idx
			if right_idx < size and _array[right_idx].cost < _array[min_idx].cost:
				min_idx = right_idx

			# Sinking node optimization correction
			# Compare the actual node we're sinking against the smallest child
			if min_idx != idx and _array[min_idx].cost < node.cost:
				_array[idx] = _array[min_idx]
				idx = min_idx
			else:
				break
		_array[idx] = node

static func generate_integration_field(targets: Array[Vector2i], graph: SpatialNavGraphRegistry, profile: NavigationProfileDefinition) -> PackedFloat32Array:
	var total_cells: int = graph.width * graph.height
	var integration_field: PackedFloat32Array = PackedFloat32Array()
	integration_field.resize(total_cells)
	integration_field.fill(INF)

	var req_clearance: int = max(profile.agent_footprint_in_cells.x, profile.agent_footprint_in_cells.y)
	var open_set = MinHeap.new()

	for target in targets:
		if graph.is_valid_coord(target):
			var idx: int = graph.get_cell_index(target)
			integration_field[idx] = 0.0
			open_set.push(DijkstraNode.new(target, 0.0))

	while open_set.size() > 0:
		var current = open_set.pop()
		var current_coord = current.coord
		var current_cost = current.cost

		var current_idx = graph.get_cell_index(current_coord)

		if current_cost > integration_field[current_idx]:
			continue

		var neighbors: Array[Vector2i] = GridTopologyAdapter.get_neighbors(current_coord, profile.topology_type, graph.bounds)

		for neighbor_coord in neighbors:
			if graph.get_clearance(neighbor_coord) < req_clearance:
				continue

			var is_diagonal = GridTopologyAdapter.is_diagonal_step(current_coord, neighbor_coord)
			if is_diagonal and not profile.allows_diagonal:
				continue

			if is_diagonal and profile.allows_diagonal and not profile.allow_corner_cutting:
				var dx = neighbor_coord.x - current_coord.x
				var dy = neighbor_coord.y - current_coord.y
				var n1 = Vector2i(current_coord.x + dx, current_coord.y)
				var n2 = Vector2i(current_coord.x, current_coord.y + dy)
				if not graph.is_cell_traversable(n1, profile.required_mask, profile.ignored_mask) or not graph.is_cell_traversable(n2, profile.required_mask, profile.ignored_mask):
					continue

			var step_cost = TraversalCostEvaluator.calculate_step_cost(current_coord, neighbor_coord, graph, profile)
			if step_cost == INF:
				continue

			var tentative_cost = current_cost + step_cost
			var neighbor_idx = graph.get_cell_index(neighbor_coord)

			if tentative_cost < integration_field[neighbor_idx]:
				integration_field[neighbor_idx] = tentative_cost
				open_set.push(DijkstraNode.new(neighbor_coord, tentative_cost))

	return integration_field

static func generate_vector_field(integration_field: PackedFloat32Array, graph: SpatialNavGraphRegistry, profile: NavigationProfileDefinition) -> PackedVector2Array:
	var total_cells: int = graph.width * graph.height
	var vector_field: PackedVector2Array = PackedVector2Array()
	vector_field.resize(total_cells)
	vector_field.fill(Vector2.ZERO)

	var req_clearance: int = max(profile.agent_footprint_in_cells.x, profile.agent_footprint_in_cells.y)

	for y in range(graph.height):
		for x in range(graph.width):
			var coord = Vector2i(x, y)
			var idx = graph.get_cell_index(coord)

			if integration_field[idx] == INF or integration_field[idx] == 0.0:
				continue

			var min_cost: float = INF
			var best_neighbor: Vector2i = coord

			# Order neighbors for deterministic tie-breaking
			var candidate_offsets: Array[Vector2i] = []
			if profile.topology_type == NavTopologyContract.TopologyType.ORTHOGONAL_4:
				candidate_offsets = [
					Vector2i(0, -1), # North
					Vector2i(1, 0),  # East
					Vector2i(0, 1),  # South
					Vector2i(-1, 0)  # West
				]
			elif profile.topology_type == NavTopologyContract.TopologyType.ORTHOGONAL_8:
				candidate_offsets = [
					Vector2i(0, -1),  # North
					Vector2i(1, -1),  # NorthEast
					Vector2i(1, 0),   # East
					Vector2i(1, 1),   # SouthEast
					Vector2i(0, 1),   # South
					Vector2i(-1, 1),  # SouthWest
					Vector2i(-1, 0),  # West
					Vector2i(-1, -1)  # NorthWest
				]
			elif profile.topology_type == NavTopologyContract.TopologyType.HEX_AXIAL:
				# Order roughly clockwise from top right
				candidate_offsets = [
					Vector2i(1, -1),
					Vector2i(1, 0),
					Vector2i(0, 1),
					Vector2i(-1, 1),
					Vector2i(-1, 0),
					Vector2i(0, -1)
				]

			for offset in candidate_offsets:
				var neighbor_coord = coord + offset
				if not graph.bounds.has_point(neighbor_coord):
					continue

				var is_diagonal = GridTopologyAdapter.is_diagonal_step(coord, neighbor_coord)
				if is_diagonal and not profile.allows_diagonal:
					continue

				if is_diagonal and profile.allows_diagonal and not profile.allow_corner_cutting:
					var dx = neighbor_coord.x - coord.x
					var dy = neighbor_coord.y - coord.y
					var n1 = Vector2i(coord.x + dx, coord.y)
					var n2 = Vector2i(coord.x, coord.y + dy)
					if not graph.is_cell_traversable(n1, profile.required_mask, profile.ignored_mask) or not graph.is_cell_traversable(n2, profile.required_mask, profile.ignored_mask):
						continue

				if graph.get_clearance(neighbor_coord) < req_clearance:
					continue

				if not graph.is_cell_traversable(neighbor_coord, profile.required_mask, profile.ignored_mask):
					continue

				var neighbor_idx = graph.get_cell_index(neighbor_coord)
				var neighbor_cost = integration_field[neighbor_idx]

				if neighbor_cost < min_cost - 0.0001:
					min_cost = neighbor_cost
					best_neighbor = neighbor_coord

			if best_neighbor != coord:
				vector_field[idx] = Vector2(best_neighbor - coord).normalized()

	return vector_field

static func get_flow_direction(coord: Vector2i, vector_field: PackedVector2Array, graph: SpatialNavGraphRegistry) -> Vector2:
	if graph.is_valid_coord(coord):
		var idx = graph.get_cell_index(coord)
		return vector_field[idx]
	return Vector2.ZERO
