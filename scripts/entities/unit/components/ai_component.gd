class_name AIComponent
extends Node
## Holds the unit's active Behavior Tree instance and converts AI decisions
## into executable command queues for the PhaseManager.

var behavior_tree: BTNode
var unit_owner: Node
var blackboard: Dictionary = {}

## The queued action decided during the Planning Phase
var queued_action: Dictionary = {}

func _ready() -> void:
	pass

## Initializes the component with a specific behavior preset.
func initialize(unit: Node, bt_preset: Resource) -> void:
	unit_owner = unit
	if bt_preset is BTNode:
		behavior_tree = bt_preset
	else:
		push_warning("Invalid Behavior Tree preset provided to AIComponent.")

	# Register with AIManager to be evaluated during planning
	if AIManager:
		AIManager.register_unit(unit_owner)

## Called by AIManager during the Planning Phase.
func evaluate_behavior() -> void:
	if not behavior_tree or not is_instance_valid(unit_owner):
		return

	# Update blackboard with current state if needed
	blackboard["unit"] = unit_owner

	var _state = behavior_tree.tick(unit_owner, blackboard)

## Queues an action to be executed during the Execution Phase.
## Typically called by BTAction nodes.
func queue_action(action_name: String, params: Dictionary = {}) -> void:
	queued_action = {
		"name": action_name,
		"params": params
	}

## Called by PhaseManager when the Execution Phase begins.
func execute_queued_action() -> void:
	if queued_action.is_empty():
		# If no action, instantly signal completion
		SignalBus.unit_action_finished.emit(unit_owner)
		return

	# Placeholder for delegating actions to specific components.
	# e.g., if action is "move", tell MovementComponent to go.
	# When MovementComponent reaches destination, it emits unit_action_finished.

	# For now, simulate instant completion
	print("Unit ", unit_owner.name, " executing: ", queued_action.name)
	queued_action.clear()
	SignalBus.unit_action_finished.emit(unit_owner)
