class_name SpatialCellRegistry
extends RefCounted

var _width: int = 0
var _height: int = 0
var _cells: PackedInt32Array = PackedInt32Array()

func init(width: int, height: int) -> void:
	_width = width
	_height = height
	_cells.resize(_width * _height)
	_cells.fill(-1)

func is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < _width and coord.y >= 0 and coord.y < _height

func get_occupant(coord: Vector2i) -> int:
	if not is_within_bounds(coord):
		return -1
	return _cells[coord.y * _width + coord.x]

func set_occupant(coord: Vector2i, entity_id: int) -> bool:
	if not is_within_bounds(coord):
		return false
	_cells[coord.y * _width + coord.x] = entity_id
	return true

func clear_cell(coord: Vector2i) -> void:
	if is_within_bounds(coord):
		_cells[coord.y * _width + coord.x] = -1

func calculate_distance(a: Vector2i, b: Vector2i, metric: int = 0) -> int:
	# 0 = Manhattan, 1 = Chebyshev, etc. Defaulting to Manhattan for now.
	if metric == 0:
		return abs(a.x - b.x) + abs(a.y - b.y)
	elif metric == 1:
		return maxi(abs(a.x - b.x), abs(a.y - b.y))
	return -1 # Unsupported metric

func get_save_state() -> Dictionary:
	return {
		"width": _width,
		"height": _height,
		"cells": _cells
	}

func load_save_state(state: Dictionary) -> bool:
	if not state.has("width") or not state.has("height") or not state.has("cells"):
		return false

	_width = state["width"]
	_height = state["height"]
	_cells = state["cells"]
	return true
