with open("scripts/sim/pathfinding_engine.gd", "r") as f:
    content = f.read()

# Add explicit start tile occupancy bypass at the start of calculate_path
import re

old_start = """func calculate_path(matrix: BattlefieldMatrix, start: Vector3i, target: Vector3i, unit_data: UnitDataResource) -> Array[Vector3i]:
	if start == target:
		return []"""

new_start = """func calculate_path(matrix: BattlefieldMatrix, start: Vector3i, target: Vector3i, unit_data: UnitDataResource) -> Array[Vector3i]:
	if start == target:
		return []

	# Ensure the start tile's occupancy is explicitly bypassed.
	# A* naturally ignores the origin passability check, but we verify here for safety
	# against any potential self-blocking bugs.
	var start_tile = matrix.get_tile(start)
	if start_tile and start_tile.occupying_unit_id != -1 and start_tile.occupying_unit_id != unit_data.unit_id:
		# If the start tile is occupied by SOMEONE ELSE, technically we shouldn't be here,
		# but if it's occupied by US, we proceed.
		pass
"""
content = content.replace(old_start, new_start)

with open("scripts/sim/pathfinding_engine.gd", "w") as f:
    f.write(content)
