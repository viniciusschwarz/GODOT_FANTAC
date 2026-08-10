import sys

def main():
    with open('scripts/sim/pathfinding_engine.gd', 'r') as f:
        content = f.read()

    # The function string to append
    is_cardinal_adjacent_func = """
func _is_cardinal_adjacent(current: Vector3i, target: Vector3i, matrix: BattlefieldMatrix) -> bool:
	var dx = target.x - current.x
	var dy = target.y - current.y
	var dz = target.z - current.z

	if abs(dx) + abs(dy) != 1:
		return false

	if abs(dz) > 1:
		return false

	if dz == 0:
		return true

	# Stair transitions logic for Z changes
	var current_tile = matrix.get_tile(current)
	var target_tile = matrix.get_tile(target)

	if not current_tile or not target_tile:
		return false

	var expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.NONE
	var expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.NONE

	if dy == -1:
		expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
		expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
	elif dy == 1:
		expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
		expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
	elif dx == 1:
		expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
		expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W
	elif dx == -1:
		expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W
		expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E

	if dz == 1: # Moving UP
		if current_tile.vertical_connector_type == expected_up_connector:
			return true
	elif dz == -1: # Moving DOWN
		if target_tile.vertical_connector_type == expected_down_connector:
			return true

	return false
"""

    if "func _is_cardinal_adjacent" not in content:
        content += is_cardinal_adjacent_func
        with open('scripts/sim/pathfinding_engine.gd', 'w') as f:
            f.write(content)
        print("Patched PathfindingEngine by adding _is_cardinal_adjacent.")
    else:
        print("PathfindingEngine already has _is_cardinal_adjacent.")

if __name__ == "__main__":
    main()
