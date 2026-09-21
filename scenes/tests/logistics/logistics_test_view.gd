extends Control

const CommandBus = preload("res://core/command/command_bus.gd")
const EventBus = preload("res://core/event/event_bus.gd")
const SimClock = preload("res://core/time/sim_clock.gd")

const SpatialCellRegistry = preload("res://simulation/spatial/spatial_cell_registry.gd")
const ResourceContainerRegistry = preload("res://simulation/resource/resource_container_registry.gd")
const ReservationRegistry = preload("res://simulation/reservation/reservation_registry.gd")

const GoapSequencer = preload("res://framework/goap/sequencer/goap_sequencer.gd")
const GoapPlanner = preload("res://framework/goap/planner/goap_planner.gd")
const GoapGoalArbitrator = preload("res://framework/goap/goals/goap_goal_arbitrator.gd")

const GoalRestockCargo = preload("res://game/logistics/goals/goal_restock_cargo.gd")
const GoalDeliverCargo = preload("res://game/logistics/goals/goal_deliver_cargo.gd")

const ActionNavigateTo = preload("res://game/logistics/actions/action_navigate_to.gd")
const ActionClaimDepot = preload("res://game/logistics/actions/action_claim_depot.gd")
const ActionWithdrawCargo = preload("res://game/logistics/actions/action_withdraw_cargo.gd")
const ActionDepositCargo = preload("res://game/logistics/actions/action_deposit_cargo.gd")
const ActionReleaseDepot = preload("res://game/logistics/actions/action_release_depot.gd")

const TargetDepotResolver = preload("res://game/logistics/evaluators/target_depot_resolver.gd")
const LogisticsStateMapper = preload("res://game/logistics/evaluators/logistics_state_mapper.gd")
const GoapStateSnapshot = preload("res://framework/goap/common/goap_state_snapshot.gd")

# Nodes
@onready var grid_canvas = $HSplitContainer/LeftPanel/GridCanvas
@onready var label_tick = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/TickLabel
@onready var label_goal = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/GoalLabel
@onready var label_action = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/ActionLabel
@onready var label_plan = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/PlanLabel
@onready var label_inv_courier = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/InvCourierLabel
@onready var label_inv_supply = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/InvSupplyLabel
@onready var label_inv_demand = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/InvDemandLabel
@onready var event_log = $HSplitContainer/RightPanel/EventLog
@onready var timer = $Timer

# Options
@onready var option_speed = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/HBoxContainer/OptionButton

# Core logic
var command_bus: CommandBus
var event_bus: EventBus
var sim_clock: SimClock

var spatial_reg: SpatialCellRegistry
var resource_reg: ResourceContainerRegistry
var reservation_reg: ReservationRegistry

var sequencer: GoapSequencer
var planner: GoapPlanner
var arbitrator: GoapGoalArbitrator

var pawn_id: int = 1
var pawn_container_id: int = 1
var pawn_coord: Vector2i = Vector2i(0, 0)

var supply_depot_id: int = 101
var supply_depot_coord: Vector2i = Vector2i(2, 2)

var demand_depot_id: int = 102
var demand_depot_coord: Vector2i = Vector2i(7, 7)

var depots: Array[Dictionary] = []

var last_tick: int = 0
var is_playing: bool = false

func _ready() -> void:
	# Configure UI hooks
	grid_canvas.draw.connect(_on_grid_canvas_draw)

	# Initial setup
	_reset_simulation()

	# Option button setup
	option_speed.add_item("1x")
	option_speed.add_item("2x")
	option_speed.add_item("5x")
	option_speed.add_item("10x")
	option_speed.selected = 0
	option_speed.item_selected.connect(_on_speed_changed)

