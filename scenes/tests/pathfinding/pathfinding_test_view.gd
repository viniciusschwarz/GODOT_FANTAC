extends Control

const CommandBus = preload("res://core/command/command_bus.gd")
const EventBus = preload("res://core/event/event_bus.gd")
const SimClock = preload("res://core/time/sim_clock.gd")
const CoreEnums = preload("res://core/schemas/core_enums.gd")

const SpatialCellRegistry = preload("res://simulation/spatial/spatial_cell_registry.gd")
const ResourceContainerRegistry = preload("res://simulation/resource/resource_container_registry.gd")
const ReservationRegistry = preload("res://simulation/reservation/reservation_registry.gd")

const SpatialNavGraphRegistry = preload("res://framework/pathfinding/graph/spatial_nav_graph_registry.gd")
const AsymmetricLinkRegistry = preload("res://framework/pathfinding/topology/asymmetric_link_registry.gd")
const NavTopologyContract = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd")
const NavigationProfileDefinition = preload("res://framework/pathfinding/graph/navigation_profile_definition.gd")
const AStar2DSolver = preload("res://framework/pathfinding/solvers/astar_2d_solver.gd")
const FlowFieldSolver = preload("res://framework/pathfinding/solvers/flow_field_solver.gd")
const TacticalQueryResolver = preload("res://framework/pathfinding/evaluators/tactical_query_resolver.gd")

const GoapSequencer = preload("res://framework/goap/sequencer/goap_sequencer.gd")
const GoapPlanner = preload("res://framework/goap/planner/goap_planner.gd")
const GoapGoalArbitrator = preload("res://framework/goap/goals/goap_goal_arbitrator.gd")
const GoapAction = preload("res://framework/goap/actions/goap_action.gd")
const GoapActionBinding = preload("res://framework/goap/actions/goap_action_binding.gd")
const GoapSymbolicEffect = preload("res://framework/goap/effects/goap_symbolic_effect.gd")
const GoapTypes = preload("res://framework/goap/common/goap_types.gd")

const GoalRestockCargo = preload("res://game/logistics/goals/goal_restock_cargo.gd")
const GoalDeliverCargo = preload("res://game/logistics/goals/goal_deliver_cargo.gd")
const ActionClaimDepot = preload("res://game/logistics/actions/action_claim_depot.gd")
const ActionWithdrawCargo = preload("res://game/logistics/actions/action_withdraw_cargo.gd")
const ActionDepositCargo = preload("res://game/logistics/actions/action_deposit_cargo.gd")
const ActionReleaseDepot = preload("res://game/logistics/actions/action_release_depot.gd")

const TargetDepotResolver = preload("res://game/logistics/evaluators/target_depot_resolver.gd")
const LogisticsStateMapper = preload("res://game/logistics/evaluators/logistics_state_mapper.gd")
const GoapStateSnapshot = preload("res://framework/goap/common/goap_state_snapshot.gd")

