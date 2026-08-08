# File: res://data/models/action_intent.gd
class_name ActionIntent extends RefCounted

## DATA CONTAINER FOR LOCKED ACTIONS
## Holds a unit's decision so the CombatManager can sort and execute it later.

var action: ActionData
var executor: Node
var target_coord: Vector3i

func _init(p_action: ActionData, p_executor: Node, p_target_coord: Vector3i) -> void:
	action = p_action
	executor = p_executor
	target_coord = p_target_coord