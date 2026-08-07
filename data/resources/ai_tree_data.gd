class_name AITreeData extends Resource

## The complete "Brain" of a unit.
## Configured by the player in the Tactics Board UI.

@export var tree_name: String = "Default Defensive Tree"

## A prioritized array of rules. Evaluated from index 0 downwards.
## EXTERNAL DATA DEPENDENCY: Array of AIRuleData resources.
@export var rules: Array[AIRuleData] = []

## Fallback action if absolutely no conditions are met (e.g., Idle/Defend)
## EXTERNAL DATA DEPENDENCY: ActionData from Phase 1
@export var fallback_action: ActionData
