class_name HealthComponent
extends Node
## Tracks current/max health and processes incoming damage.

var current_health: int
var max_health: int
var is_dead: bool = false

var unit_owner: Node

func _ready() -> void:
	unit_owner = get_parent()

## Initializes the health based on UnitData.
func initialize(health: int) -> void:
	max_health = health
	current_health = health
	is_dead = false
	SignalBus.unit_health_changed.emit(unit_owner, current_health, max_health, 0)

## Applies damage, considering armor mitigation (handled externally by CombatManager).
func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	current_health = max(0, current_health)

	SignalBus.unit_health_changed.emit(unit_owner, current_health, max_health, -amount)

	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	SignalBus.unit_died.emit(unit_owner)
	# Notify AIManager that this unit is out
	if has_node("/root/AIManager"):
		get_node("/root/AIManager").unregister_unit(unit_owner)
