class_name BTNode
extends Resource
## Base class for all Behavior Tree nodes.

enum State {
	SUCCESS,
	FAILURE,
	RUNNING
}

## Evaluates the node and returns its current State.
## Must be overridden by subclasses.
func tick(unit: Node, blackboard: Dictionary) -> State:
	return State.FAILURE
