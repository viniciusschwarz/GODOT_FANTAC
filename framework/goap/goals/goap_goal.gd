class_name GoapGoal
extends RefCounted

var goal_name: StringName
var base_priority: float = 1.0
var desired_conditions: Array[GoapCondition] = []

func _init(p_goal_name: StringName, p_base_priority: float = 1.0):
	goal_name = p_goal_name
	base_priority = p_base_priority

func add_condition(condition: GoapCondition) -> void:
	desired_conditions.append(condition)

func is_satisfied(snapshot: GoapStateSnapshot, context: Dictionary = {}) -> bool:
	for condition in desired_conditions:
		if not condition.evaluates(snapshot, context):
			return false
	return true

func calculate_utility(snapshot: GoapStateSnapshot, context: Dictionary = {}) -> float:
	return base_priority
