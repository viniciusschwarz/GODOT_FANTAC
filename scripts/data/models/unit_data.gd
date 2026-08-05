class_name UnitData
extends Resource
## Defines the core stats and equipment for a specific unit type.

@export var unit_name: String = "Unnamed Unit"

@export_group("Base Stats")
@export var max_health: int = 100
@export var base_movement_speed: float = 3.0
@export var base_morale: int = 100

@export_group("Equipment")
@export var weapon: WeaponData
@export var armor: ArmorData
@export var shield: ArmorData # Optional, usually type SHIELD

@export_group("AI Behavior")
## Path to the behavior tree preset resource (.tres)
@export var behavior_tree_preset: Resource
