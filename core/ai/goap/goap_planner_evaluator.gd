class_name GoapPlannerEvaluator
extends RefCounted

class GoapNode extends RefCounted:
	var state: Dictionary
	var parent: GoapNode
	var action: GoapActionDefinition
	var g_cost: int = 0
	var h_cost: int = 0

	func f_cost() -> int:
		return g_cost + h_cost

static func plan(current_state: Dictionary, goal_state: Dictionary, available_actions: Array[GoapActionDefinition]) -> Array[GoapActionDefinition]:
	var open_set: Array[GoapNode] = []
	var closed_set: Array[Dictionary] = [] # List of states already evaluated to avoid loops

	var start_node = GoapNode.new()
	start_node.state = current_state.duplicate(true)
	start_node.h_cost = _calculate_h_cost(start_node.state, goal_state)
	open_set.append(start_node)

	while open_set.size() > 0:
		# Find the node with the lowest f_cost
		var current_node: GoapNode = open_set[0]
		var current_index: int = 0
		for i in range(1, open_set.size()):
			if open_set[i].f_cost() < current_node.f_cost():
				current_node = open_set[i]
				current_index = i

		open_set.remove_at(current_index)
		closed_set.append(current_node.state)

		# Check if the current state satisfies all goal conditions
		if _state_satisfies_goal(current_node.state, goal_state):
			return _reconstruct_path(current_node)

		# Find valid actions that can transition from the current state
		for action in available_actions:
			if _action_is_valid(current_node.state, action):
				var next_state = current_node.state.duplicate(true)
				_apply_action_effects(next_state, action)

				# Skip if we already evaluated this state
				if _is_state_in_closed_set(next_state, closed_set):
					continue

				var neighbor = GoapNode.new()
				neighbor.state = next_state
				neighbor.parent = current_node
				neighbor.action = action
				neighbor.g_cost = current_node.g_cost + action.base_cost
				neighbor.h_cost = _calculate_h_cost(next_state, goal_state)

				# Check if this state is already in open_set with a lower g_cost
				var in_open_set_with_lower_cost = false
				for open_node in open_set:
					if _states_are_equal(open_node.state, next_state) and open_node.g_cost <= neighbor.g_cost:
						in_open_set_with_lower_cost = true
						break

				if not in_open_set_with_lower_cost:
					open_set.append(neighbor)

	return []

static func _calculate_h_cost(state: Dictionary, goal_state: Dictionary) -> int:
	var unsatisfied_count = 0
	for key in goal_state:
		if not state.has(key) or state[key] != goal_state[key]:
			unsatisfied_count += 1
	return unsatisfied_count

static func _state_satisfies_goal(state: Dictionary, goal_state: Dictionary) -> bool:
	return _calculate_h_cost(state, goal_state) == 0

static func _action_is_valid(state: Dictionary, action: GoapActionDefinition) -> bool:
	for key in action.preconditions:
		if not state.has(key) or state[key] != action.preconditions[key]:
			return false
	return true

static func _apply_action_effects(state: Dictionary, action: GoapActionDefinition) -> void:
	for key in action.effects:
		state[key] = action.effects[key]

static func _states_are_equal(state1: Dictionary, state2: Dictionary) -> bool:
	if state1.size() != state2.size():
		return false
	for key in state1:
		if not state2.has(key) or state1[key] != state2[key]:
			return false
	return true

static func _is_state_in_closed_set(state: Dictionary, closed_set: Array[Dictionary]) -> bool:
	for closed_state in closed_set:
		if _states_are_equal(state, closed_state):
			return true
	return false

static func _reconstruct_path(end_node: GoapNode) -> Array[GoapActionDefinition]:
	var path: Array[GoapActionDefinition] = []
	var current = end_node
	while current.parent != null:
		path.append(current.action)
		current = current.parent
	path.reverse()
	return path
