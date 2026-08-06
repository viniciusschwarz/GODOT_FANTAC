class_name HealthComponent
extends Node
## Tracks current/max health and processes incoming damage.

var current_health: int
var max_health: int
var is_dead: bool = false

var current_cover_bonus: float = 0.0

var unit_owner: Node

func _ready() -> void:
	unit_owner = get_parent()

func initialize(health: int) -> void:
	max_health = health
	current_health = health
	is_dead = false
	SignalBus.unit_health_changed.emit(unit_owner, current_health, max_health, 0)

func take_damage(amount: int) -> void:
	if is_dead:
		return

	# Apply cover bonus mitigation (e.g. 0.2 cover bonus = 20% damage reduction)
	var mitigated_amount = int(amount * (1.0 - current_cover_bonus))
	mitigated_amount = max(1, mitigated_amount) if amount > 0 else 0

	current_health -= mitigated_amount
	current_health = max(0, current_health)

	SignalBus.unit_health_changed.emit(unit_owner, current_health, max_health, -mitigated_amount)

	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	SignalBus.unit_died.emit(unit_owner)
	if has_node("/root/AIManager"):
		get_node("/root/AIManager").unregister_unit(unit_owner)
