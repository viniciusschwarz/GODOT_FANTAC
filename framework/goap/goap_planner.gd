class_name GoapPlanner
extends RefCounted

class PlanNode extends RefCounted:
	var state: Dictionary
	var parent: PlanNode
	var action: GoapAction
	var g_cost: int = 0
	var h_cost: int = 0

	func f_cost() -> int:
		return g_cost + h_cost

static func _hash_state(state: Dictionary) -> String:
	var keys: Array = state.keys()
	keys.sort()
	var tokens: PackedStringArray = []
	for k in keys:
		tokens.append("%s=%s" % [str(k), str(state[k])])
	return ";".join(tokens)

## Pure function: computes optimal action path from current_state to goal_state.
## Returns Array[GoapAction] ordered chronologically (index 0 is first to execute).
## Returns an empty array if unsolvable.
static func plan(
	current_state: Dictionary,
	goal_state: Dictionary,
	available_actions: Array[GoapAction],
	blackboard_context: Dictionary = {}
) -> Array[GoapAction]:

	var start_node := PlanNode.new()
	start_node.state = current_state.duplicate()
	start_node.g_cost = 0
	start_node.h_cost = _calculate_h_cost(start_node.state, goal_state)

	var open_set: Array[PlanNode] = [start_node]
	var closed_set: Dictionary = {} # Set of hashed states to prevent infinite loops

	while open_set.size() > 0:
		# 2. Iterate lowest f_cost nodes
		open_set.sort_custom(func(a, b): return a.f_cost() < b.f_cost())
		var current := open_set.pop_front() as PlanNode

		# 4. If child satisfies goal_state, reconstruct path, reverse, and return
		if _matches_goal(current.state, goal_state):
			return _reconstruct_path(current)

		var state_hash := _hash_state(current.state)
		if closed_set.has(state_hash):
			continue
		closed_set[state_hash] = true

		# 3. For each action whose static preconditions match the node state:
		for action in available_actions:
			if not _matches_preconditions(current.state, action.preconditions):
				continue

			if not action.check_procedural_precondition(blackboard_context):
				continue

			var new_state := current.state.duplicate()
			for k in action.effects:
				new_state[k] = action.effects[k]

			var child_hash := _hash_state(new_state)
			if closed_set.has(child_hash):
				continue

			var child := PlanNode.new()
			child.state = new_state
			child.parent = current
			child.action = action
			child.g_cost = current.g_cost + action.get_cost(blackboard_context)
			child.h_cost = _calculate_h_cost(new_state, goal_state)

			open_set.append(child)

	return []

static func _matches_preconditions(state: Dictionary, preconditions: Dictionary) -> bool:
	for k in preconditions:
		if not state.has(k) or state[k] != preconditions[k]:
			return false
	return true

static func _matches_goal(state: Dictionary, goal_state: Dictionary) -> bool:
	for k in goal_state:
		if not state.has(k) or state[k] != goal_state[k]:
			return false
	return true

static func _calculate_h_cost(state: Dictionary, goal_state: Dictionary) -> int:
	var h := 0
	for k in goal_state:
		if not state.has(k) or state[k] != goal_state[k]:
			h += 1
	return h

static func _reconstruct_path(node: PlanNode) -> Array[GoapAction]:
	var path: Array[GoapAction] = []
	var current := node
	while current.parent != null:
		path.append(current.action)
		current = current.parent
	path.reverse()
	return path
