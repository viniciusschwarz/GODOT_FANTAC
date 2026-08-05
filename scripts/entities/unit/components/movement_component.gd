class_name MovementComponent
extends Node
## Handles path execution, movement speed, knockback physics, and tile transitions.

var unit_owner: CharacterBody2D
var current_speed: float = 3.0
var target_position: Vector2

var is_moving: bool = false
var path: Array[Vector2] = []

func _ready() -> void:
	if get_parent() is CharacterBody2D:
		unit_owner = get_parent()
	else:
		push_warning("MovementComponent parent must be a CharacterBody2D")

func initialize(speed: float) -> void:
	current_speed = speed

func _physics_process(delta: float) -> void:
	if not is_moving or not unit_owner:
		return

	# Placeholder for actual path following logic.
	# Normally this would move along `path` points using navigation.

	if path.size() > 0:
		var next_point = path[0]
		var direction = (next_point - unit_owner.global_position).normalized()
		var velocity = direction * current_speed * 64.0 # Scale to grid size roughly

		unit_owner.velocity = velocity
		unit_owner.move_and_slide()

		# Update facing
		if unit_owner.has_method("set_facing"):
			unit_owner.set_facing(direction)

		if unit_owner.global_position.distance_to(next_point) < 5.0:
			path.remove_at(0)

		if path.size() == 0:
			is_moving = false
			# If called during execution phase, signal completion
			# Only signal if we were commanded to move this phase.

func set_path(new_path: Array[Vector2]) -> void:
	path = new_path
	is_moving = true

## Applies a physical impulse (e.g., knockback from a heavy hit).
func apply_impulse(impulse_vector: Vector2) -> void:
	if unit_owner:
		# Simple implementation; a robust one would use lerp or physics forces
		unit_owner.velocity += impulse_vector
		unit_owner.move_and_slide()
