class_name UnitStats extends Resource

## Defines the immutable base attributes of a unit.
## Does not contain active state (like current HP), only maximums and definitions.

@export var unit_name: String = "Unknown Conscript"
@export var max_health: int = 100
@export var max_mana: int = 50
@export var max_ap: int = 10 ## Action Points available per Execution Phase
@export var base_movement_speed: int = 3 ## Grid tiles per AP

@export_category("Combat Attributes")
@export var physical_attack: int = 10
@export var magic_attack: int = 5
@export var physical_defense: int = 5
@export var magic_defense: int = 5

@export_category("Tactical Properties")
## If true, this unit can bypass ground obstacles (ignores Z-level pathing restrictions)
@export var is_flying: bool = false
@export var base_vision_range: int = 5
