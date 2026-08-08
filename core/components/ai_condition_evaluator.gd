# File: res://core/components/ai_condition_evaluator.gd
class_name AIConditionEvaluator extends Node

## AI BEHAVIOR PARSER
## Evaluates the tree and returns an ActionIntent for the CombatManager.

var _tree_data: AITreeData
var _unit: Node

func initialize(tree: AITreeData, unit: Node) -> void:
	_tree_data = tree
	_unit = unit

## Evaluates the AI tree and returns the chosen action intent.
## @param blackboard: The combat context (all units, map data, etc.)
## @return ActionIntent: The chosen action, or null if no condition is met.
func get_intended_action(blackboard: Dictionary) -> ActionIntent:
	if not _tree_data or _tree_data.rules.is_empty():
		return null
		
	for rule: AIRuleData in _tree_data.rules:
		# EXTERNAL ACCESS NOTE: Querying the ConditionData Resource
		if rule.condition and rule.condition.evaluate(_unit, blackboard):
			# If true, lock in the action.
			# For testing purposes, we default to the unit's current coordinate as the target.
			# (In Phase 12/13, the condition will output the exact target coordinate to the blackboard).
			var target_coord: Vector3i = blackboard.get("default_target_coord", Vector3i.ZERO)
			
			return ActionIntent.new(rule.action, _unit, target_coord)
			
	return null