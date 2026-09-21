class_name GoapGoalArbitrator
extends RefCounted

var hysteresis_margin: float = 0.1

func select_best_goal(goals: Array[GoapGoal], snapshot: GoapStateSnapshot, context: Dictionary, current_active_goal: GoapGoal = null) -> GoapGoal:
	var active_util: float = 0.0
	var has_active_util: bool = false

	if current_active_goal != null:
		if not current_active_goal.is_satisfied(snapshot, context):
			active_util = current_active_goal.calculate_utility(snapshot, context)
			has_active_util = true

	var best_goal: GoapGoal = null
	var best_util: float = -INF

	for goal in goals:
		if goal.is_satisfied(snapshot, context):
			continue

		var util = goal.calculate_utility(snapshot, context)
		if util > best_util:
			best_util = util
			best_goal = goal

	if has_active_util:
		if best_util > active_util + hysteresis_margin:
			return best_goal
		else:
			return current_active_goal
	else:
		return best_goal
