class_name HealthComponent
extends Node
## Tracks current/max health and processes incoming damage.

var current_health: int
var max_health: int
var is_dead: bool = false

var current_cover_bonus: float = 0.0

var unit_owner: Node

func _ready() -> void:
	SignalBus.unit_cover_bonus_changed.connect(_on_unit_cover_bonus_changed)

func initialize(unit: Node, health: int) -> void:
	unit_owner = unit
	max_health = health
	current_health = health
	is_dead = false
	SignalBus.unit_health_changed.emit(unit_owner, current_health, max_health, 0)

func _on_unit_cover_bonus_changed(unit: Node, cover_bonus: float) -> void:
	if unit == unit_owner:
		current_cover_bonus = cover_bonus

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
	# The AIManager (or whatever handles units) will listen to the unit_died signal instead,
	# but as a fallback/for now, if AIManager autoload is present we can call it.
	if AIManager:
		AIManager.unregister_unit(unit_owner)
