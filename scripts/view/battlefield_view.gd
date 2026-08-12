## View layer renderer projecting 3D simulation coordinates onto a 2D isometric canvas.
## Strictly parses headless telemetry snapshots and matrix payloads without modifying data.
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
## [VIEW LAYER SAFETY]: READ-ONLY visual state cache populated from headless initializations.
var _static_unit_cache: Dictionary = {}
var _static_prop_coords: Dictionary = {}
var active_z_level: int = 1
var _current_tick: int = 0

var threat_tiles: Array[Vector3i] = []
var preview_intent: Dictionary = {}

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
	if not unit_tokens.is_empty():
		return

	if replay_buffer.tick_snapshots.is_empty():
		return

	# [VIEW LAYER SAFETY]: Reading initial headless matrix injection payloads mapping visuals for Tick 0.
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

		var start_coord = initial_snapshot.unit_transform_states[unit_id]
		var start_hp = initial_snapshot.unit_hp_states.get(unit_id, max_hp)
		token.update_state(start_coord, start_hp)

		unit_tokens[unit_id] = token

	for prop_id in initial_snapshot.prop_states.keys():
		var token: UnitTokenView = unit_token_scene.instantiate()
		tokens_container.add_child(token)

		token.setup_visuals(prop_id as int, -1, 100.0, true)

		var p_coord = _static_prop_coords.get(prop_id, Vector3i.ZERO)
		token.update_state(p_coord, 100.0)

		unit_tokens[prop_id] = token

	_on_scrubber_tick_changed(0)

## Interprets micro-tick array indexing mapping positional timelines onto dynamic sprite components.
func _on_scrubber_tick_changed(target_tick: int) -> void:
	if not current_replay_buffer or target_tick < 0 or target_tick >= current_replay_buffer.tick_snapshots.size():
		return

	_current_tick = target_tick
	queue_redraw()

	# [VIEW LAYER SAFETY]: Strictly iterating readonly serialized ticks preventing cross-thread state pollution.
	var snapshot = current_replay_buffer.tick_snapshots[target_tick]

	for token_id in unit_tokens.keys():
		var token: UnitTokenView = unit_tokens[token_id]

		if token_id in snapshot.unit_transform_states:
			var coord: Vector3i = snapshot.unit_transform_states[token_id]
			if coord.z <= active_z_level:
				token.visible = true
				var hp: float = snapshot.unit_hp_states.get(token_id, 0.0)
				token.update_state(coord, hp)
			else:
				token.visible = false
		elif token_id in snapshot.prop_states:
			var state = snapshot.prop_states[token_id]

			if _static_prop_coords.has(token_id):
				var coord = _static_prop_coords[token_id]
				if state == 0 and coord.z <= active_z_level:
					token.visible = true
					token.update_state(coord, 100.0)
				else:
					token.visible = false
			else:
				token.visible = false
		else:
			token.visible = false

## Receives the generated map, establishing grid visualization.
func _on_grid_initialized(matrix: BattlefieldMatrix) -> void:
	master_matrix = matrix
	paint_debug_grid(matrix)

## Initializes view caching reading master state dictionary payloads.
func _on_match_started(matrix: BattlefieldMatrix, units_cache: Dictionary) -> void:
	_static_unit_cache = units_cache

	_static_prop_coords.clear()
	for prop_id in matrix._props.keys():
		var prop = matrix.get_prop(prop_id)
		_static_prop_coords[prop_id] = prop.grid_position

## Receives UI signals assigning active context highlighting and previews AITree paths.
func _on_unit_selected(unit_id: int) -> void:
	selected_unit_id = unit_id
	preview_intent.clear()
	if current_phase == EventBus.Phase.PLANNING and _static_unit_cache.has(unit_id):
		var unit = _static_unit_cache[unit_id]
		preview_intent = AITreeEvaluator.preview_unit_intent(unit, master_matrix, _static_unit_cache)
	queue_redraw()

## Re-configures input bounds clearing UI context and threat envelopes.
func _on_phase_changed(phase: EventBus.Phase) -> void:
	current_phase = phase
	threat_tiles.clear()
	preview_intent.clear()

	if phase != EventBus.Phase.PLANNING:
		lines_container.hide()
	else:
		lines_container.show()
		active_waypoints.clear()
		_redraw_intent_lines()

		# Calculate Threat Envelopes
		for u_id in _static_unit_cache:
			var unit = _static_unit_cache[u_id]
			if unit.faction_id != 0 and unit.current_hp > 0:
				var max_movable_tiles = floor(100.0 / unit.movement_speed_ticks_per_tile)
				var total_reach = max_movable_tiles + unit.attack_range_max
				var start_coord = Vector3i(unit.template_parameters.get("last_coord_x", 0), unit.template_parameters.get("last_coord_y", 0), unit.template_parameters.get("last_coord_z", 0))

				for x in range(master_matrix._width):
					for y in range(master_matrix._depth):
						for z in range(master_matrix._height_levels):
							var target_coord = Vector3i(x, y, z)
							if master_matrix.get_tile(target_coord) != null:
								var dist = abs(start_coord.x - target_coord.x) + abs(start_coord.y - target_coord.y)
								if dist <= total_reach:
									threat_tiles.append(target_coord)

	queue_redraw()

