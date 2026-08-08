# File: res://data/resources/modifiers/modifier_data.gd
class_name ModifierData extends Resource

## MODIFIER BLUEPRINT
## Defines a data-driven alteration to a unit's capabilities.

enum StatType {
	PHYSICAL_ATTACK,
	PHYSICAL_DEFENSE,
	MAX_HEALTH,
	MAX_MANA,
	MOVEMENT_SPEED,
	ACTION_POINTS,
	RANGE
}

enum ModifierType {
	FLAT_ADD,
	MULTIPLY,
	OVERRIDE
}

@export var modifier_name: String = "Base Modifier"
@export var target_stat: StatType = StatType.PHYSICAL_ATTACK
@export var mod_type: ModifierType = ModifierType.FLAT_ADD

## The value applied. 
## For FLAT_ADD: +5 or -5. 
## For MULTIPLY: 1.5 (+50%) or 0.5 (-50%).
## For OVERRIDE: 1 (Forces stat to exactly 1).
@export var value: float = 0.0

## How many Execution phases this lasts. -1 means infinite/conditional.
@export var duration_ticks: int = -1