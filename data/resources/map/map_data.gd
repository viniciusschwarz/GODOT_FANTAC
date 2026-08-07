class_name MapData extends Resource

## The complete mathematical blueprint of a battlefield.
## Can be generated procedurally or saved in the editor.

@export var map_name: String = "Debug Map"
@export var width: int = 20
@export var height: int = 20
@export var max_z_levels: int = 3

## Godot 4 does not yet support fully typed dictionaries in exports.
## Structure: Dictionary[Vector3i, TacticalTileData]
@export var grid_tiles: Dictionary = {}

## Helper to safely check if a coordinate exists in our mathematical grid.
func has_tile(coord: Vector3i) -> bool:
	return grid_tiles.has(coord)

## Helper to fetch tile data, returns null if empty space.
func get_tile(coord: Vector3i) -> TacticalTileData:
	return grid_tiles.get(coord, null)
