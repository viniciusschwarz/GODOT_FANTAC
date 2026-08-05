extends Node
## Handles spatial calculations for a 2D battlefield with multi-floor structures (Z-levels).

## Scale multiplier for height differences when calculating effective distance.
const FLOOR_HEIGHT_SCALE: float = 2.0

## Maps 2D position (Vector2) to a 3D grid coordinate (Vector3i).
## In a full implementation, this would query a TileMap or navigation mesh.
func get_grid_position(world_pos: Vector2, elevation: int = 0) -> Vector3i:
	# Placeholder: Assuming a simple 64x64 grid
	var grid_x = int(world_pos.x / 64.0)
	var grid_y = int(world_pos.y / 64.0)
	return Vector3i(grid_x, grid_y, elevation)

## Calculates the effective distance between two points, accounting for elevation.
## Formula: Effective Distance = sqrt(ΔX^2 + ΔY^2 + (ΔZ * FloorHeightScale)^2)
func get_effective_distance(pos_a: Vector3i, pos_b: Vector3i) -> float:
	var delta_x = pos_b.x - pos_a.x
	var delta_y = pos_b.y - pos_a.y
	var delta_z = pos_b.z - pos_a.z

	var effective_z = delta_z * FLOOR_HEIGHT_SCALE

	return sqrt((delta_x * delta_x) + (delta_y * delta_y) + (effective_z * effective_z))

## Checks if there is a clear Line of Sight between two points on the grid.
func check_line_of_sight(pos_a: Vector3i, pos_b: Vector3i) -> bool:
	# Placeholder for actual raycasting or Bresenham's line algorithm with Z-checks
	return true