class PathfindingActionNavigateTo extends GoapAction:
	var nav_graph: SpatialNavGraphRegistry
	var profile: NavigationProfileDefinition
	var link_reg: AsymmetricLinkRegistry

	func _init(p_nav_graph: SpatialNavGraphRegistry, p_profile: NavigationProfileDefinition, p_link_reg: AsymmetricLinkRegistry):
		action_name = &"NavigateTo"
		effects.append(GoapSymbolicEffect.new(&"pawn_at_target", GoapTypes.SymbolicEffectOp.ASSIGN, true))
		nav_graph = p_nav_graph
		profile = p_profile
		link_reg = p_link_reg

	func on_enter(binding: GoapActionBinding, context: Dictionary) -> void:
		context["active_path"] = [] as Array[Vector2i]

	func on_step(tick: int, binding: GoapActionBinding, context: Dictionary, cmd_bus: Object = null) -> int:
		var target_coord: Vector2i = binding.get_param(&"target_coord", Vector2i(-1, -1))
		if target_coord == Vector2i(-1, -1) and context.has("target_depot"):
			target_coord = context["target_depot"].get("coord", Vector2i(-1, -1))

		var current_coord: Vector2i = context.get("pawn_coord", Vector2i(-1, -1))
		if target_coord == Vector2i(-1, -1) or current_coord == -Vector2i.ONE:
			return GoapTypes.ActionStatus.FAILED

		if current_coord == target_coord:
			return GoapTypes.ActionStatus.COMPLETED

		var active_path: Array[Vector2i] = context.get("active_path", [])

		# Replan if path is empty or next step is blocked
		var needs_replan = false
		if active_path.is_empty():
			needs_replan = true
		else:
			var next_step = active_path[0]
			if not nav_graph.is_cell_traversable(next_step, profile.required_mask, profile.ignored_mask):
				needs_replan = true

		if needs_replan:
			active_path = AStar2DSolver.find_path(current_coord, target_coord, nav_graph, profile, link_reg)
			context["active_path"] = active_path
			if active_path.is_empty():
				return GoapTypes.ActionStatus.FAILED

		var next_step = active_path.pop_front()

		# If the first node in path is the current node (sometimes returned by solver), get the next one
		if next_step == current_coord:
			if active_path.is_empty():
				return GoapTypes.ActionStatus.COMPLETED
			next_step = active_path.pop_front()

		if cmd_bus != null:
			cmd_bus.submit({
				"command_id": 1, # Auto-assigned by framework/command_bus but giving 1 is safe
				"priority": CoreEnums.ExecutionPriority.INPUT_DIRECT,
				"command_type": &"SPATIAL_RELOCATION",
				"issuer_id": context.get("pawn_id", 0),
				"target_tick": tick,
				"payload": {
					"from_coord": current_coord,
					"to_coord": next_step
				}
			})

		context["pawn_coord"] = next_step
		context["active_path"] = active_path

		if next_step == target_coord:
			return GoapTypes.ActionStatus.COMPLETED
		else:
			return GoapTypes.ActionStatus.RUNNING

# Nodes
@onready var grid_canvas = $HSplitContainer/LeftPanel/GridCanvas
@onready var label_tick = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/TickLabel
@onready var label_goal = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/GoalLabel
@onready var label_action = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/ActionLabel
@onready var label_plan = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/PlanLabel
@onready var label_inv_courier = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/InvCourierLabel
@onready var label_path_nodes = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/PathNodesLabel
@onready var event_log = $HSplitContainer/RightPanel/EventLog
@onready var timer = $Timer

@onready var check_clearance = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/HBoxContainer2/CheckClearance
@onready var check_flow_field = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/HBoxContainer2/CheckFlowField
@onready var check_los = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/HBoxContainer2/CheckLoS
@onready var option_speed = $HSplitContainer/RightPanel/Dashboard/VBoxContainer/HBoxContainer/SpeedOption

# Core logic
var command_bus: CommandBus
var event_bus: EventBus
var sim_clock: SimClock

var spatial_reg: SpatialCellRegistry
var resource_reg: ResourceContainerRegistry
var reservation_reg: ReservationRegistry

var nav_graph: SpatialNavGraphRegistry
var link_reg: AsymmetricLinkRegistry
var nav_profile: NavigationProfileDefinition

var sequencer: GoapSequencer
var planner: GoapPlanner
var arbitrator: GoapGoalArbitrator

var pawn_id: int = 1
var pawn_container_id: int = 1
var pawn_coord: Vector2i = Vector2i(0, 0)
var current_context: Dictionary = {}

var supply_depot_id: int = 101
var supply_depot_coord: Vector2i = Vector2i(1, 1)

var demand_depot_id: int = 102
var demand_depot_coord: Vector2i = Vector2i(10, 10)

var depots: Array[Dictionary] = []
var active_flow_field: PackedVector2Array = PackedVector2Array()

var last_tick: int = 0
var is_playing: bool = false
var cell_size: float = 40.0

