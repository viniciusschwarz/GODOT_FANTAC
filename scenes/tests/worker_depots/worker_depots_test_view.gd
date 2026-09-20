extends Node2D

# Setup simulation infrastructure
var clock: SimClock
var command_bus: CommandBus
var event_bus: EventBus
var save_registry: SaveRegistry

# Domain primitives
var spatial_reg: SpatialCellRegistry
var resource_reg: ResourceContainerRegistry
var reservation_reg: ReservationRegistry

# State tracking for rendering
var cell_size_pixels: float = 48.0
var grid_offset: Vector2 = Vector2(80, 80)
var worker_pos: Vector2i = Vector2i(0, 0)
var _command_id_counter: int = 1

# UI Nodes
@onready var status_label: Label = $HUD/Panel/VBoxContainer/StatusLabel
@onready var event_log: RichTextLabel = $HUD/Panel/VBoxContainer/EventLog
@onready var btn_step: Button = $HUD/Panel/VBoxContainer/HBoxContainer/BtnStep
@onready var btn_play_pause: Button = $HUD/Panel/VBoxContainer/HBoxContainer/BtnPlayPause
@onready var btn_speed_1: Button = $HUD/Panel/VBoxContainer/HBoxContainer/BtnSpeed1
@onready var btn_speed_2: Button = $HUD/Panel/VBoxContainer/HBoxContainer/BtnSpeed2
@onready var btn_speed_5: Button = $HUD/Panel/VBoxContainer/HBoxContainer/BtnSpeed5
@onready var btn_reset: Button = $HUD/Panel/VBoxContainer/HBoxContainer/BtnReset

func _ready() -> void:
	btn_step.pressed.connect(_on_step_pressed)
	btn_play_pause.pressed.connect(_on_play_pause_pressed)
	btn_speed_1.pressed.connect(func(): clock.set_speed(1); _update_ui())
	btn_speed_2.pressed.connect(func(): clock.set_speed(2); _update_ui())
	btn_speed_5.pressed.connect(func(): clock.set_speed(5); _update_ui())
	btn_reset.pressed.connect(_init_simulation)

	_init_simulation()

func _init_simulation() -> void:
	event_log.text = ""
	_log_event("Initializing simulation...")

	clock = SimClock.new()
	clock.set_speed(0) # Start paused
	command_bus = CommandBus.new()
	event_bus = EventBus.new()
	save_registry = SaveRegistry.new()

	spatial_reg = SpatialCellRegistry.new()
	spatial_reg.init(10, 10)
	resource_reg = ResourceContainerRegistry.new()
	reservation_reg = ReservationRegistry.new()

	_command_id_counter = 1
	worker_pos = Vector2i(0, 0)

	_register_commands()
	_register_saves()
	_register_events()

	# Setup Depot A (100) at (0,0) with 50 wood
	resource_reg.create_container(100)
	resource_reg.deposit(100, &"WOOD", 50)

	# Setup Depot B (200) at (0,2) with 0 wood
	resource_reg.create_container(200)

	# Setup Worker (1) at (0,0)
	resource_reg.create_container(1)
	spatial_reg.set_occupant(Vector2i(0, 0), 1)

	_update_ui()
	queue_redraw()

func _process(delta: float) -> void:
	if clock.is_paused():
		return

	var available_ticks = clock.advance_accumulator(int(delta * 1_000_000))
	for i in range(available_ticks):
		_step_simulation()

func _step_simulation() -> void:
	clock.step_tick()
	var tick = clock.current_tick

	if tick == 1:
		var c = _create_cmd(&"RESERVATION_CLAIM", {"claimant_id": 1, "target_id": 100, "claim_type": CoreEnums.ReservationClaimType.EXCLUSIVE_WRITE, "duration": 10}, tick)
		command_bus.submit(c)
	elif tick == 2:
		var c = _create_cmd(&"RESOURCE_TRANSFER", {"src_id": 100, "dst_id": 1, "resource_type": &"WOOD", "amount": 10}, tick)
		command_bus.submit(c)
	elif tick == 3:
		var c = _create_cmd(&"SPATIAL_RELOCATION", {"entity_id": 1, "from": Vector2i(0, 0), "to": Vector2i(0, 1)}, tick)
		command_bus.submit(c)
	elif tick == 4:
		var c = _create_cmd(&"SPATIAL_RELOCATION", {"entity_id": 1, "from": Vector2i(0, 1), "to": Vector2i(0, 2)}, tick)
		command_bus.submit(c)
	elif tick == 5:
		var c = _create_cmd(&"RESOURCE_TRANSFER", {"src_id": 1, "dst_id": 200, "resource_type": &"WOOD", "amount": 10}, tick)
		command_bus.submit(c)
	elif tick == 6:
		reservation_reg.release_claim(1, 100)
		_log_event("Worker released reservation on Depot A")

	command_bus.flush_tick(tick)

	_update_ui()
	queue_redraw()

