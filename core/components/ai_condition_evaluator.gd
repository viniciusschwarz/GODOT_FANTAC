class_name AIConditionEvaluator extends Node

## Reads the unit's AITreeData resource and evaluates tactical conditions.
## Returns the highest-priority valid action to the simulation engine.

var _ai_tree: AITreeData
var _parent_unit: Node

## Injected by the Unit container upon spawning.
## @param tree_data: The specific AI strategy assigned to this unit by the player.
## @param parent: The unit node this AI belongs to (needed for context).
func initialize(tree_data: AITreeData, parent: Node) -> void:
	if not tree_data:
		push_warning("AIConditionEvaluator initialized without AITreeData. Unit will be inert.")

	_ai_tree = tree_data
	_parent_unit = parent
	print("AIConditionEvaluator initialized for %s" % _parent_unit.name)

## Called by the simulation (e.g., TurnManager) during the Execution Phase.
## Parses the rules top-to-bottom and returns the first valid action.
## @param blackboard: A dictionary containing battlefield context (enemies, map grid, etc.)
## @return ActionData: The action the unit intends to execute.
func determine_next_action(blackboard: Dictionary) -> ActionData:
	if not _ai_tree:
		return null

	# 1. Iterate through the priority list of rules
	for rule: AIRuleData in _ai_tree.rules:
		# Safety check for unconfigured rules
		if not rule.condition or not rule.action:
			continue

		# 2. Evaluate the condition (EXTERNAL ACCESS: Calls Resource logic)
		# We pass the parent unit and the blackboard so the condition can analyze the board state
		var is_condition_met: bool = rule.condition.evaluate(_parent_unit, blackboard)

		if is_condition_met:
			print("AI Evaluator: Condition '%s' met. Executing '%s'." % [rule.condition.condition_name, rule.action.action_name])
			return rule.action

	# 3. If no conditions match, return the default behavior
	if _ai_tree.fallback_action:
		print("AI Evaluator: No conditions met. Executing Fallback Action.")
		return _ai_tree.fallback_action

	return null
