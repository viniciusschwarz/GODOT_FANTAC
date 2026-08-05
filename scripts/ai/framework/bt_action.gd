class_name BTAction
extends BTNode
## Base class for leaf nodes that perform actions.
## In this engine, actions typically queue commands for the PhaseManager
## during the Planning Phase rather than executing them instantly.

## The string name of the action command to queue (e.g., "move", "attack").
@export var action_name: String = ""

func tick(unit: Node, blackboard: Dictionary) -> State:
	# Implement specific action logic in subclasses.
	# Example:
	# unit.get_node("AIComponent").queue_action(action_name, target)
	# return State.SUCCESS

	return State.FAILURE