func _create_cmd(type: StringName, payload: Dictionary, tick: int) -> Dictionary:
	var packet = {
		"command_id": _command_id_counter,
		"priority": CoreEnums.ExecutionPriority.INPUT_DIRECT,
		"command_type": type,
		"issuer_id": 1,
		"target_tick": tick,
		"payload": payload
	}
	_command_id_counter += 1
	return packet

func _register_commands() -> void:
	command_bus.register_command(&"SPATIAL_RELOCATION", _validate_spatial_relocation, _execute_spatial_relocation)
	command_bus.register_command(&"RESERVATION_CLAIM", _validate_reservation_claim, _execute_reservation_claim)
	command_bus.register_command(&"RESOURCE_TRANSFER", _validate_resource_transfer, _execute_resource_transfer)

func _register_saves() -> void:
	save_registry.register_domain(&"SPATIAL", Callable(spatial_reg, "get_save_state"), Callable(spatial_reg, "load_save_state"))
	save_registry.register_domain(&"RESOURCE", Callable(resource_reg, "get_save_state"), Callable(resource_reg, "load_save_state"))
	save_registry.register_domain(&"RESERVATION", Callable(reservation_reg, "get_save_state"), Callable(reservation_reg, "load_save_state"))

func _register_events() -> void:
	event_bus.subscribe(&"ENTITY_RELOCATED", func(e): _log_event("Entity %d moved to %s" % [e.get("entity_id", 0), str(e.get("to_coord", Vector2i()))]))
	event_bus.subscribe(&"RESERVATION_CLAIMED", func(e): _log_event("Entity %d claimed %d" % [e.get("claimant_id", 0), e.get("target_id", 0)]))
	event_bus.subscribe(&"RESOURCE_TRANSFERRED", func(e): _log_event("Transferred %d %s from %d to %d" % [e.get("amount", 0), str(e.get("resource_type", "")), e.get("src_id", 0), e.get("dst_id", 0)]))

# --- COMMAND EXECUTORS ---

func _validate_spatial_relocation(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	var from_coord = pl["from"]
	var to_coord = pl["to"]
	var dist = spatial_reg.calculate_distance(from_coord, to_coord, CoreEnums.SpatialDistanceMetric.MANHATTAN)
	if dist > 1:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_OUT_OF_BOUNDS, &"TOO_FAR")
	return _success_res(packet)