## Stores requested override coordinates visually before UI confirmation.
func _on_tile_right_clicked(unit_id: int, grid_coord: Vector3i) -> void:
	active_waypoints[unit_id] = grid_coord
	_redraw_intent_lines()

## Maps logical spatial lines bridging tokens to waypoints.
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

## Adjusts visible terrain bounds.
func _set_active_z_level(level: int) -> void:
	active_z_level = clampi(level, 0, 1)
	rampart_layer_z1.visible = (active_z_level >= 1)
	_on_scrubber_tick_changed(_current_tick)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			_set_active_z_level(active_z_level - 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			_set_active_z_level(active_z_level + 1)
			get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		if master_matrix == null:
			return

		var mouse_pos = get_global_mouse_position()
		# Rough inverse calculation, assuming z=0 for picking
		var grid_x = int(mouse_pos.x / 64.0)
		var grid_y = int(mouse_pos.y / 64.0)

		var tile = null
		var clicked_coord = Vector3i.ZERO

		# Check Z1 first (if active), then Z0
		if active_z_level >= 1:
			clicked_coord = Vector3i(grid_x, grid_y, 1)
			tile = master_matrix.get_tile(clicked_coord)

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

func _process(_delta: float) -> void:
	if current_phase == EventBus.Phase.PLANNING:
		queue_redraw()

func _draw() -> void:
	if current_phase == EventBus.Phase.PLANNING:
		for coord in threat_tiles:
			var screen_pos = Vector2(coord.x * 64, coord.y * 64) + Vector2(0, coord.z * Z1_VISUAL_Y_OFFSET)
			draw_rect(Rect2(screen_pos, Vector2(64, 64)), Color(1.0, 0.0, 0.0, 0.25), true)

		if not preview_intent.is_empty():
			var target_coord = preview_intent.get("predicted_target_coord", Vector3i(-1, -1, -1))
			if target_coord != Vector3i(-1, -1, -1):
				var screen_pos = Vector2(target_coord.x * 64, target_coord.y * 64) + Vector2(0, target_coord.z * Z1_VISUAL_Y_OFFSET)
				var alpha = (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.4 + 0.2
				draw_rect(Rect2(screen_pos, Vector2(64, 64)), Color(0.2, 0.8, 1.0, alpha), false, 2.0)

			var path = preview_intent.get("predicted_path_array", [])
			if path.size() > 1:
				var points = PackedVector2Array()
				for coord in path:
					var screen_pos = Vector2(coord.x * 64 + 32, coord.y * 64 + 32) + Vector2(0, coord.z * Z1_VISUAL_Y_OFFSET)
					points.append(screen_pos)
				draw_polyline(points, Color(0.2, 0.8, 1.0, 1.0), 3.0)

	if current_replay_buffer and _current_tick >= 0 and _current_tick < current_replay_buffer.tick_snapshots.size():
		var snapshot = current_replay_buffer.tick_snapshots[_current_tick]

		for proj in snapshot.active_projectiles:
			var pos_3d = proj.current_pos_3d
			var vel_3d = proj.velocity.normalized() * 2.0
			var start_3d = pos_3d - vel_3d

			var end_screen = Vector2(pos_3d.x * 64, pos_3d.y * 64) + Vector2(0, pos_3d.z * Z1_VISUAL_Y_OFFSET)
			var start_screen = Vector2(start_3d.x * 64, start_3d.y * 64) + Vector2(0, start_3d.z * Z1_VISUAL_Y_OFFSET)

			draw_line(start_screen, end_screen, Color(1.0, 0.9, 0.1), 2.0)
			draw_circle(end_screen, 4.0, Color(1.0, 1.0, 1.0))

		var recent_melee_events = []
		for t in range(max(0, _current_tick - 2), _current_tick + 1):
			var snap = current_replay_buffer.tick_snapshots[t]
			recent_melee_events.append_array(snap.melee_events)

		for event in recent_melee_events:
			var a_c = event.attacker_coord
			var d_c = event.target_coord
			var a_screen = Vector2(a_c.x * 64 + 32, a_c.y * 64 + 32) + Vector2(0, a_c.z * Z1_VISUAL_Y_OFFSET)
			var d_screen = Vector2(d_c.x * 64 + 32, d_c.y * 64 + 32) + Vector2(0, d_c.z * Z1_VISUAL_Y_OFFSET)

			draw_line(a_screen, d_screen, Color(1.0, 0.2, 0.2), 4.0)
			draw_arc(d_screen, 16.0, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.8), 2.0)
