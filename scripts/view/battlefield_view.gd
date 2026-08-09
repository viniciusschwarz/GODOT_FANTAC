class_name BattlefieldView extends Node2D

const TILE_SIZE: int = 64
const Z1_VISUAL_Y_OFFSET: float = -12.0

@onready var ground_layer_z0 = $GroundLayerZ0
@onready var rampart_layer_z1 = $RampartLayerZ1

@onready var tokens_container = $TokensContainer
@onready var lines_container = Node2D.new()


var unit_token_scene: PackedScene = preload("res://scenes/view/unit_token_view.tscn")
var unit_tokens: Dictionary = {} # Dictionary[int, UnitTokenView]

var current_replay_buffer: TurnReplayBufferResource = null

var selected_unit_id: int = -1
var active_waypoints: Dictionary = {}
var master_matrix: BattlefieldMatrix = null
var current_phase: EventBus.Phase = EventBus.Phase.INITIALIZATION
var _static_unit_cache: Dictionary = {} # READ-ONLY cache of UnitDataResource
var _static_prop_coords: Dictionary = {} # prop_id -> Vector3i


func _ready() -> void:
	add_child(lines_container)
	EventBus.scrubber_tick_changed.connect(_on_scrubber_tick_changed)
	EventBus.turn_simulation_completed.connect(_on_turn_simulation_completed)
	EventBus.grid_initialized.connect(_on_grid_initialized)
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.tile_right_clicked.connect(_on_tile_right_clicked)
	EventBus.match_started.connect(_on_match_started)



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
	# Only initialize once at Tick 0
	if not unit_tokens.is_empty():
		return

	if replay_buffer.tick_snapshots.is_empty():
		return

	var initial_snapshot = replay_buffer.tick_snapshots[0]

	for unit_id in initial_snapshot.unit_transform_states.keys():
		var token: UnitTokenView = unit_token_scene.instantiate()
		tokens_container.add_child(token)

		var faction_id = 0
		var max_hp = 100.0
		if _static_unit_cache.has(unit_id):
			var unit_data = _static_unit_cache[unit_id]
			faction_id = unit_data.faction_id
			max_hp = unit_data.max_hp

		token.setup_visuals(unit_id as int, faction_id, max_hp, false)
		unit_tokens[unit_id] = token

	for prop_id in initial_snapshot.prop_states.keys():
		var token: UnitTokenView = unit_token_scene.instantiate()
		tokens_container.add_child(token)

		# Prop tokens use their own IDs, and faction is ignored
		token.setup_visuals(prop_id as int, -1, 100.0, true)
		unit_tokens[prop_id] = token

	# Apply tick 0 state
	_on_scrubber_tick_changed(0)

func _on_scrubber_tick_changed(target_tick: int) -> void:
	if not current_replay_buffer or target_tick < 0 or target_tick >= current_replay_buffer.tick_snapshots.size():
		return

	var snapshot = current_replay_buffer.tick_snapshots[target_tick]

	for token_id in unit_tokens.keys():
		var token: UnitTokenView = unit_tokens[token_id]

		if token_id in snapshot.unit_transform_states:
			token.visible = true
			var coord: Vector3i = snapshot.unit_transform_states[token_id]
			var hp: float = snapshot.unit_hp_states.get(token_id, 0.0)
			token.update_state(coord, hp)
		elif token_id in snapshot.prop_states:
			var state = snapshot.prop_states[token_id]
			if state == 0: # Intact
				token.visible = true
			else:
				token.visible = false

			if _static_prop_coords.has(token_id):
				var coord = _static_prop_coords[token_id]
				token.update_state(coord, 100.0) # Props don't track HP in UI right now
		else:
			token.visible = false

func _on_grid_initialized(matrix: BattlefieldMatrix) -> void:
	master_matrix = matrix
	paint_debug_grid(matrix)

func _on_match_started(matrix: BattlefieldMatrix, units_cache: Dictionary) -> void:
	_static_unit_cache = units_cache

	_static_prop_coords.clear()
	for prop_id in matrix._props.keys():
		var prop = matrix.get_prop(prop_id)
		_static_prop_coords[prop_id] = prop.grid_position

func _on_unit_selected(unit_id: int) -> void:
	selected_unit_id = unit_id

func _on_phase_changed(phase: EventBus.Phase) -> void:
	current_phase = phase
	if phase != EventBus.Phase.PLANNING:
		lines_container.hide()
	else:
		lines_container.show()
		# Waypoints are cleared by UI manager and simulation on new turn,
		# but view just blindly draws what's in active_waypoints.
		# We'll rely on UI to tell us or just keep it simple.
		# To be safe, clear them visually when returning to planning.
		active_waypoints.clear()
		_redraw_intent_lines()

func _on_tile_right_clicked(unit_id: int, grid_coord: Vector3i) -> void:
	active_waypoints[unit_id] = grid_coord
	_redraw_intent_lines()

func _redraw_intent_lines() -> void:
	for child in lines_container.get_children():
		child.queue_free()

	for unit_id in active_waypoints.keys():
		if unit_tokens.has(unit_id):
			var token = unit_tokens[unit_id]
			var start_pos = token.position
			var target_coord = active_waypoints[unit_id]
			# Formula: Vector2(grid_x * 64 + 32, grid_y * 64 + 32 + (grid_z * -12))
			var target_pos = Vector2(target_coord.x * 64 + 32, target_coord.y * 64 + 32 + (target_coord.z * -12.0))

			var line = Line2D.new()
			line.add_point(start_pos)
			line.add_point(target_pos)
			line.width = 4.0
			line.default_color = Color(1.0, 0.5, 0.0, 0.8) # Orange intent line
			lines_container.add_child(line)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if master_matrix == null:
			return

		var mouse_pos = get_global_mouse_position()
		# Rough inverse calculation, assuming z=0 for picking
		var grid_x = int(mouse_pos.x / 64.0)
		var grid_y = int(mouse_pos.y / 64.0)

		# Check Z1 first, then Z0
		var clicked_coord = Vector3i(grid_x, grid_y, 1)
		var tile = master_matrix.get_tile(clicked_coord)
		if tile == null:
			clicked_coord = Vector3i(grid_x, grid_y, 0)
			tile = master_matrix.get_tile(clicked_coord)

		if event.button_index == MOUSE_BUTTON_LEFT:
			if tile and tile.occupying_unit_id != -1:
				EventBus.unit_selected.emit(tile.occupying_unit_id)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_phase == EventBus.Phase.PLANNING and selected_unit_id != -1:
				if tile != null:
					EventBus.tile_right_clicked.emit(selected_unit_id, clicked_coord)
