class_name AStar2DSolver
extends RefCounted

const SpatialNavGraphRegistry = preload("res://framework/pathfinding/graph/spatial_nav_graph_registry.gd")
const NavigationProfileDefinition = preload("res://framework/pathfinding/graph/navigation_profile_definition.gd")
const AsymmetricLinkRegistry = preload("res://framework/pathfinding/topology/asymmetric_link_registry.gd")
const GridTopologyAdapter = preload("res://framework/pathfinding/topology/grid_topology_adapter.gd")
const TraversalCostEvaluator = preload("res://framework/pathfinding/evaluators/traversal_cost_evaluator.gd")
const NavTopologyContract = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd")

class AStarNode:
	extends RefCounted
	var coord: Vector2i
	var g_cost: float = 0.0
	var h_cost: float = 0.0
	var f_cost: float = 0.0
	var parent: AStarNode = null
	var entry_index: int = 0

	func _init(c: Vector2i):
		coord = c

class MinHeap:
	extends RefCounted
	var _array: Array[AStarNode] = []

	func size() -> int:
		return _array.size()

	func push(node: AStarNode) -> void:
		_array.append(node)
		_upheap(_array.size() - 1)

	func pop() -> AStarNode:
		if _array.is_empty():
			return null
		if _array.size() == 1:
			return _array.pop_back()

		var root = _array[0]
		_array[0] = _array.pop_back()
		_downheap(0)
		return root

	func update(node: AStarNode) -> void:
		var idx = _array.find(node)
		if idx != -1:
			_upheap(idx)

	func has(node: AStarNode) -> bool:
		return _array.has(node)

	func _upheap(idx: int) -> void:
		var node = _array[idx]
		while idx > 0:
			var parent_idx = (idx - 1) / 2
			var parent = _array[parent_idx]
			if _compare(node, parent):
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

			if left_idx < size and _compare(_array[left_idx], _array[min_idx]):
				min_idx = left_idx
			if right_idx < size and _compare(_array[right_idx], _array[min_idx]):
				min_idx = right_idx

			if min_idx != idx:
				_array[idx] = _array[min_idx]
				idx = min_idx
			else:
				break
		_array[idx] = node

	func _compare(a: AStarNode, b: AStarNode) -> bool:
		if abs(a.f_cost - b.f_cost) > 0.0001:
			return a.f_cost < b.f_cost
		if abs(a.h_cost - b.h_cost) > 0.0001:
			return a.h_cost < b.h_cost
		return a.entry_index < b.entry_index # FIFO tie-breaking

