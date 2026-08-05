class_name TargetingComponent
extends Node2D
## Performs line-of-sight checks and target detection across Z-levels.

@onready var los_raycast: RayCast2D = $RayCast2D if has_node("RayCast2D") else null

var unit_owner: Node

func _ready() -> void:
	unit_owner = get_parent()

	if not los_raycast:
		# Create a placeholder raycast if not assigned in editor
		los_raycast = RayCast2D.new()
		add_child(los_raycast)
		los_raycast.enabled = false # Enable only when checking

## Finds the nearest valid enemy within a given range.
func get_nearest_target(max_range: float, elevation: int) -> Node:
	# Placeholder logic.
	# Real logic would query AIManager or a spatial hash for enemies.
	# Use GridManager to calculate effective distance with Z-levels.
	return null

## Checks if there is clear line of sight to the target.
func has_line_of_sight(target: Node) -> bool:
	if not target or not is_instance_valid(target):
		return false

	if los_raycast:
		los_raycast.target_position = target.global_position - global_position
		los_raycast.force_raycast_update()

		if los_raycast.is_colliding():
			var collider = los_raycast.get_collider()
			return collider == target

	return true