func _reset_simulation() -> void:
	is_playing = false
	timer.stop()
	timer.wait_time = 1.0

	command_bus = CommandBus.new()
	event_bus = EventBus.new()
	sim_clock = SimClock.new()
	sim_clock.reset()
	last_tick = 0

	spatial_reg = SpatialCellRegistry.new()
	spatial_reg.init(10, 10)

	resource_reg = ResourceContainerRegistry.new()
	reservation_reg = ReservationRegistry.new()

	planner = GoapPlanner.new()
	arbitrator = GoapGoalArbitrator.new()
	sequencer = GoapSequencer.new(pawn_id, planner, arbitrator, command_bus, event_bus)

	# Register handlers
	command_bus.register_command(&"SPATIAL_RELOCATION", _pass_validator, _handle_spatial_relocation)
	command_bus.register_command(&"RESERVATION_CLAIM", _pass_validator, _handle_reservation_claim)
	command_bus.register_command(&"RESERVATION_RELEASE", _pass_validator, _handle_reservation_release)
	command_bus.register_command(&"RESOURCE_TRANSFER", _pass_validator, _handle_resource_transfer)

	# Connect events
	event_bus.event_emitted.connect(_on_event_emitted)

	# Init registries
	pawn_coord = Vector2i(0, 0)
	spatial_reg.set_occupant(supply_depot_coord, supply_depot_id)
	spatial_reg.set_occupant(demand_depot_coord, demand_depot_id)
	spatial_reg.set_occupant(pawn_coord, pawn_id)

	resource_reg.create_container(pawn_container_id)
	resource_reg.create_container(supply_depot_id)
	resource_reg.create_container(demand_depot_id)

	resource_reg.deposit(supply_depot_id, &"wood", 50)
	resource_reg.withdraw(pawn_container_id, &"wood", resource_reg.get_balance(pawn_container_id, &"wood"))
	resource_reg.withdraw(demand_depot_id, &"wood", resource_reg.get_balance(demand_depot_id, &"wood"))

	depots = [
		{"id": supply_depot_id, "coord": supply_depot_coord, "type": &"SUPPLY", "resource_type": &"wood"},
		{"id": demand_depot_id, "coord": demand_depot_coord, "type": &"DEMAND", "resource_type": &"wood"}
	]

	# Register agent
	sequencer.register_goal(GoalRestockCargo.new())
	sequencer.register_goal(GoalDeliverCargo.new())

	sequencer.register_action(ActionNavigateTo.new())
	sequencer.register_action(ActionClaimDepot.new())
	sequencer.register_action(ActionWithdrawCargo.new())
	sequencer.register_action(ActionDepositCargo.new())
	sequencer.register_action(ActionReleaseDepot.new())

	event_log.text = ""
	_update_ui()
	grid_canvas.queue_redraw()

