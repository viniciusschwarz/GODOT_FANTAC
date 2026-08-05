class_name ArmorData
extends Resource
## Defines the physical properties of a piece of armor for a unit.

enum ArmorType {
	UNARMORED,
	LIGHT,
	HEAVY,
	SHIELD
}

@export var armor_name: String = "Unnamed Armor"
@export var armor_type: ArmorType = ArmorType.UNARMORED

## Flat damage reduction applied to incoming attacks.
@export var damage_reduction: int = 0

## Chance to completely block an attack (0.0 to 1.0). Primarily used by shields.
@export var block_chance: float = 0.0

## Penalty applied to unit movement speed.
@export var movement_penalty: float = 0.0