func _ready() -> void:
	grid_canvas.draw.connect(_on_grid_canvas_draw)

	option_speed.add_item("1x")
	option_speed.add_item("2x")
	option_speed.add_item("5x")
	option_speed.add_item("10x")
	option_speed.selected = 0

	check_clearance.toggled.connect(func(v): grid_canvas.queue_redraw())
	check_flow_field.toggled.connect(func(v): grid_canvas.queue_redraw())
	check_los.toggled.connect(func(v): grid_canvas.queue_redraw())

	_reset_simulation()

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
	spatial_reg.init(12, 12)

	resource_reg = ResourceContainerRegistry.new()
	reservation_reg = ReservationRegistry.new()

	nav_graph = SpatialNavGraphRegistry.new()
	nav_graph.initialize_grid(12, 12, NavTopologyContract.TopologyType.ORTHOGONAL_8)
	link_reg = AsymmetricLinkRegistry.new()

	nav_profile = NavigationProfileDefinition.new()
	nav_profile.allows_diagonal = true
	nav_profile.allow_corner_cutting = false

	# Configure Terrain
	# Mud
	for y in range(5, 8):
		for x in range(5, 8):
			nav_graph.set_cell_cost(Vector2i(x, y), 3.0)

	# Wall
	for y in range(2, 10):
		nav_graph.set_cell_mask(Vector2i(4, y), NavTopologyContract.CellMask.SOLID, true)

	# Teleporter
	link_reg.register_link(Vector2i(2, 6), Vector2i(8, 6), 1.0, 0, false)

	nav_graph.recalculate_clearance()

	planner = GoapPlanner.new()
	arbitrator = GoapGoalArbitrator.new()
	sequencer = GoapSequencer.new(pawn_id, planner, arbitrator, command_bus, event_bus)

	# Register handlers
	command_bus.register_command(&"SPATIAL_RELOCATION", _pass_validator, _handle_spatial_relocation)
	command_bus.register_command(&"RESERVATION_CLAIM", _pass_validator, _handle_reservation_claim)
	command_bus.register_command(&"RESERVATION_RELEASE", _pass_validator, _handle_reservation_release)
	command_bus.register_command(&"RESOURCE_TRANSFER", _pass_validator, _handle_resource_transfer)
	command_bus.register_command(&"NAV_SET_CELL_MASK", _pass_validator, _handle_nav_set_cell_mask)
	command_bus.register_command(&"NAV_SET_CELL_COST", _pass_validator, _handle_nav_set_cell_cost)

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

	sequencer.register_action(PathfindingActionNavigateTo.new(nav_graph, nav_profile, link_reg))
	sequencer.register_action(ActionClaimDepot.new())
	sequencer.register_action(ActionWithdrawCargo.new())
	sequencer.register_action(ActionDepositCargo.new())
	sequencer.register_action(ActionReleaseDepot.new())

	event_log.text = ""

	current_context = {
		"pawn_id": pawn_id,
		"pawn_coord": pawn_coord,
		"pawn_container_id": pawn_container_id,
		"active_path": []
	}

	_update_flow_field()
	_update_ui()
	grid_canvas.queue_redraw()

func _update_flow_field() -> void:
	var target_coord = demand_depot_coord
	if current_context.has("target_depot") and current_context["target_depot"].has("coord"):
		target_coord = current_context["target_depot"]["coord"]

	var integration_field = FlowFieldSolver.generate_integration_field([target_coord], nav_graph, nav_profile)
	active_flow_field = FlowFieldSolver.generate_vector_field(integration_field, nav_graph, nav_profile)

