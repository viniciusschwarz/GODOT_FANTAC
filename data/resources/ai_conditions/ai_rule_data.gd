class_name AIRuleData extends Resource

## A single tactical directive configured by the player.
## Matches a specific tactical condition to an executable action.

@export var rule_name: String = "New Rule"

## EXTERNAL DATA DEPENDENCY: ConditionData from Phase 1
@export var condition: ConditionData

## EXTERNAL DATA DEPENDENCY: ActionData from Phase 1
@export var action: ActionData
