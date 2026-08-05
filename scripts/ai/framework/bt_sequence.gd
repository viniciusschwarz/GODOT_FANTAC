class_name BTSequence
extends BTNode
## A composite node that ticks its children in order.
## Returns FAILURE if any child returns FAILURE.
## Returns RUNNING if a child returns RUNNING.
## Returns SUCCESS only if all children return SUCCESS.

@export var children: Array[BTNode] = []

func tick(unit: Node, blackboard: Dictionary) -> State:
	for child in children:
		if not child:
			continue

		var result: State = child.tick(unit, blackboard)

		if result == State.FAILURE:
			return State.FAILURE
		elif result == State.RUNNING:
			return State.RUNNING

	return State.SUCCESS
