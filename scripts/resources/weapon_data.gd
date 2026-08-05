class_name WeaponData
extends Resource
## A data container for weapon properties loaded from JSON.

@export var id: String = ""
@export var weapon_name: String = ""
@export var damage: int = 1
@export var range: int = 1
@export var type: String = "melee"

## Initialize with a dictionary parsed from JSON
func setup_from_dict(weapon_id: String, data: Dictionary) -> void:
	id = weapon_id
	weapon_name = data.get("name", "Unknown Weapon")
	damage = data.get("damage", 1)
	range = data.get("range", 1)
	type = data.get("type", "melee")
