class_name MapObjectData
extends Resource
## Defines the interaction properties of dynamic map objects (trees, rocks, barrels).

@export var object_name: String = "Unnamed Object"

## Does this object physically block movement?
@export var blocks_pathing: bool = false

## At what Z-level does this object block Line of Sight? (0 = doesn't block)
@export var los_block_height: int = 0

## Penalty applied when stepping onto the object's tile.
@export var movement_cost: float = 1.0

## Damage mitigation granted to units taking cover behind/inside this object.
@export var cover_bonus: float = 0.0
