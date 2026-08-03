extends Resource
class_name UnitStats
# 'class_name' registers this script as a new type of Resource in Godot!

# ==========================================
# UNIT DATA TEMPLATE
# ==========================================
@export var unit_name: String = "Unknown Unit"
@export var max_hp: int = 10
@export var attack_power: int = 3
@export var movement_range: int = 2

# We also store the visual token here!
@export var texture: Texture2D