static func find_path(start: Vector2i, goal: Vector2i, graph: SpatialNavGraphRegistry, profile: NavigationProfileDefinition, link_registry: AsymmetricLinkRegistry = null) -> Array[Vector2i]:
	if start == goal:
		return [start] as Array[Vector2i]

	var req_clearance: int = max(profile.agent_footprint_in_cells.x, profile.agent_footprint_in_cells.y)
	if not graph.is_cell_traversable(goal, profile.required_mask, profile.ignored_mask):
		return [] as Array[Vector2i]
	if graph.get_clearance(goal) < req_clearance:
		return [] as Array[Vector2i]

	var open_set = MinHeap.new()
	var closed_set: Dictionary = {}
	var node_records: Dictionary = {}
	var entry_counter: int = 0
	var nodes_evaluated: int = 0

	var start_node = AStarNode.new(start)
	start_node.g_cost = 0.0
	start_node.h_cost = TraversalCostEvaluator.calculate_heuristic(start, goal, profile.topology_type, profile.heuristic_weight)
	start_node.f_cost = start_node.g_cost + start_node.h_cost
	start_node.entry_index = entry_counter
	entry_counter += 1

	open_set.push(start_node)
	node_records[start] = start_node

	while open_set.size() > 0:
		if nodes_evaluated >= profile.max_node_budget:
			return [] as Array[Vector2i]

		var current: AStarNode = open_set.pop()
		nodes_evaluated += 1

		if current.coord == goal:
			var path: Array[Vector2i] = []
			var curr_trace = current
			while curr_trace != null:
				path.append(curr_trace.coord)
				curr_trace = curr_trace.parent
			path.reverse()
			return path

		closed_set[current.coord] = true

		var neighbors: Array[Vector2i] = GridTopologyAdapter.get_neighbors(current.coord, profile.topology_type, graph.bounds)

		for neighbor_coord in neighbors:
			if closed_set.has(neighbor_coord):
				continue

			if graph.get_clearance(neighbor_coord) < req_clearance:
				continue

			# Check corner cutting
			var is_diagonal = GridTopologyAdapter.is_diagonal_step(current.coord, neighbor_coord)
			if is_diagonal and not profile.allows_diagonal:
				continue

			if is_diagonal and profile.allows_diagonal and not profile.allow_corner_cutting:
				var dx = neighbor_coord.x - current.coord.x
				var dy = neighbor_coord.y - current.coord.y
				var n1 = Vector2i(current.coord.x + dx, current.coord.y)
				var n2 = Vector2i(current.coord.x, current.coord.y + dy)
				if not graph.is_cell_traversable(n1, profile.required_mask, profile.ignored_mask) or not graph.is_cell_traversable(n2, profile.required_mask, profile.ignored_mask):
					continue

			var step_cost = TraversalCostEvaluator.calculate_step_cost(current.coord, neighbor_coord, graph, profile)
			if step_cost == INF:
				continue

			var tentative_g = current.g_cost + step_cost

			if not node_records.has(neighbor_coord):
				var neighbor_node = AStarNode.new(neighbor_coord)
				neighbor_node.g_cost = tentative_g
				neighbor_node.h_cost = TraversalCostEvaluator.calculate_heuristic(neighbor_coord, goal, profile.topology_type, profile.heuristic_weight)
				neighbor_node.f_cost = neighbor_node.g_cost + neighbor_node.h_cost
				neighbor_node.parent = current
				neighbor_node.entry_index = entry_counter
				entry_counter += 1
				node_records[neighbor_coord] = neighbor_node
				open_set.push(neighbor_node)
			else:
				var neighbor_node = node_records[neighbor_coord]
				if tentative_g < neighbor_node.g_cost:
					neighbor_node.parent = current
					neighbor_node.g_cost = tentative_g
					neighbor_node.f_cost = neighbor_node.g_cost + neighbor_node.h_cost
					if not open_set.has(neighbor_node):
						neighbor_node.entry_index = entry_counter
						entry_counter += 1
						open_set.push(neighbor_node)
					else:
						open_set.update(neighbor_node)

		if link_registry != null and link_registry.has_links(current.coord):
			var links = link_registry.get_links(current.coord)
			for link in links:
				var link_to = link["to_coord"]
				if closed_set.has(link_to):
					continue

				if link["mask_requirement"] != 0 and (graph.get_cell_mask(current.coord) & link["mask_requirement"]) != link["mask_requirement"]:
					continue

				if graph.get_clearance(link_to) < req_clearance:
					continue

				var tentative_g = current.g_cost + link["cost"]

				if not node_records.has(link_to):
					var link_node = AStarNode.new(link_to)
					link_node.g_cost = tentative_g
					link_node.h_cost = TraversalCostEvaluator.calculate_heuristic(link_to, goal, profile.topology_type, profile.heuristic_weight)
					link_node.f_cost = link_node.g_cost + link_node.h_cost
					link_node.parent = current
					link_node.entry_index = entry_counter
					entry_counter += 1
					node_records[link_to] = link_node
					open_set.push(link_node)
				else:
					var link_node = node_records[link_to]
					if tentative_g < link_node.g_cost:
						link_node.parent = current
						link_node.g_cost = tentative_g
						link_node.f_cost = link_node.g_cost + link_node.h_cost
						if not open_set.has(link_node):
							link_node.entry_index = entry_counter
							entry_counter += 1
							open_set.push(link_node)
						else:
							open_set.update(link_node)

	return [] as Array[Vector2i]