func _execute_spatial_relocation(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	var to_coord = pl["to"]
	var from_coord = pl["from"]
	var entity_id = pl["entity_id"]
	spatial_reg.clear_cell(from_coord)
	spatial_reg.set_occupant(to_coord, entity_id)

	if entity_id == 1:
		worker_pos = to_coord

	event_bus.emit_now({
		"event_type": &"ENTITY_RELOCATED",
		"entity_id": entity_id,
		"from_coord": from_coord,
		"to_coord": to_coord
	})

	return _success_res(packet)

func _validate_reservation_claim(packet: Dictionary) -> Dictionary:
	return _success_res(packet)

func _execute_reservation_claim(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	var claimant = pl["claimant_id"]
	var target = pl["target_id"]
	var res = reservation_reg.try_claim(claimant, target, pl["claim_type"], pl["duration"], clock.current_tick)
	if not res:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_TARGET_LOCKED, &"TARGET_LOCKED")

	event_bus.emit_now({
		"event_type": &"RESERVATION_CLAIMED",
		"claimant_id": claimant,
		"target_id": target,
		"claim_type": pl["claim_type"]
	})

	return _success_res(packet)

func _validate_resource_transfer(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	if resource_reg.get_balance(pl["src_id"], pl["resource_type"]) < pl["amount"]:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_INSUFFICIENT_BALANCE, &"INSUFFICIENT_BALANCE")
	return _success_res(packet)

func _execute_resource_transfer(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	var src = pl["src_id"]
	var dst = pl["dst_id"]
	var res_type = pl["resource_type"]
	var amount = pl["amount"]
	var res = resource_reg.transfer(src, dst, res_type, amount)
	if not res:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_INSUFFICIENT_BALANCE, &"TRANSFER_FAILED")

	event_bus.emit_now({
		"event_type": &"RESOURCE_TRANSFERRED",
		"src_id": src,
		"dst_id": dst,
		"resource_type": res_type,
		"amount": amount
	})

	return _success_res(packet)

func _error_res(packet: Dictionary, status: int, reason: StringName) -> Dictionary:
	return {
		"command_id": packet["command_id"],
		"status_code": status,
		"reason_code": reason,
		"mutated_entity_ids": PackedInt32Array()
	}

func _success_res(packet: Dictionary) -> Dictionary:
	return {
		"command_id": packet["command_id"],
		"status_code": CoreEnums.ExecutionStatusCode.SUCCESS,
		"reason_code": &"NONE",
		"mutated_entity_ids": PackedInt32Array()
	}

# --- UI & RENDERING ---

func _on_step_pressed() -> void:
	if not clock.is_paused():
		clock.set_speed(0)
	_step_simulation()

func _on_play_pause_pressed() -> void:
	if clock.is_paused():
		clock.set_speed(1)
	else:
		clock.set_speed(0)
	_update_ui()

func _update_ui() -> void:
	var speed_str = "Paused"
	if clock.speed_multiplier > 0:
		speed_str = "%dx" % clock.speed_multiplier
	status_label.text = "Tick: %d | Speed: %s" % [clock.current_tick, speed_str]

func _log_event(msg: String) -> void:
	event_log.text += "[Tick %d] %s\n" % [clock.current_tick if clock else 0, msg]

func _draw() -> void:
	if not spatial_reg:
		return

	# Draw Grid Outline
	var grid_width = 10
	var grid_height = 10

	for x in range(grid_width + 1):
		draw_line(grid_offset + Vector2(x * cell_size_pixels, 0), grid_offset + Vector2(x * cell_size_pixels, grid_height * cell_size_pixels), Color(0.5, 0.5, 0.5, 0.5))
	for y in range(grid_height + 1):
		draw_line(grid_offset + Vector2(0, y * cell_size_pixels), grid_offset + Vector2(grid_width * cell_size_pixels, y * cell_size_pixels), Color(0.5, 0.5, 0.5, 0.5))

	# Draw Depot A (0, 0)
	var depot_a_pos = grid_offset + Vector2(0, 0) * cell_size_pixels
	var depot_a_rect = Rect2(depot_a_pos, Vector2(cell_size_pixels, cell_size_pixels))
	draw_rect(depot_a_rect, Color(0, 0, 1, 0.5)) # Blue
	draw_string(ThemeDB.fallback_font, depot_a_pos + Vector2(5, 20), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var depot_a_wood = resource_reg.get_balance(100, &"WOOD") if resource_reg else 0
	draw_string(ThemeDB.fallback_font, depot_a_pos + Vector2(5, 40), str(depot_a_wood), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# Draw Depot B (0, 2)
	var depot_b_pos = grid_offset + Vector2(0, 2) * cell_size_pixels
	var depot_b_rect = Rect2(depot_b_pos, Vector2(cell_size_pixels, cell_size_pixels))
	draw_rect(depot_b_rect, Color(0, 1, 0, 0.5)) # Green
	draw_string(ThemeDB.fallback_font, depot_b_pos + Vector2(5, 20), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var depot_b_wood = resource_reg.get_balance(200, &"WOOD") if resource_reg else 0
	draw_string(ThemeDB.fallback_font, depot_b_pos + Vector2(5, 40), str(depot_b_wood), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# Draw Worker
	var worker_draw_pos = grid_offset + Vector2(worker_pos) * cell_size_pixels
	var worker_rect = Rect2(worker_draw_pos + Vector2(cell_size_pixels * 0.25, cell_size_pixels * 0.25), Vector2(cell_size_pixels * 0.5, cell_size_pixels * 0.5))
	draw_rect(worker_rect, Color(1, 1, 0, 0.8)) # Yellow
	var worker_wood = resource_reg.get_balance(1, &"WOOD") if resource_reg else 0
	draw_string(ThemeDB.fallback_font, worker_draw_pos + Vector2(cell_size_pixels * 0.25, cell_size_pixels * 0.25 - 5), str(worker_wood), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
