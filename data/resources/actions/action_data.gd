class_name ActionData extends Resource

## Base class for all executable actions in the WeGo system.
## Includes Attacks, Movement, Spellcasting, and Defensive stances.

@export var action_name: String = "Base Action"
@export var ap_cost: int = 2

@export_category("Targeting Parameters")
@export var target_required: bool = true
@export var action_range: int = 1 ## 1 is melee, >1 is ranged
@export var is_aoe: bool = false
@export var aoe_radius: int = 0

## Executes the physical action in the simulation. Must be overridden.
## @param unit: The unit performing the action.
## @param target_pos: The Vector3i grid position being targeted.
## @param blackboard: Context dictionary.
func execute(unit: Node, target_pos: Vector3i, blackboard: Dictionary) -> void:
	# EXTERNAL ACCESS NOTE: Child classes will interact with the EventBus and CombatComponent here.
	push_warning("execute() called on base ActionData. Must be overridden.")
	pass
