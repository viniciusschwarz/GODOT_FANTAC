# File: res://data/resources/ai_conditions/condition_always_true.gd
class_name ConditionAlwaysTrue extends ConditionData

## DUMMY CONDITION FOR TESTING
## Always evaluates to true.

func evaluate(_unit: Node, _blackboard: Dictionary) -> bool:
	return true
