# File: res://data/resources/map/building_blueprint_data.gd
class_name BuildingBlueprintData extends Resource

## PATTERN-BASED BUILDING STAMP
## Defines a multi-floor structure using ASCII-style character mapping.

@export var blueprint_name: String = "Base Blueprint"

## Each element in the array represents a Z-level (Floor 0, Floor 1, etc.).
## Inside the PackedStringArray, each string is a Y-row, and each character is an X-column.
@export var z_layers: Array[PackedStringArray] = []