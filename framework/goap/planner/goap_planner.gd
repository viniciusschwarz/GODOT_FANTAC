class_name GoapPlanner
extends RefCounted

var max_nodes_evaluated: int = 500
var max_depth: int = 16

func plan(
	initial_snapshot: GoapStateSnapshot,
	goal: GoapGoal,
	available_actions: Array[GoapAction],
	context: Dictionary = {}
) -> GoapPlan:
	var start_time: int = Time.get_ticks_usec()
	var new_plan := GoapPlan.new()
	new_plan.target_goal = goal

	if goal.is_satisfied(initial_snapshot, context):
		new_plan.status = GoapPlan.Status.SOLVED
		new_plan.bindings = []
		new_plan.total_cost = 0.0
		new_plan.planning_time_usec = Time.get_ticks_usec() - start_time
		new_plan.nodes_evaluated = 0
		return new_plan

	var start_node := GoapSearchNode.new()
	start_node.snapshot = initial_snapshot.duplicate_snapshot()
	start_node.g_cost = 0.0
	start_node.h_cost = _calculate_heuristic(start_node.snapshot, goal, context)
	start_node.depth = 0

	var open_set: Array[GoapSearchNode] = [start_node]
	var closed_set: Dictionary = {}
	var nodes_evaluated: int = 0
	var depth_limit_hit: bool = false

	while not open_set.is_empty():
		if nodes_evaluated >= max_nodes_evaluated:
			new_plan.status = GoapPlan.Status.BUDGET_EXHAUSTED
			new_plan.planning_time_usec = Time.get_ticks_usec() - start_time
			new_plan.nodes_evaluated = nodes_evaluated
			return new_plan

		open_set.sort_custom(func(a: GoapSearchNode, b: GoapSearchNode) -> bool:
			if is_equal_approx(a.f_cost(), b.f_cost()):
				return a.h_cost < b.h_cost
			return a.f_cost() < b.f_cost()
		)

		var current: GoapSearchNode = open_set.pop_front()
		nodes_evaluated += 1

		if goal.is_satisfied(current.snapshot, context):
			var curr: GoapSearchNode = current
			var path_bindings: Array[GoapActionBinding] = []
			while curr != null and curr.binding != null:
				path_bindings.push_front(curr.binding)
				curr = curr.parent

			new_plan.bindings = path_bindings
			new_plan.total_cost = current.g_cost
			new_plan.status = GoapPlan.Status.SOLVED
			new_plan.planning_time_usec = Time.get_ticks_usec() - start_time
			new_plan.nodes_evaluated = nodes_evaluated
			return new_plan

		var hash: String = current.snapshot.compute_hash()
		if closed_set.has(hash) and closed_set[hash] <= current.g_cost:
			continue

		closed_set[hash] = current.g_cost

		if current.depth >= max_depth:
			depth_limit_hit = true
			continue

		for action in available_actions:
			var candidate_bindings = action.generate_bindings(current.snapshot, context)
			for binding in candidate_bindings:
				var preconds_met: bool = true
				for cond in action.preconditions:
					if not cond.evaluates(current.snapshot, context):
						preconds_met = false
						break
				if not preconds_met:
					continue

				if not action.check_procedural_precondition(current.snapshot, binding, context):
					continue

				var child_snapshot = current.snapshot.duplicate_snapshot()
				for effect in action.effects:
					effect.apply_to(child_snapshot)

				var child_hash: String = child_snapshot.compute_hash()
				var action_cost = action.calculate_cost(current.snapshot, binding, context)
				var tentative_g_cost = current.g_cost + action_cost

				if closed_set.has(child_hash) and closed_set[child_hash] <= tentative_g_cost:
					continue

				var child := GoapSearchNode.new()
				child.snapshot = child_snapshot
				child.parent = current
				child.binding = binding
				child.g_cost = tentative_g_cost
				child.h_cost = _calculate_heuristic(child_snapshot, goal, context)
				child.depth = current.depth + 1

				open_set.append(child)

	if depth_limit_hit:
		new_plan.status = GoapPlan.Status.DEPTH_LIMIT_REACHED
	else:
		new_plan.status = GoapPlan.Status.UNSOLVABLE

	new_plan.planning_time_usec = Time.get_ticks_usec() - start_time
	new_plan.nodes_evaluated = nodes_evaluated
	return new_plan

func _calculate_heuristic(snapshot: GoapStateSnapshot, goal: GoapGoal, context: Dictionary) -> float:
	var unsatisfied_count: float = 0.0
	for cond in goal.desired_conditions:
		if not cond.evaluates(snapshot, context):
			unsatisfied_count += 1.0
	return unsatisfied_count
