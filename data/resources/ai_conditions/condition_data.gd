# File: res://data/resources/ai_conditions/condition_data.gd
class_name ConditionData extends Resource

## Base class for all AI Tactics Board Conditions.

@export var condition_name: String = "Base Condition"

## Evaluates the tactical situation. 
## Prefixed parameters with '_' to satisfy strict GDScript compiler warnings.
func evaluate(_unit: Node, _blackboard: Dictionary) -> bool:
	# EXTERNAL ACCESS NOTE: Child classes will query the MapManager and LOSComponent here.
	push_warning("evaluate() called on base ConditionData. Must be overridden.")
	return false