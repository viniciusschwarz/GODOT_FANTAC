class_name ClearanceMapCalculator
extends RefCounted

static func compute_clearance(width: int, height: int, is_blocked_callable: Callable) -> PackedByteArray:
	var total_cells: int = width * height
	var clearance_map = PackedByteArray()
	clearance_map.resize(total_cells)
	clearance_map.fill(0)

	# Bottom-up dynamic programming
	for y in range(height - 1, -1, -1):
		for x in range(width - 1, -1, -1):
			var index: int = (y * width) + x

			if is_blocked_callable.call(Vector2i(x, y)):
				clearance_map[index] = 0
				continue

			# If cell is on right or bottom edge
			if x == width - 1 or y == height - 1:
				clearance_map[index] = 1
			else:
				var right_clearance: int = clearance_map[(y * width) + (x + 1)]
				var bottom_clearance: int = clearance_map[((y + 1) * width) + x]
				var bottom_right_clearance: int = clearance_map[((y + 1) * width) + (x + 1)]

				var min_adjacent = min(right_clearance, min(bottom_clearance, bottom_right_clearance))
				var new_clearance: int = 1 + min_adjacent

				# Clamp to 255 as we are using PackedByteArray
				clearance_map[index] = min(new_clearance, 255)

	return clearance_map
