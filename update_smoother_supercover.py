import sys

content = """class_name PathSmootherResolver
extends RefCounted

const SpatialNavGraphRegistry = preload("res://framework/pathfinding/graph/spatial_nav_graph_registry.gd")
const NavigationProfileDefinition = preload("res://framework/pathfinding/graph/navigation_profile_definition.gd")

static func smooth_path(path: Array[Vector2i], graph: SpatialNavGraphRegistry, profile: NavigationProfileDefinition) -> Array[Vector2i]:
	if path.size() <= 2:
		return path.duplicate()

	var smoothed_path: Array[Vector2i] = [path[0]]
	var current_index: int = 0
	var req_clearance: int = max(profile.agent_footprint_in_cells.x, profile.agent_footprint_in_cells.y)

	while current_index < path.size() - 1:
		var furthest_visible_index: int = current_index + 1

		# Try to find the furthest node we have line of sight to
		for j in range(path.size() - 1, current_index + 1, -1):
			if _has_line_of_sight_supercover(path[current_index], path[j], graph, profile, req_clearance):
				furthest_visible_index = j
				break

		smoothed_path.append(path[furthest_visible_index])
		current_index = furthest_visible_index

	return smoothed_path

static func _has_line_of_sight_supercover(start: Vector2i, end: Vector2i, graph: SpatialNavGraphRegistry, profile: NavigationProfileDefinition, req_clearance: int) -> bool:
	# Bresenham's Supercover Line Algorithm
	# This ensures we check all cells that the ray passes through, not just a thin diagonal line.

	var x: int = start.x
	var y: int = start.y
	var dx: int = abs(end.x - start.x)
	var dy: int = abs(end.y - start.y)
	var sx: int = 1 if start.x < end.x else -1
	var sy: int = 1 if start.y < end.y else -1

	var ix: int = 0
	var iy: int = 0

	# Initial check at start position
	var current_cell = Vector2i(x, y)
	if not graph.is_cell_traversable(current_cell, profile.required_mask, profile.ignored_mask):
		return false
	if graph.get_clearance(current_cell) < req_clearance:
		return false

	while ix < dx or iy < dy:
		var decision: float = (0.5 + ix) / max(1.0, float(dx)) - (0.5 + iy) / max(1.0, float(dy))

		if decision == 0:
			# Diagonal step - must check both orthogonal neighbors for supercover
			x += sx
			y += sy
			ix += 1
			iy += 1

			var nx1 = Vector2i(x, y - sy)
			if not graph.is_cell_traversable(nx1, profile.required_mask, profile.ignored_mask) or graph.get_clearance(nx1) < req_clearance:
				return false

			var nx2 = Vector2i(x - sx, y)
			if not graph.is_cell_traversable(nx2, profile.required_mask, profile.ignored_mask) or graph.get_clearance(nx2) < req_clearance:
				return false

		elif decision < 0:
			x += sx
			ix += 1
		else:
			y += sy
			iy += 1

		current_cell = Vector2i(x, y)
		if not graph.is_cell_traversable(current_cell, profile.required_mask, profile.ignored_mask):
			return false
		if graph.get_clearance(current_cell) < req_clearance:
			return false

	return true
"""

with open("framework/pathfinding/solvers/path_smoother_resolver.gd", "w") as f:
    f.write(content)