func _on_grid_canvas_draw() -> void:
	var cell_size = 40.0
	var offset = Vector2((grid_canvas.size.x - 400.0) / 2.0, (grid_canvas.size.y - 400.0) / 2.0)
	if offset.x < 0: offset.x = 0
	if offset.y < 0: offset.y = 0

	# Background
	grid_canvas.draw_rect(Rect2(offset, Vector2(400, 400)), Color("#1e1e24"))

	# Grid Lines
	for x in range(11):
		grid_canvas.draw_line(offset + Vector2(x * cell_size, 0), offset + Vector2(x * cell_size, 400), Color("#3a3a44", 0.5), 1.0)
	for y in range(11):
		grid_canvas.draw_line(offset + Vector2(0, y * cell_size), offset + Vector2(400, y * cell_size), Color("#3a3a44", 0.5), 1.0)

	# Depots
	var supply_rect = Rect2(offset + Vector2(supply_depot_coord.x * cell_size, supply_depot_coord.y * cell_size), Vector2(cell_size, cell_size))
	grid_canvas.draw_rect(supply_rect, Color("#2ecc71"))
	var default_font = ThemeDB.fallback_font
	grid_canvas.draw_string(default_font, supply_rect.position + Vector2(2, 15), "S: %d" % resource_reg.get_balance(supply_depot_id, &"wood"), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

	var demand_rect = Rect2(offset + Vector2(demand_depot_coord.x * cell_size, demand_depot_coord.y * cell_size), Vector2(cell_size, cell_size))
	grid_canvas.draw_rect(demand_rect, Color("#e67e22"))
	grid_canvas.draw_string(default_font, demand_rect.position + Vector2(2, 15), "D: %d" % resource_reg.get_balance(demand_depot_id, &"wood"), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

	# Reservation Indicators
	if reservation_reg.get_claimant(supply_depot_id) != 0:
		grid_canvas.draw_rect(supply_rect, Color("#e74c3c"), false, 3.0)
	if reservation_reg.get_claimant(demand_depot_id) != 0:
		grid_canvas.draw_rect(demand_rect, Color("#e74c3c"), false, 3.0)

	# Pawn
	var pawn_center = offset + Vector2(pawn_coord.x * cell_size + cell_size/2.0, pawn_coord.y * cell_size + cell_size/2.0)
	grid_canvas.draw_circle(pawn_center, cell_size * 0.4, Color("#3498db"))
	grid_canvas.draw_string(default_font, pawn_center - Vector2(18, 5), "P: %d" % resource_reg.get_balance(pawn_container_id, &"wood"), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

func _step_simulation() -> void:
	sim_clock.advance(1)
	var current_tick = sim_clock.get_tick()
	last_tick = current_tick

	reservation_reg.tick_prune_expired(current_tick)

	var pawn_cargo = resource_reg.get_balance(pawn_container_id, &"wood")
	var target_depot_info: Dictionary = {}
	if pawn_cargo == 0:
		target_depot_info = TargetDepotResolver.resolve_best_supply(pawn_coord, &"wood", 1, depots, reservation_reg, resource_reg, pawn_id)
	else:
		target_depot_info = TargetDepotResolver.resolve_best_demand(pawn_coord, depots, reservation_reg, pawn_id)

	var snapshot = LogisticsStateMapper.build_snapshot(pawn_id, pawn_coord, pawn_container_id, resource_reg, reservation_reg, target_depot_info)
	var context = {
		"pawn_id": pawn_id,
		"pawn_coord": pawn_coord,
		"pawn_container_id": pawn_container_id,
		"target_depot": target_depot_info
	}

	sequencer.tick(current_tick, snapshot, context)
	command_bus.flush_tick(current_tick)
	event_bus.flush_queue()

	_update_ui()
	grid_canvas.queue_redraw()

func _update_ui() -> void:
	label_tick.text = "Tick: %d" % last_tick

	var active_goal = sequencer.active_goal
	if active_goal != null:
		label_goal.text = "Goal: %s" % active_goal.goal_name
	else:
		label_goal.text = "Goal: None"

	var active_binding = sequencer.active_binding
	if active_binding != null:
		label_action.text = "Action: %s" % active_binding.get_action_name()
	else:
		label_action.text = "Action: None"

	var active_plan = sequencer.active_plan
	if active_plan != null and not active_plan.bindings.is_empty():
		var steps_str = ""
		for binding in active_plan.bindings:
			steps_str += str(binding.action.action_name) + ", "
		label_plan.text = "Plan: %s" % steps_str
	else:
		label_plan.text = "Plan: None"

	label_inv_courier.text = "Courier Wood: %d" % resource_reg.get_balance(pawn_container_id, &"wood")
	label_inv_supply.text = "Supply Wood: %d" % resource_reg.get_balance(supply_depot_id, &"wood")
	label_inv_demand.text = "Demand Wood: %d" % resource_reg.get_balance(demand_depot_id, &"wood")

func _on_event_emitted(payload: Dictionary) -> void:
	var event_type = payload.get("event_type", "UNKNOWN")
	var source_id = payload.get("source_entity_id", 0)
	var tick = payload.get("tick_timestamp", 0)
	var data = payload.get("event_data", {})
	event_log.text += "[Tick %d] (%s) Source: %d -> %s\n" % [tick, event_type, source_id, str(data)]
	event_log.scroll_to_line(event_log.get_line_count() - 1)

# --- UI Callbacks ---
func _on_step_button_pressed() -> void:
	_step_simulation()

func _on_play_pause_button_pressed() -> void:
	is_playing = !is_playing
	if is_playing:
		timer.start()
	else:
		timer.stop()

func _on_timer_timeout() -> void:
	_step_simulation()

func _on_reset_button_pressed() -> void:
	_reset_simulation()

func _on_speed_changed(index: int) -> void:
	match index:
		0: timer.wait_time = 1.0 # 1x
		1: timer.wait_time = 0.5 # 2x
		2: timer.wait_time = 0.2 # 5x
		3: timer.wait_time = 0.1 # 10x

# --- Command Handlers ---
func _pass_validator(packet: Dictionary) -> Dictionary:
	return command_bus._create_error_result(packet.get("cmd_id", 0), 0, &"OK")

func _handle_spatial_relocation(packet: Dictionary) -> Dictionary:
	var new_coord = packet.get("to_coord", Vector2i(-1, -1))
	if new_coord != Vector2i(-1, -1):
		spatial_reg.clear_cell(pawn_coord)
		pawn_coord = new_coord
		spatial_reg.set_occupant(pawn_coord, pawn_id)
	return command_bus._create_error_result(packet.get("cmd_id", 0), 0, &"")

func _handle_reservation_claim(packet: Dictionary) -> Dictionary:
	var claimant_id = packet.get("claimant_id", 0)
	var target_id = packet.get("target_id", 0)
	var claim_type = packet.get("claim_type", 0)
	var duration = packet.get("duration", 0)
	reservation_reg.try_claim(claimant_id, target_id, claim_type, duration, last_tick)
	return command_bus._create_error_result(packet.get("cmd_id", 0), 0, &"")

func _handle_reservation_release(packet: Dictionary) -> Dictionary:
	var claimant_id = packet.get("claimant_id", 0)
	var target_id = packet.get("target_id", 0)
	reservation_reg.release_claim(claimant_id, target_id)
	return command_bus._create_error_result(packet.get("cmd_id", 0), 0, &"")

func _handle_resource_transfer(packet: Dictionary) -> Dictionary:
	var src_id = packet.get("source_id", 0)
	var dst_id = packet.get("destination_id", 0)
	var type = packet.get("resource_type", &"")
	var amount = packet.get("amount", 0)
	resource_reg.transfer(src_id, dst_id, type, amount)
	return command_bus._create_error_result(packet.get("cmd_id", 0), 0, &"")
