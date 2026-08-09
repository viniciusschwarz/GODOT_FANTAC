class_name BattlefieldView extends Node2D

const TILE_SIZE: int = 64
const Z1_VISUAL_Y_OFFSET: float = -12.0

@onready var ground_layer_z0 = $GroundLayerZ0
@onready var rampart_layer_z1 = $RampartLayerZ1
@onready var tokens_container = $TokensContainer

var unit_token_scene: PackedScene = preload("res://scenes/view/unit_token_view.tscn")
var unit_tokens: Dictionary = {} # Dictionary[int, UnitTokenView]

var current_replay_buffer: TurnReplayBufferResource = null

func _ready() -> void:
	EventBus.scrubber_tick_changed.connect(_on_scrubber_tick_changed)
	EventBus.turn_simulation_completed.connect(_on_turn_simulation_completed)
	EventBus.grid_initialized.connect(_on_grid_initialized)

func _on_grid_initialized(matrix: BattlefieldMatrix) -> void:
	paint_debug_grid(matrix)

func paint_debug_grid(matrix: BattlefieldMatrix) -> void:
	var atlas_img = Image.create(128, 64, false, Image.FORMAT_RGBA8)

	# Paint Z0 Ground (Dark Green)
	for x in range(0, 64):
		for y in range(0, 64):
			# 2px black border
			if x < 2 or x >= 62 or y < 2 or y >= 62:
				atlas_img.set_pixel(x, y, Color.BLACK)
			else:
				atlas_img.set_pixel(x, y, Color(0.15, 0.3, 0.15))

	# Paint Z1 Rampart (Gray)
	for x in range(64, 128):
		for y in range(0, 64):
			# 2px black border
			if x < 66 or x >= 126 or y < 2 or y >= 62:
				atlas_img.set_pixel(x, y, Color.BLACK)
			else:
				atlas_img.set_pixel(x, y, Color(0.4, 0.4, 0.4))

	var texture = ImageTexture.create_from_image(atlas_img)
	# Prevent pixel bleeding
	# Texture filter is typically set on the CanvasItem or via project settings,
	# but can't be set directly on ImageTexture in Godot 4.
	# We can set texture_filter on the TileMapLayers to NEAREST.
	ground_layer_z0.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rampart_layer_z1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(64, 64)
	atlas_source.create_tile(Vector2i(0, 0))
	atlas_source.create_tile(Vector2i(1, 0))

	var custom_tileset = TileSet.new()
	custom_tileset.tile_size = Vector2i(64, 64)
	custom_tileset.add_source(atlas_source)

	ground_layer_z0.tile_set = custom_tileset
	rampart_layer_z1.tile_set = custom_tileset

	for x in range(12):
		for y in range(12):
			if matrix.get_tile(Vector3i(x, y, 0)) != null:
				ground_layer_z0.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			if matrix.get_tile(Vector3i(x, y, 1)) != null:
				rampart_layer_z1.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

func _on_turn_simulation_completed(replay_buffer: TurnReplayBufferResource) -> void:
	current_replay_buffer = replay_buffer
	_initialize_tokens_from_buffer(replay_buffer)

func _initialize_tokens_from_buffer(replay_buffer: TurnReplayBufferResource) -> void:
	# Clear existing tokens
	for token in unit_tokens.values():
		token.queue_free()
	unit_tokens.clear()

	if replay_buffer.tick_snapshots.is_empty():
		return

	# Assume Tick 0 has all units for instantiation (in a real scenario, you'd get the roster details from GameState/BattlefieldManager)
	var initial_snapshot = replay_buffer.tick_snapshots[0]

	for unit_id in initial_snapshot.unit_transform_states.keys():
		var token: UnitTokenView = unit_token_scene.instantiate()
		tokens_container.add_child(token)

		# Here we assume faction=0 and max_hp=100 as fallback. Real implementation should fetch from UnitDataResource roster.
		token.setup(unit_id as int, 0, 100.0)
		unit_tokens[unit_id] = token

	# Apply tick 0 state
	_on_scrubber_tick_changed(0)

func _on_scrubber_tick_changed(target_tick: int) -> void:
	if not current_replay_buffer or target_tick < 0 or target_tick >= current_replay_buffer.tick_snapshots.size():
		return

	var snapshot = current_replay_buffer.tick_snapshots[target_tick]

	for unit_id in unit_tokens.keys():
		var token: UnitTokenView = unit_tokens[unit_id]

		if unit_id in snapshot.unit_transform_states:
			token.visible = true
			var coord: Vector3i = snapshot.unit_transform_states[unit_id]
			var hp: float = snapshot.unit_hp_states.get(unit_id, 0.0)
			token.update_state(coord, hp)
		else:
			token.visible = false
