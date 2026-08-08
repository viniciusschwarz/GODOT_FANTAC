# File: res://data/resources/actions/action_data.gd
class_name ActionData extends Resource

## Base class for all executable actions in the WeGo system.

enum ExecutionPhase {
	RANGED_AND_MAGIC = 0,
	MOVEMENT = 1,
	MELEE = 2,
	DEFENSIVE = 3
}

@export var action_name: String = "Base Action"
@export var ap_cost: int = 2
@export var execution_phase: ExecutionPhase = ExecutionPhase.MELEE

@export_category("Targeting Parameters")
@export var target_required: bool = true
@export var action_range: int = 1 
@export var is_aoe: bool = false
@export var aoe_radius: int = 0

## Executes the physical action in the simulation.
func execute(_unit: Node, _target_pos: Vector3i, _blackboard: Dictionary) -> void:
	push_warning("execute() called on base ActionData. Must be overridden.")