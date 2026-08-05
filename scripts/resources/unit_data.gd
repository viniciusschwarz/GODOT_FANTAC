class_name UnitData
extends Resource
## A data container for unit base stats loaded from JSON.

@export var id: String = ""
@export var unit_name: String = ""
@export var max_hp: int = 1
@export var speed: int = 1
@export var default_weapon: String = ""
@export var ai_preset: String = ""

## Initialize with a dictionary parsed from JSON
func setup_from_dict(unit_id: String, data: Dictionary) -> void:
	id = unit_id
	unit_name = data.get("name", "Unknown Unit")
	max_hp = data.get("max_hp", 1)
	speed = data.get("speed", 1)
	default_weapon = data.get("default_weapon", "")
	ai_preset = data.get("ai_preset", "default")
