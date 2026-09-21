class_name GoapPlan
extends RefCounted

enum Status {
	SOLVED = 0,
	UNSOLVABLE = 1,
	BUDGET_EXHAUSTED = 2,
	DEPTH_LIMIT_REACHED = 3
}

var status: int = Status.UNSOLVABLE
var target_goal: GoapGoal = null
var bindings: Array[GoapActionBinding] = []
var total_cost: float = 0.0
var nodes_evaluated: int = 0
var planning_time_usec: int = 0

func is_valid() -> bool:
	return status == Status.SOLVED and not bindings.is_empty()

func get_step_count() -> int:
	return bindings.size()
