class_name BattlefieldRenderer extends Node2D

## THE VISUAL BOARD
## Translates mathematical MapData into visual TileMapLayers.
## Reacts to camera elevation changes to hide blocking roofs.

@export var tileset: TileSet ## The visual art for the tiles
@export var elevation_visual_offset: float = 16.0 ## How many pixels up each Z-level is shifted

var _map_layers: Dictionary = {} ## Maps Z-level (int) to TileMapLayer Node

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Subscribing to global camera events
	EventBus.camera_z_level_changed.connect(_on_camera_z_level_changed)

## Dependency Injection: Called by the BattlefieldManager to draw the grid.
## @param map_data: The Resource containing the mathematical layout.
func initialize_visuals(map_data: MapData) -> void:
	_clear_existing_layers()

	# 1. Create TileMapLayers for every potential Z-level
	for z: int in range(map_data.max_z_levels + 1):
		var layer: TileMapLayer = TileMapLayer.new()
		layer.tile_set = tileset
		layer.name = "ElevationLayer_Z%d" % z

		# Offset the Y position to create the 2.5D height illusion
		layer.position.y = -float(z) * elevation_visual_offset

		# Ensure higher layers render on top of lower ones
		layer.z_index = z

		add_child(layer)
		_map_layers[z] = layer

	# 2. Populate the grid based on the MapData resource
	# EXTERNAL ACCESS NOTE: Iterating over the custom MapData Dictionary
	for coord: Vector3i in map_data.grid_tiles.keys():
		var tile: TacticalTileData = map_data.get_tile(coord)

		if tile and _map_layers.has(coord.z):
			var target_layer: TileMapLayer = _map_layers[coord.z]

			# Note: In a real project, you would map 'tile.tile_name' to specific atlas coordinates.
			# Using Vector2i.ZERO as a placeholder for the atlas coordinate.
			var atlas_coords: Vector2i = Vector2i.ZERO
			var source_id: int = 0

			# We only pass x and y to the 2D TileMapLayer; the layer's position handles the Z height
			target_layer.set_cell(Vector2i(coord.x, coord.y), source_id, atlas_coords)

	print("BattlefieldRenderer: Drawn %d layers." % _map_layers.size())

func _clear_existing_layers() -> void:
	for child: Node in get_children():
		child.queue_free()
	_map_layers.clear()

## Modulates the alpha of tile layers based on the player's camera focus.
func _on_camera_z_level_changed(focus_z: int) -> void:
	for z: int in _map_layers.keys():
		var layer: TileMapLayer = _map_layers[z]

		if z > focus_z:
			# Hide layers entirely if they are above our focus to prevent seeing roofs blocking units
			# You can use a Tween here to fade the modulate.a to 0.0 for extra juice
			layer.modulate.a = 0.0
		elif z == focus_z:
			# Fully visible
			layer.modulate = Color.WHITE
		else:
			# Optional: Darken layers below the current focus so the current level pops
			layer.modulate = Color(0.6, 0.6, 0.6, 1.0)
