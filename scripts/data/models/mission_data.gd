extends Resource
class_name MissionData
## Data model for a campaign mission.

@export var mission_id: String = ""
@export var mission_name: String = "New Mission"
@export_multiline var description: String = ""
@export var difficulty_rating: int = 1
@export var map_size: Vector2i = Vector2i(32, 32)
@export var biome_preset: Resource # Placeholder for future biome integration
@export var enemy_roster: Array[Dictionary] = [] # e.g. [{"unit_id": "goblin_melee", "count": 3}]
@export_enum("Rout_Enemy") var win_condition: String = "Rout_Enemy"
