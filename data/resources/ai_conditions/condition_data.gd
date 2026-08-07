class_name ConditionData extends Resource

## Base class for all AI Tactics Board Conditions.
## Player logic is built by chaining these (e.g., IF [Condition] -> THEN [Action])

@export var condition_name: String = "Base Condition"

## Evaluates the tactical situation. Must be overridden by child classes.
## @param unit: The Node executing the logic.
## @param blackboard: A Dictionary storing temporary state/context (e.g., current targets).
## @return bool: True if the condition is met.
func evaluate(unit: Node, blackboard: Dictionary) -> bool:
	# EXTERNAL ACCESS NOTE: Child classes will query the MapManager and LOSComponent here.
	push_warning("evaluate() called on base ConditionData. Must be overridden.")
	return false
