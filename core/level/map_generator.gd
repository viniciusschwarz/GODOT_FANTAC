# File: res://core/level/map_generator.gd
class_name MapGenerator extends RefCounted

## PROCEDURAL MAP BUILDER (UPDATED PHASE 14)
## Constructs MapData by stamping pre-defined BuildingBlueprintData resources.

# EXTERNAL ACCESS NOTE: Requires TacticalTileData templates to populate the grid.
var tile_templates: Dictionary = {}

func _init(templates: Dictionary) -> void:
	tile_templates = templates

## Fills the base grid with a ground tile.
func fill_ground(map: MapData, w: int, h: int) -> void:
	var grass: TacticalTileData = tile_templates.get("grass")
	if not grass: return
	
	for x: int in range(w):
		for y: int in range(h):
			map.grid_tiles[Vector3i(x, y, 0)] = grass

## Parses a BuildingBlueprintData resource and stamps it onto the map.
func apply_blueprint(map: MapData, blueprint: BuildingBlueprintData, origin: Vector3i) -> void:
	var wall: TacticalTileData = tile_templates.get("wall")
	var floor_tile: TacticalTileData = tile_templates.get("floor")
	var stairs: TacticalTileData = tile_templates.get("stairs")
	
	if not wall or not floor_tile or not stairs:
		push_error("MapGenerator: Missing required templates for blueprint application.")
		return

	# Iterate through each Z-level in the blueprint
	for z: int in range(blueprint.z_layers.size()):
		var layer: PackedStringArray = blueprint.z_layers[z]
		var current_z: int = origin.z + z
		
		# Iterate through each Y-row
		for y: int in range(layer.size()):
			var row: String = layer[y]
			
			# Iterate through each X-column (character)
			for x: int in range(row.length()):
				var char_symbol: String = row[x]
				var coord: Vector3i = Vector3i(origin.x + x, origin.y + y, current_z)
				
				# Stamp the appropriate tile based on the ASCII symbol
				match char_symbol:
					"#":
						map.grid_tiles[coord] = wall
					"W":
						# EXTERNAL ACCESS NOTE: Fetching the new window template
						var window: TacticalTileData = tile_templates.get("window")
						if window: map.grid_tiles[coord] = window
					".":
						map.grid_tiles[coord] = floor_tile
					"S":
						map.grid_tiles[coord] = stairs
					" ":
						if map.grid_tiles.has(coord):
							map.grid_tiles.erase(coord)
						pass
