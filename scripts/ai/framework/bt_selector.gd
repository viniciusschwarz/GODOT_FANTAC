class_name BTSelector
extends BTNode
## A composite node that ticks its children in order.
## Returns SUCCESS if any child returns SUCCESS.
## Returns RUNNING if a child returns RUNNING.
## Returns FAILURE only if all children return FAILURE.

@export var children: Array[BTNode] = []

func tick(unit: Node, blackboard: Dictionary) -> State:
	for child: BTNode in children:
		if not child:
			continue

		var result: State = child.tick(unit, blackboard)

		if result == State.SUCCESS:
			return State.SUCCESS
		elif result == State.RUNNING:
			return State.RUNNING

	return State.FAILURE