func _on_grid_canvas_draw() -> void:
	var offset = Vector2((grid_canvas.size.x - (12 * cell_size)) / 2.0, (grid_canvas.size.y - (12 * cell_size)) / 2.0)
	if offset.x < 0: offset.x = 0
	if offset.y < 0: offset.y = 0

	# Background & Terrain
	for y in range(12):
		for x in range(12):
			var c = Vector2i(x, y)
			var rect = Rect2(offset + Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))

			var cell_color = Color("#1e1e24")

			if (nav_graph.get_cell_mask(c) & NavTopologyContract.CellMask.SOLID) != 0:
				cell_color = Color("#555555")
			elif nav_graph.get_cell_cost(c) > 1.0:
				cell_color = Color("#5c4033")

			grid_canvas.draw_rect(rect, cell_color)
			grid_canvas.draw_rect(rect, Color("#3a3a44", 0.5), false, 1.0) # Grid lines

	var default_font = ThemeDB.fallback_font

	# Depots
	var supply_rect = Rect2(offset + Vector2(supply_depot_coord.x * cell_size, supply_depot_coord.y * cell_size), Vector2(cell_size, cell_size))
	grid_canvas.draw_rect(supply_rect, Color("#2ecc71"))
	grid_canvas.draw_string(default_font, supply_rect.position + Vector2(2, 15), "S: %d" % resource_reg.get_balance(supply_depot_id, &"wood"), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

	var demand_rect = Rect2(offset + Vector2(demand_depot_coord.x * cell_size, demand_depot_coord.y * cell_size), Vector2(cell_size, cell_size))
	grid_canvas.draw_rect(demand_rect, Color("#e67e22"))
	grid_canvas.draw_string(default_font, demand_rect.position + Vector2(2, 15), "D: %d" % resource_reg.get_balance(demand_depot_id, &"wood"), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

	# Asymmetric Link
	var link_start = offset + Vector2(2 * cell_size + cell_size/2.0, 6 * cell_size + cell_size/2.0)
	var link_end = offset + Vector2(8 * cell_size + cell_size/2.0, 6 * cell_size + cell_size/2.0)
	grid_canvas.draw_line(link_start, link_end, Color.CYAN, 2.0)
	grid_canvas.draw_circle(link_end, 5.0, Color.CYAN)

	# Active Path Overlay
	if current_context.has("active_path") and not current_context["active_path"].is_empty():
		var path: Array[Vector2i] = current_context["active_path"]
		if path.size() > 0:
			var points = PackedVector2Array()
			points.append(offset + Vector2(pawn_coord.x * cell_size + cell_size/2.0, pawn_coord.y * cell_size + cell_size/2.0))
			for c in path:
				points.append(offset + Vector2(c.x * cell_size + cell_size/2.0, c.y * cell_size + cell_size/2.0))
			grid_canvas.draw_polyline(points, Color.YELLOW_GREEN, 2.0)

	# LoS
	if check_los.button_pressed:
		var los_cells = TacticalQueryResolver.calculate_field_of_view(pawn_coord, 5, nav_graph, NavTopologyContract.CellMask.SOLID)
		var los_color = Color(0.2, 0.6, 1.0, 0.18)
		for c in los_cells:
			var rect = Rect2(offset + Vector2(c.x * cell_size, c.y * cell_size), Vector2(cell_size, cell_size))
			grid_canvas.draw_rect(rect, los_color)

	# Pawn
	var pawn_center = offset + Vector2(pawn_coord.x * cell_size + cell_size/2.0, pawn_coord.y * cell_size + cell_size/2.0)
	grid_canvas.draw_circle(pawn_center, cell_size * 0.4, Color("#3498db"))
	grid_canvas.draw_string(default_font, pawn_center - Vector2(10, 5), "%d" % resource_reg.get_balance(pawn_container_id, &"wood"), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

	# Overlays
	for y in range(12):
		for x in range(12):
			var c = Vector2i(x, y)
			var cell_center = offset + Vector2(x * cell_size + cell_size/2.0, y * cell_size + cell_size/2.0)

			if check_clearance.button_pressed:
				var clearance = nav_graph.get_clearance(c)
				grid_canvas.draw_string(default_font, cell_center + Vector2(-4, 4), str(clearance), HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 1, 1, 0.6))

			if check_flow_field.button_pressed and active_flow_field.size() > 0:
				var dir = FlowFieldSolver.get_flow_direction(c, active_flow_field, nav_graph)
				if dir != Vector2.ZERO:
					grid_canvas.draw_line(cell_center, cell_center + dir * (cell_size * 0.4), Color.MAGENTA, 1.5)
					grid_canvas.draw_circle(cell_center + dir * (cell_size * 0.4), 2.0, Color.MAGENTA)

func _step_simulation() -> void:
	var current_tick: int = sim_clock.step_tick()
	last_tick = current_tick

	reservation_reg.tick_prune_expired(current_tick)

	var pawn_cargo = resource_reg.get_balance(pawn_container_id, &"wood")
	var target_depot_info: Dictionary = {}
	if pawn_cargo == 0:
		target_depot_info = TargetDepotResolver.resolve_best_supply(pawn_coord, &"wood", 1, depots, reservation_reg, resource_reg, pawn_id)
	else:
		target_depot_info = TargetDepotResolver.resolve_best_demand(pawn_coord, depots, reservation_reg, pawn_id)

	var snapshot = LogisticsStateMapper.build_snapshot(pawn_id, pawn_coord, pawn_container_id, resource_reg, reservation_reg, target_depot_info)

	current_context["pawn_coord"] = pawn_coord
	current_context["target_depot"] = target_depot_info

	sequencer.tick(current_tick, snapshot, current_context)
	command_bus.flush_tick(current_tick)
	event_bus.flush_queue()

	# Update pawn coord in case it changed during tick
	pawn_coord = current_context["pawn_coord"]

	_update_flow_field()
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

	var path_nodes = 0
	if current_context.has("active_path"):
		path_nodes = current_context["active_path"].size()
	label_path_nodes.text = "Remaining Path Nodes: %d" % path_nodes

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

func _on_grid_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var offset = Vector2((grid_canvas.size.x - (12 * cell_size)) / 2.0, (grid_canvas.size.y - (12 * cell_size)) / 2.0)
		if offset.x < 0: offset.x = 0
		if offset.y < 0: offset.y = 0

		var local_pos = event.position - offset
		if local_pos.x >= 0 and local_pos.y >= 0 and local_pos.x < 12 * cell_size and local_pos.y < 12 * cell_size:
			var cx = int(local_pos.x / cell_size)
			var cy = int(local_pos.y / cell_size)
			var coord = Vector2i(cx, cy)

			var is_solid = (nav_graph.get_cell_mask(coord) & NavTopologyContract.CellMask.SOLID) != 0
			command_bus.submit({
				"command_id": 2,
				"priority": CoreEnums.ExecutionPriority.INPUT_DIRECT,
				"command_type": &"NAV_SET_CELL_MASK",
				"issuer_id": 0,
				"target_tick": sim_clock.current_tick,
				"payload": {
					"coord": coord,
					"mask_bits": NavTopologyContract.CellMask.SOLID,
					"is_enabled": not is_solid
				}
			})
			command_bus.flush_tick(sim_clock.current_tick)
			_update_flow_field()
			grid_canvas.queue_redraw()

# --- Command Handlers ---
func _pass_validator(packet: Dictionary) -> Dictionary:
	return command_bus._create_error_result(packet.get("cmd_id", 0), 0, &"OK")

func _handle_spatial_relocation(packet: Dictionary) -> Dictionary:
	var payload = packet.get("command_payload", packet.get("payload", packet))
	var new_coord = payload.get("to_coord", Vector2i(-1, -1))
	if new_coord != Vector2i(-1, -1):
		spatial_reg.clear_cell(pawn_coord)
		pawn_coord = new_coord
		spatial_reg.set_occupant(pawn_coord, pawn_id)
	return command_bus._create_error_result(packet.get("cmd_id", packet.get("command_id", 0)), 0, &"")

func _handle_reservation_claim(packet: Dictionary) -> Dictionary:
	var payload = packet.get("command_payload", packet.get("payload", packet))
	var claimant_id = payload.get("claimant_id", 0)
	var target_id = payload.get("target_id", 0)
	var claim_type = payload.get("claim_type", 0)
	var duration = payload.get("duration", 0)
	reservation_reg.try_claim(claimant_id, target_id, claim_type, duration, last_tick)
	return command_bus._create_error_result(packet.get("cmd_id", packet.get("command_id", 0)), 0, &"")

func _handle_reservation_release(packet: Dictionary) -> Dictionary:
	var payload = packet.get("command_payload", packet.get("payload", packet))
	var claimant_id = payload.get("claimant_id", 0)
	var target_id = payload.get("target_id", 0)
	reservation_reg.release_claim(claimant_id, target_id)
	return command_bus._create_error_result(packet.get("cmd_id", packet.get("command_id", 0)), 0, &"")

func _handle_resource_transfer(packet: Dictionary) -> Dictionary:
	var payload = packet.get("command_payload", packet.get("payload", packet))
	var src_id = payload.get("source_id", 0)
	var dst_id = payload.get("destination_id", 0)
	var type = payload.get("resource_type", &"")
	var amount = payload.get("amount", 0)
	resource_reg.transfer(src_id, dst_id, type, amount)
	return command_bus._create_error_result(packet.get("cmd_id", packet.get("command_id", 0)), 0, &"")

func _handle_nav_set_cell_mask(packet: Dictionary) -> Dictionary:
	var payload = packet.get("command_payload", packet.get("payload", packet))
	var coord = payload.get("coord", Vector2i(-1, -1))
	var mask_bits = payload.get("mask_bits", 0)
	var is_enabled = payload.get("is_enabled", false)

	if coord != Vector2i(-1, -1):
		nav_graph.set_cell_mask(coord, mask_bits, is_enabled)
		nav_graph.recalculate_clearance()

	return command_bus._create_error_result(packet.get("cmd_id", packet.get("command_id", 0)), 0, &"")

func _handle_nav_set_cell_cost(packet: Dictionary) -> Dictionary:
	var payload = packet.get("command_payload", packet.get("payload", packet))
	var coord = payload.get("coord", Vector2i(-1, -1))
	var cost = payload.get("cost", 1.0)

	if coord != Vector2i(-1, -1):
		nav_graph.set_cell_cost(coord, cost)

	return command_bus._create_error_result(packet.get("cmd_id", packet.get("command_id", 0)), 0, &"")
