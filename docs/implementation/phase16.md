Commander, we have reached the culmination of our foundational architecture: **Phase 7: The Renderer**.

It is time to make the invisible mathematical simulation visible. Because we have strictly separated our logic from our presentation, drawing the battlefield is a straightforward process of reading data and instantiating visual nodes.

### 1. Architectural Logic: Visual Slicing and 2.5D Illusion

**The 2.5D Illusion (`BattlefieldRenderer`):**
We will not use a single, monolithic `TileMap`. Instead, modern Godot 4.x architecture favors `TileMapLayer` nodes. The renderer will dynamically instantiate one `TileMapLayer` for every Z-level defined in our `MapData`.
To create the illusion of height in a top-down 2D perspective, we simply offset the visual `position.y` of higher layers (e.g., Z=1 is drawn 16 pixels higher than Z=0).

**The Elevation Slicer (`TacticalCamera`):**
The camera does more than pan and zoom; it dictates the player's focal Z-level. When the player adjusts the elevation focus (e.g., looking down into a valley or up at a tower), the Camera broadcasts this intent via the `EventBus`. The Renderer listens and dynamically fades out `TileMapLayer` nodes and entity sprites that exist above the current focal level.

*Before we begin, we must add one new signal to our global `EventBus` from Phase 1:*
`signal camera_z_level_changed(new_z_level: int)`

---

### 2. Phase 7 Directory Tree

```text
res://
└── Core/
    └── Level/
        ├── BattlefieldRenderer.gd   # Translates MapData into visual TileMapLayers
        └── TacticalCamera.gd        # Handles view manipulation and elevation slicing

```

---

### 3. Modular Node Scripts

#### A. The Tactical Camera

This script is attached to a `Camera2D`. It processes user input for panning, zooming, and scrolling through Z-levels. It contains zero simulation logic—it merely controls the viewport and broadcasts its state.

```gdscript
# File: res://Core/Level/TacticalCamera.gd
class_name TacticalCamera extends Camera2D

## THE PLAYER'S EYE
## Handles panning, zooming, and Z-level focus.
## Emits changes globally so the Renderer can slice the visual elevation.

@export_category("Camera Settings")
@export var pan_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var max_z_level: int = 3

var current_z_level: int = 0
var _target_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	_target_zoom = zoom
	# Ensure the initial state is broadcasted
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.camera_z_level_changed.emit(current_z_level)

func _process(delta: float) -> void:
	_handle_panning(delta)
	
	# Smoothly interpolate zoom
	zoom = zoom.lerp(_target_zoom, 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	_handle_zooming(event)
	_handle_z_level_slicing(event)

func _handle_panning(delta: float) -> void:
	var move_vec: Vector2 = Vector2.ZERO
	
	# Assumes standard InputMap actions are defined in Project Settings
	if Input.is_action_pressed("camera_up"): move_vec.y -= 1
	if Input.is_action_pressed("camera_down"): move_vec.y += 1
	if Input.is_action_pressed("camera_left"): move_vec.x -= 1
	if Input.is_action_pressed("camera_right"): move_vec.x += 1
	
	position += move_vec.normalized() * pan_speed * delta * (1.0 / zoom.x)

func _handle_zooming(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		_target_zoom += Vector2(zoom_speed, zoom_speed)
	elif event.is_action_pressed("camera_zoom_out"):
		_target_zoom -= Vector2(zoom_speed, zoom_speed)
		
	_target_zoom.x = clampf(_target_zoom.x, min_zoom, max_zoom)
	_target_zoom.y = clampf(_target_zoom.y, min_zoom, max_zoom)

func _handle_z_level_slicing(event: InputEvent) -> void:
	var z_changed: bool = false
	
	if event.is_action_pressed("camera_elevation_up") and current_z_level < max_z_level:
		current_z_level += 1
		z_changed = true
	elif event.is_action_pressed("camera_elevation_down") and current_z_level > 0:
		current_z_level -= 1
		z_changed = true
		
	if z_changed:
		print("TacticalCamera: Z-Level Focus changed to %d" % current_z_level)
		# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
		EventBus.camera_z_level_changed.emit(current_z_level)

```

#### B. The Battlefield Renderer

This script is attached to a standard `Node2D` (e.g., `BattlefieldRenderer`). It is passed the `MapData` upon initialization. It creates a stacked array of `TileMapLayer` nodes and uses the `camera_z_level_changed` event to hide or show layers seamlessly.

```gdscript
# File: res://Core/Level/BattlefieldRenderer.gd
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
			layer.modulate.a = 1.0
		else:
			# Optional: Darken layers below the current focus so the current level pops
			layer.modulate = Color(0.6, 0.6, 0.6, 1.0)

```

---