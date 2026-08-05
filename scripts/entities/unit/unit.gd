class_name Unit
extends CharacterBody2D
## Lightweight, team-agnostic root container node.
## Appearance, stats, and behavior are loaded dynamically from UnitData.

@export var data: UnitData

@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var ai_component: AIComponent = $AIComponent

var team_id: int = 0
var facing_vector: Vector2 = Vector2.DOWN

func _ready() -> void:
	if data:
		initialize(data)

	# Listen for the WEGO execution phase to start our queued action
	SignalBus.connect("wego_phase_started", _on_phase_started)

func initialize(unit_data: UnitData, team: int = 0) -> void:
	data = unit_data
	team_id = team
	name = data.unit_name

	# Initialize components
	if health_component:
		health_component.initialize(data.max_health)
	if movement_component:
		movement_component.initialize(data.base_movement_speed)
	if ai_component and data.behavior_tree_preset:
		ai_component.initialize(data.behavior_tree_preset)

func _on_phase_started(phase_name: String) -> void:
	if phase_name == "execution":
		if ai_component:
			ai_component.execute_queued_action()
		else:
			# Fallback if no AI component
			SignalBus.unit_action_finished.emit(self)

func set_facing(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		facing_vector = direction.normalized()
		# Update sprite flip or animation here later
