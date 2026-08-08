# File: res://data/resources/actions/action_wait.gd
class_name ActionWait extends ActionData

## DEFENSIVE ACTION
## The unit holds its ground and ends its turn.

func _init() -> void:
	execution_phase = ExecutionPhase.DEFENSIVE
	target_required = false

func execute(unit: Node, _target_pos: Vector3i, _blackboard: Dictionary) -> void:
	print("COMBAT LOG: %s holds their ground and waits." % unit.name)