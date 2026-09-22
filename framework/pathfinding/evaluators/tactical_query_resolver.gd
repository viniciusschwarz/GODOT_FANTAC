class_name TacticalQueryResolver
extends RefCounted

const SpatialNavGraphRegistry = preload("res://framework/pathfinding/graph/spatial_nav_graph_registry.gd")
const NavTopologyContract = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd")

enum CoverType {
	NONE = 0,
	HALF_COVER = 1,
	FULL_COVER = 2
}

static func has_line_of_sight(from_coord: Vector2i, to_coord: Vector2i, graph: SpatialNavGraphRegistry, vision_blocking_mask: int = NavTopologyContract.CellMask.SOLID) -> bool:
	if from_coord == to_coord:
		return true

	var x0: int = from_coord.x
	var y0: int = from_coord.y
	var x1: int = to_coord.x
	var y1: int = to_coord.y

	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy

	while true:
		var current = Vector2i(x0, y0)
		if current != from_coord and current != to_coord:
			if (graph.get_cell_mask(current) & vision_blocking_mask) != 0:
				return false

		if x0 == x1 and y0 == y1:
			break

		var e2: int = 2 * err
		if e2 >= dy:
			if x0 == x1: break
			err += dy
			x0 += sx
		if e2 <= dx:
			if y0 == y1: break
			err += dx
			y0 += sy

	return true

static func evaluate_cover(defender_coord: Vector2i, threat_coord: Vector2i, graph: SpatialNavGraphRegistry, vision_blocking_mask: int = NavTopologyContract.CellMask.SOLID) -> int:
	if defender_coord == threat_coord:
		return CoverType.NONE

	# Step 1: If total line of sight is blocked, defender has FULL cover
	if not has_line_of_sight(defender_coord, threat_coord, graph, vision_blocking_mask):
		return CoverType.FULL_COVER

	# Step 2: Check adjacent neighbor tiles between defender and threat for HALF cover
	var dx: int = signi(threat_coord.x - defender_coord.x)
	var dy: int = signi(threat_coord.y - defender_coord.y)

	var primary_adj = defender_coord + Vector2i(dx, dy)
	var ortho_x = defender_coord + Vector2i(dx, 0)
	var ortho_y = defender_coord + Vector2i(0, dy)

	# If adjacent tile in threat direction has solid obstacle, it grants HALF cover
	if (graph.get_cell_mask(primary_adj) & vision_blocking_mask) != 0:
		return CoverType.HALF_COVER
	if dx != 0 and (graph.get_cell_mask(ortho_x) & vision_blocking_mask) != 0:
		return CoverType.HALF_COVER
	if dy != 0 and (graph.get_cell_mask(ortho_y) & vision_blocking_mask) != 0:
		return CoverType.HALF_COVER

	return CoverType.NONE

static func calculate_field_of_view(origin: Vector2i, max_range: int, graph: SpatialNavGraphRegistry, vision_blocking_mask: int = NavTopologyContract.CellMask.SOLID) -> Array[Vector2i]:
	var visible_cells_dict: Dictionary = {}
	visible_cells_dict[origin] = true

	for octant in range(8):
		_cast_light(origin, 1, 1.0, 0.0, max_range, octant, graph, vision_blocking_mask, visible_cells_dict)

	var result: Array[Vector2i] = []
	for coord in visible_cells_dict.keys():
		result.append(coord)
	return result

static func _cast_light(origin: Vector2i, row: int, start_slope: float, end_slope: float, radius: int, octant: int, graph: SpatialNavGraphRegistry, vision_blocking_mask: int, visible_cells_dict: Dictionary) -> void:
	if start_slope < end_slope:
		return

	var radius_squared: int = radius * radius
	var next_start_slope: float = start_slope

	for j in range(row, radius + 1):
		var blocked: bool = false
		var dx: int = -j - 1
		var dy: int = -j

		while dx <= 0:
			dx += 1
			var l_slope: float = (dx - 0.5) / (dy + 0.5)
			var r_slope: float = (dx + 0.5) / (dy - 0.5)

			if start_slope < r_slope:
				continue
			elif end_slope > l_slope:
				break

			var nx: int = 0
			var ny: int = 0

			# Map standard coordinate system to the octant
			if octant == 0:
				nx = origin.x + dx
				ny = origin.y - dy
			elif octant == 1:
				nx = origin.x - dx
				ny = origin.y - dy
			elif octant == 2:
				nx = origin.x + dy
				ny = origin.y - dx
			elif octant == 3:
				nx = origin.x - dy
				ny = origin.y - dx
			elif octant == 4:
				nx = origin.x + dx
				ny = origin.y + dy
			elif octant == 5:
				nx = origin.x - dx
				ny = origin.y + dy
			elif octant == 6:
				nx = origin.x + dy
				ny = origin.y + dx
			elif octant == 7:
				nx = origin.x - dy
				ny = origin.y + dx

			var current_coord = Vector2i(nx, ny)

			if (nx - origin.x) * (nx - origin.x) + (ny - origin.y) * (ny - origin.y) <= radius_squared:
				visible_cells_dict[current_coord] = true

			if blocked:
				if (graph.get_cell_mask(current_coord) & vision_blocking_mask) != 0:
					next_start_slope = r_slope
				else:
					blocked = false
					start_slope = next_start_slope
			else:
				if (graph.get_cell_mask(current_coord) & vision_blocking_mask) != 0 and j < radius:
					blocked = true
					_cast_light(origin, j + 1, start_slope, r_slope, radius, octant, graph, vision_blocking_mask, visible_cells_dict)
					next_start_slope = r_slope

		if blocked:
			break
