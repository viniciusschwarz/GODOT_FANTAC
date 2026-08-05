class_name WeaponData
extends Resource
## Defines the properties of a weapon used by a unit.

enum DamageType {
	SLASHING,
	PIERCING,
	BLUNT,
	MAGIC
}

@export var weapon_name: String = "Unnamed Weapon"
@export var damage_type: DamageType = DamageType.SLASHING

## Base damage dealt by the weapon.
@export var base_damage: int = 10

## The range of the weapon in grid tiles.
@export var range: int = 1

## Modifier for armor penetration or bypassing specific armor types.
@export var armor_penetration: int = 0

## The amount of knockback force applied on hit.
@export var knockback_force: float = 0.0
