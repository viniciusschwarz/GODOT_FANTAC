class_name MovementComponent
extends Node
## Handles path execution, movement speed, knockback physics, and tile transitions.

var unit_owner: CharacterBody2D
var base_speed: float = 3.0
var current_speed: float = 3.0

var is_moving: bool = false
var path: Array[Vector2] = []

# Dynamic Terrain States
var current_z_elevation: int = 0
var current_move_penalty: float = 1.0

func _ready() -> void:
	if get_parent() is CharacterBody2D:
		unit_owner = get_parent()
	else:
		push_warning("MovementComponent parent must be a CharacterBody2D")

func initialize(speed: float) -> void:
	base_speed = speed
	current_speed = speed
	_update_terrain_state()

func _physics_process(delta: float) -> void:
	if not is_moving or not unit_owner:
		return

	if path.size() > 0:
		var next_point = path[0]
		var direction = (next_point - unit_owner.global_position).normalized()

		# Apply move penalty to current velocity
		var effective_speed = current_speed * (1.0 / current_move_penalty)
		var velocity = direction * effective_speed * 64.0

		unit_owner.velocity = velocity
		unit_owner.move_and_slide()

		if unit_owner.has_method("set_facing"):
			unit_owner.set_facing(direction)

		if unit_owner.global_position.distance_to(next_point) < 5.0:
			path.remove_at(0)
			_update_terrain_state() # Update state when reaching a new tile

		if path.size() == 0:
			is_moving = false

func set_path(new_path: Array[Vector2]) -> void:
	path = new_path
	is_moving = true

func _update_terrain_state() -> void:
	if not unit_owner: return

	var grid_pos = GridManager.get_grid_position2d(unit_owner.global_position)
	var tile_data = GridManager.get_tile_data(grid_pos)

	current_z_elevation = tile_data["z_height"]
	current_move_penalty = tile_data["move_penalty"]

	# Pass cover bonus to health component if it exists
	if unit_owner.has_node("HealthComponent"):
		unit_owner.get_node("HealthComponent").current_cover_bonus = tile_data["cover_bonus"]

func apply_impulse(impulse_vector: Vector2) -> void:
	if unit_owner:
		unit_owner.velocity += impulse_vector
		unit_owner.move_and_slide()
		_update_terrain_state()
