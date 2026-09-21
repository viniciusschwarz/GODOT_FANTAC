class_name NavTopologyContract
extends RefCounted

enum TopologyType {
	ORTHOGONAL_4 = 0,
	ORTHOGONAL_8 = 1,
	HEX_AXIAL = 2
}

enum CellMask {
	NONE = 0,
	SOLID = 1 << 0,
	WATER = 1 << 1,
	FLYING = 1 << 2,
	HAZARD = 1 << 3,
	DOOR_CLOSED = 1 << 4
}

## Returns a list of valid neighbors within the given bounds based on the topology type.
func get_neighbors(coord: Vector2i, topology_type: int, bounds: Rect2i) -> Array[Vector2i]:
	return []

## Calculates the distance between two coordinates based on the topology type.
func calculate_distance(from_coord: Vector2i, to_coord: Vector2i, topology_type: int) -> float:
	return 0.0
