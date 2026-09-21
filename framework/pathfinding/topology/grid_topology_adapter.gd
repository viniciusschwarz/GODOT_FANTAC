class_name GridTopologyAdapter
extends RefCounted

const TopologyType = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd").TopologyType

static func get_neighbors(coord: Vector2i, topology_type: int, bounds: Rect2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var candidates: Array[Vector2i] = []

	if topology_type == TopologyType.ORTHOGONAL_4:
		candidates = [
			Vector2i(coord.x, coord.y - 1), # North
			Vector2i(coord.x, coord.y + 1), # South
			Vector2i(coord.x + 1, coord.y), # East
			Vector2i(coord.x - 1, coord.y)  # West
		]
	elif topology_type == TopologyType.ORTHOGONAL_8:
		candidates = [
			Vector2i(coord.x, coord.y - 1),     # North
			Vector2i(coord.x, coord.y + 1),     # South
			Vector2i(coord.x + 1, coord.y),     # East
			Vector2i(coord.x - 1, coord.y),     # West
			Vector2i(coord.x - 1, coord.y - 1), # NorthWest
			Vector2i(coord.x + 1, coord.y - 1), # NorthEast
			Vector2i(coord.x - 1, coord.y + 1), # SouthWest
			Vector2i(coord.x + 1, coord.y + 1)  # SouthEast
		]
	elif topology_type == TopologyType.HEX_AXIAL:
		candidates = [
			Vector2i(coord.x + 1, coord.y),
			Vector2i(coord.x + 1, coord.y - 1),
			Vector2i(coord.x, coord.y - 1),
			Vector2i(coord.x - 1, coord.y),
			Vector2i(coord.x - 1, coord.y + 1),
			Vector2i(coord.x, coord.y + 1)
		]

	for candidate in candidates:
		if bounds.has_point(candidate):
			neighbors.append(candidate)

	return neighbors

static func calculate_distance(from_coord: Vector2i, to_coord: Vector2i, topology_type: int) -> float:
	var dx: float = abs(from_coord.x - to_coord.x)
	var dy: float = abs(from_coord.y - to_coord.y)

	if topology_type == TopologyType.ORTHOGONAL_4:
		# Manhattan distance
		return dx + dy
	elif topology_type == TopologyType.ORTHOGONAL_8:
		# Chebyshev/Octile distance
		return max(dx, dy)
	elif topology_type == TopologyType.HEX_AXIAL:
		# Hex axial distance: (|dq| + |dq + dr| + |dr|) / 2.0
		var dq: float = from_coord.x - to_coord.x
		var dr: float = from_coord.y - to_coord.y
		return (abs(dq) + abs(dq + dr) + abs(dr)) / 2.0

	return 0.0

static func is_diagonal_step(from_coord: Vector2i, to_coord: Vector2i) -> bool:
	var dx: int = abs(from_coord.x - to_coord.x)
	var dy: int = abs(from_coord.y - to_coord.y)
	return dx == 1 and dy == 1
