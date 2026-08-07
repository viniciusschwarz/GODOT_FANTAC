class_name HealthComponent extends Node

## Tracks vitality state and processes incoming damage.

var current_health: int = 0
var max_health: int = 0
var _parent_id: StringName

## Injected by the Unit container.
func initialize(in_max_health: int, parent_id: StringName) -> void:
	max_health = in_max_health
	current_health = max_health
	_parent_id = parent_id

## Applies damage and broadcasts the result.
## @param amount: The raw damage integer after armor calculations.
func take_damage(amount: int) -> void:
	if current_health <= 0:
		return # Already dead

	current_health -= amount
	current_health = maxi(current_health, 0)

	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.unit_took_damage.emit(_parent_id, amount, current_health)

	if current_health == 0:
		_die()

func _die() -> void:
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.unit_died.emit(_parent_id)
