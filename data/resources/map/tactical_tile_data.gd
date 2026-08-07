class_name TacticalTileData extends Resource

## Defines the simulation rules for a single grid coordinate.
## This has no visual data; it only dictates tactical math.

@export var tile_name: String = "Ground"
@export var is_walkable: bool = true
@export var blocks_vision: bool = false

## If true, this tile allows units below to see units here, but blocks units
## from seeing through it horizontally.
@export var blocks_vision_from_above: bool = false

@export_category("Verticality")
## If true, this tile connects to a walkable tile at z + 1
@export var is_stairs: bool = false
@export var movement_cost: float = 1.0
