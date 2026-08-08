# File: res://core/level/battlefield_renderer.gd
class_name BattlefieldRenderer extends Node2D

## THE VISUAL BOARD (FLAT 2D UPDATE)
## Translates mathematical MapData into visual TileMapLayers using Atlas mapping.
## Tiles are stacked precisely on top of each other on the Z-axis.

@export var tileset: TileSet 
## Matches the ID found in the bottom TileSet panel (Setup -> Atlas -> ID).
@export var tileset_source_id: int = 1 

var _map_layers: Dictionary = {} 

## TRANSLATION DICTIONARY
## Maps the string names from MapGenerator to the Vector2i coordinates in your tiles.png Atlas.
const TILE_MAPPING: Dictionary = {
	"Grass": Vector2i(0, 0),
	"Tree": Vector2i(1, 0),
	"Floor": Vector2i(2, 0),
	"Wall": Vector2i(3, 0),
	"Stairs": Vector2i(4, 0),
	"Window": Vector2i(5, 0) # Note: Ensure you actually paint a 6th tile in your atlas for this!
}

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Subscribing to global camera events
	EventBus.camera_z_level_changed.connect(_on_camera_z_level_changed)

func initialize_visuals(map_data: MapData) -> void:
	_clear_existing_layers()

	for z: int in range(map_data.max_z_levels + 1):
		var layer: TileMapLayer = TileMapLayer.new()
		layer.tile_set = tileset
		layer.name = "ElevationLayer_Z%d" % z
		
		# Z strictly controls rendering order.
		layer.z_index = z
		
		add_child(layer)
		_map_layers[z] = layer

	for coord: Vector3i in map_data.grid_tiles.keys():
		# EXTERNAL ACCESS NOTE: Iterating over the custom MapData Dictionary
		var tile: TacticalTileData = map_data.grid_tiles.get(coord)

		if tile and _map_layers.has(coord.z):
			var target_layer: TileMapLayer = _map_layers[coord.z]
			var atlas_coords: Vector2i = TILE_MAPPING.get(tile.tile_name, Vector2i(0, 0))
			
			# FIX: Using the exported tileset_source_id instead of a hardcoded 0
			target_layer.set_cell(Vector2i(coord.x, coord.y), tileset_source_id, atlas_coords)

func _clear_existing_layers() -> void:
	for child: Node in get_children():
		child.queue_free()
	_map_layers.clear()

func _on_camera_z_level_changed(focus_z: int) -> void:
	for z: int in _map_layers.keys():
		var layer: TileMapLayer = _map_layers[z]
		if z > focus_z:
			layer.modulate.a = 0.0
		elif z == focus_z:
			layer.modulate = Color.WHITE
		else:
			layer.modulate = Color(0.4, 0.4, 0.4, 1.0)
