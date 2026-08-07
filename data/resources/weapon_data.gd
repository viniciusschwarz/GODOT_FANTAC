class_name WeaponData extends Resource

## Defines weapon statistics and the tactical actions they unlock.
## External Data Dependency: Will reference ActionData resources.

@export var weapon_name: String = "Standard Sword"
@export var base_damage: int = 15

@export_category("Range & Verticality")
@export var base_range: int = 1 ## 1 is melee
## Multiplier applied when calculating Line of Sight from a higher Z-level
@export var height_range_multiplier: float = 1.0

@export_category("Granted Abilities")
## Actions unlocked in the Tactics Board when equipped (e.g., "Thrust", "Block")
## EXTERNAL DATA: Array of ActionData Resources
@export var granted_actions: Array[ActionData] = []
