class_name SpatialNavGraphRegistry
extends RefCounted

const TopologyType = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd").TopologyType
const CellMask = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd").CellMask
const ClearanceCalculator = preload("res://framework/pathfinding/graph/clearance_map_calculator.gd")

var width: int = 0
var height: int = 0
var bounds: Rect2i = Rect2i()
var topology_type: int = TopologyType.ORTHOGONAL_4

var costs_per_cell: PackedFloat32Array
var masks_per_cell: PackedInt32Array
var clearance_per_cell: PackedByteArray

func initialize_grid(p_width: int, p_height: int, p_topology: int = TopologyType.ORTHOGONAL_4) -> void:
	width = p_width
	height = p_height
	bounds = Rect2i(0, 0, width, height)
	topology_type = p_topology

	var total_cells: int = width * height

	costs_per_cell = PackedFloat32Array()
	costs_per_cell.resize(total_cells)
	costs_per_cell.fill(1.0)

	masks_per_cell = PackedInt32Array()
	masks_per_cell.resize(total_cells)
	masks_per_cell.fill(0)

	clearance_per_cell = PackedByteArray()
	clearance_per_cell.resize(total_cells)
	clearance_per_cell.fill(0)

func get_cell_index(coord: Vector2i) -> int:
	return (coord.y * width) + coord.x

func get_coord_from_index(index: int) -> Vector2i:
	return Vector2i(index % width, index / width)

func is_valid_coord(coord: Vector2i) -> bool:
	return bounds.has_point(coord)

func set_cell_cost(coord: Vector2i, cost: float) -> void:
	if is_valid_coord(coord):
		var index: int = get_cell_index(coord)
		costs_per_cell[index] = cost

func get_cell_cost(coord: Vector2i) -> float:
	if is_valid_coord(coord):
		var index: int = get_cell_index(coord)
		return costs_per_cell[index]
	return INF

func set_cell_mask(coord: Vector2i, mask_bits: int, is_enabled: bool) -> void:
	if is_valid_coord(coord):
		var index: int = get_cell_index(coord)
		if is_enabled:
			masks_per_cell[index] |= mask_bits
		else:
			masks_per_cell[index] &= ~mask_bits

func get_cell_mask(coord: Vector2i) -> int:
	if is_valid_coord(coord):
		var index: int = get_cell_index(coord)
		return masks_per_cell[index]
	return CellMask.SOLID # Treat out of bounds as solid

func is_cell_traversable(coord: Vector2i, required_mask: int = 0, ignored_mask: int = 0) -> bool:
	if not is_valid_coord(coord):
		return false

	var cell_mask: int = get_cell_mask(coord)

	var effective_mask: int = cell_mask & ~ignored_mask
	if (effective_mask & CellMask.SOLID) != 0:
		return false

	if required_mask != 0 and (cell_mask & required_mask) != required_mask:
		return false

	return true

func recalculate_clearance() -> void:
	# Create a callable bounded to the current instance context
	var callable = Callable(self, "_is_cell_blocked_for_clearance")
	clearance_per_cell = ClearanceCalculator.compute_clearance(width, height, callable)

func _is_cell_blocked_for_clearance(coord: Vector2i) -> bool:
	var cell_mask: int = get_cell_mask(coord)
	return (cell_mask & CellMask.SOLID) != 0

func get_clearance(coord: Vector2i) -> int:
	if is_valid_coord(coord):
		var index: int = get_cell_index(coord)
		return clearance_per_cell[index]
	return 0
