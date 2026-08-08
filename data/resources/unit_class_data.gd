# File: res://data/resources/unit_class_data.gd
class_name UnitClassData extends Resource

## THE FACTORY BLUEPRINT
## Defines an archetype's base capabilities, visual token, and procedural variance.

@export var class_name_str: String = "Standard Recruit"
## The X,Y coordinate mapping to the 4x4 unit_tokens.png grid
@export var sprite_atlas_coord: Vector2i = Vector2i(0, 0) 

@export_category("Base Stats")
@export var base_health: int = 100
@export var base_mana: int = 50
@export var base_ap: int = 10
@export var base_movement: int = 4
@export var physical_attack: int = 15
@export var physical_defense: int = 10

@export_category("Procedural Variance")
## Maximum percentage variance (0.0 to 1.0). e.g., 0.1 means +/- 10%
@export var stat_variance_margin: float = 0.1 

## Generates a unique UnitStats resource in-memory based on this blueprint.
func generate_unique_stats() -> UnitStats:
	# EXTERNAL ACCESS NOTE: Instantiating a Resource defined in Phase 1
	var new_stats: UnitStats = UnitStats.new()
	new_stats.unit_name = class_name_str
	
	new_stats.max_health = _apply_variance(base_health)
	new_stats.max_mana = _apply_variance(base_mana)
	new_stats.max_ap = base_ap
	new_stats.base_movement_speed = base_movement
	new_stats.physical_attack = _apply_variance(physical_attack)
	new_stats.physical_defense = _apply_variance(physical_defense)
	
	return new_stats

func _apply_variance(base_val: int) -> int:
	if base_val == 0:
		return 0
	var variance: float = float(base_val) * stat_variance_margin
	var offset: float = randf_range(-variance, variance)
	return clampi(base_val + int(offset), 1, 9999)