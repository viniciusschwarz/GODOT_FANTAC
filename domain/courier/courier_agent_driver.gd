class_name CourierAgentDriver
extends RefCounted

var _worker_entity_id: int
var _worker_container_id: int
var _command_bus: CommandBus
var _event_bus: EventBus

var _available_actions: Array[GoapActionDefinition] = []
var _active_plan: Array[GoapActionDefinition] = []
var _active_action_index: int = 0
var _command_id_counter: int = 1000

func _init(worker_entity_id: int, worker_container_id: int, cmd_bus: CommandBus, evt_bus: EventBus) -> void:
	_worker_entity_id = worker_entity_id
	_worker_container_id = worker_container_id
	_command_bus = cmd_bus
	_event_bus = evt_bus
	_setup_actions()

func _setup_actions() -> void:
	var travel_supply = GoapActionDefinition.new()
	travel_supply.action_id = &"TRAVEL_TO_SUPPLY"
	travel_supply.effects = {"at_supply": true, "at_demand": false}

	var reserve_supply = GoapActionDefinition.new()
	reserve_supply.action_id = &"CLAIM_RESERVATION"
	reserve_supply.preconditions = {"at_supply": true}
	reserve_supply.effects = {"supply_reserved": true}

	var withdraw = GoapActionDefinition.new()
	withdraw.action_id = &"WITHDRAW_CARGO"
	withdraw.preconditions = {"at_supply": true, "supply_reserved": true}
	withdraw.effects = {"has_wood": true}

	var travel_demand = GoapActionDefinition.new()
	travel_demand.action_id = &"TRAVEL_TO_DEMAND"
	travel_demand.preconditions = {"has_wood": true}
	travel_demand.effects = {"at_demand": true, "at_supply": false}

	var deposit = GoapActionDefinition.new()
	deposit.action_id = &"DEPOSIT_CARGO"
	deposit.preconditions = {"at_demand": true, "has_wood": true}
	deposit.effects = {"wood_delivered": true, "has_wood": false}

	var release_supply = GoapActionDefinition.new()
	release_supply.action_id = &"RELEASE_RESERVATION"
	release_supply.preconditions = {"wood_delivered": true}
	release_supply.effects = {"supply_reserved": false}

	_available_actions = [travel_supply, reserve_supply, withdraw, travel_demand, deposit, release_supply]

func tick(
	current_tick: int,
	worker_coord: Vector2i,
	depot_records: Array[Dictionary],
	spatial_reg: SpatialCellRegistry,
	resource_reg: ResourceContainerRegistry,
	reservation_reg: ReservationRegistry
) -> void:
	var blackboard: Dictionary = CourierSensorEvaluator.evaluate_blackboard(
		_worker_entity_id, _worker_container_id, worker_coord, depot_records, spatial_reg, resource_reg, reservation_reg
	)

	# If no active plan, formulate one
	if _active_plan.is_empty():
		# Formulate new plan
		var current_state: Dictionary = {
			"at_supply": blackboard["at_supply"],
			"at_demand": blackboard["at_demand"],
			"has_wood": blackboard["has_wood"],
			"wood_delivered": blackboard["wood_delivered"],
			"supply_reserved": reservation_reg.is_reserved(blackboard["nearest_valid_supply_depot_id"]) and reservation_reg.get_claimant(blackboard["nearest_valid_supply_depot_id"]) == _worker_entity_id
		}

		var goal_state: Dictionary = {"wood_delivered": true}

		# If we have no wood and there's no valid supply depot, we can't do anything
		if not current_state["has_wood"] and blackboard["nearest_valid_supply_depot_id"] == -1:
			return

		# If we have wood but there's no valid demand depot, we can't do anything
		if current_state["has_wood"] and blackboard["nearest_valid_demand_depot_id"] == -1:
			return

		_active_plan = GoapPlannerEvaluator.plan(current_state, goal_state, _available_actions)
		_active_action_index = 0

		if not _active_plan.is_empty():
			var action_sequence = []
			for action in _active_plan:
				action_sequence.append(action.action_id)

			_event_bus.emit_now({
				"event_type": &"GOAP_PLAN_FORMULATED",
				"tick_timestamp": current_tick,
				"source_entity_id": _worker_entity_id,
				"target_entity_id": 0,
				"event_data": {
					"action_sequence": action_sequence
				}
			})
		else:
			return # Unsolvable

	# Execute the active step
	if _active_action_index < _active_plan.size():
		var current_action = _active_plan[_active_action_index]
		var action_id = current_action.action_id

		if action_id == &"TRAVEL_TO_SUPPLY":
			var target_coord: Vector2i = blackboard["nearest_valid_supply_depot_coord"]
			if _step_towards(worker_coord, target_coord, current_tick):
				_active_action_index += 1
		elif action_id == &"TRAVEL_TO_DEMAND":
			var target_coord: Vector2i = blackboard["nearest_valid_demand_depot_coord"]
			if _step_towards(worker_coord, target_coord, current_tick):
				_active_action_index += 1
		elif action_id == &"CLAIM_RESERVATION":
			var target_id = blackboard["nearest_valid_supply_depot_id"]
			if target_id != -1:
				var cmd = _create_cmd(&"RESERVATION_CLAIM", {
					"claimant_id": _worker_entity_id,
					"target_id": target_id,
					"claim_type": CoreEnums.ReservationClaimType.EXCLUSIVE_WRITE,
					"duration": 50 # Arbitrary long duration
				}, current_tick)
				_command_bus.submit(cmd)
				_active_action_index += 1
			else:
				_force_replan()
		elif action_id == &"WITHDRAW_CARGO":
			var target_id = blackboard["nearest_valid_supply_depot_id"]
			if target_id != -1:
				# Withdraw up to 20 or remaining available
				var available_wood: int = resource_reg.get_balance(target_id, &"WOOD")
				var amount_to_take = min(available_wood, 20)
				var cmd = _create_cmd(&"RESOURCE_TRANSFER", {
					"src_id": target_id,
					"dst_id": _worker_container_id,
					"resource_type": &"WOOD",
					"amount": amount_to_take
				}, current_tick)
				_command_bus.submit(cmd)
				_active_action_index += 1
			else:
				_force_replan()
		elif action_id == &"DEPOSIT_CARGO":
			var target_id = blackboard["nearest_valid_demand_depot_id"]
			if target_id != -1:
				var carried: int = blackboard["carried_wood"]
				var cmd = _create_cmd(&"RESOURCE_TRANSFER", {
					"src_id": _worker_container_id,
					"dst_id": target_id,
					"resource_type": &"WOOD",
					"amount": carried
				}, current_tick)
				_command_bus.submit(cmd)
				_active_action_index += 1
			else:
				_force_replan()
		elif action_id == &"RELEASE_RESERVATION":
			var target_id = blackboard["nearest_valid_supply_depot_id"]
			if target_id != -1:
				var cmd = _create_cmd(&"RESERVATION_RELEASE", {
					"claimant_id": _worker_entity_id,
					"target_id": target_id
				}, current_tick)
				_command_bus.submit(cmd)
			_active_action_index += 1

		# Check if we finished the plan
		if _active_action_index >= _active_plan.size():
			_active_plan.clear()

func _step_towards(current_coord: Vector2i, target_coord: Vector2i, tick: int) -> bool:
	if current_coord == target_coord:
		return true # Reached

	var dx = sign(target_coord.x - current_coord.x)
	var dy = sign(target_coord.y - current_coord.y)
	var next_coord = current_coord + Vector2i(dx, dy)

	var cmd = _create_cmd(&"SPATIAL_RELOCATION", {
		"entity_id": _worker_entity_id,
		"from": current_coord,
		"to": next_coord
	}, tick)
	_command_bus.submit(cmd)

	# We return false because we haven't reached the destination yet, so the GOAP action isn't complete.
	# But wait, next tick we will be at `next_coord`. If it's the target, `current_coord == target_coord` will be true.
	return false

func notify_command_failed() -> void:
	_force_replan()

func _force_replan() -> void:
	_active_plan.clear()
	_active_action_index = 0

func _create_cmd(type: StringName, payload: Dictionary, tick: int) -> Dictionary:
	var packet = {
		"command_id": _command_id_counter,
		"priority": CoreEnums.ExecutionPriority.AGENT_DECISION,
		"command_type": type,
		"issuer_id": _worker_entity_id,
		"target_tick": tick,
		"payload": payload
	}
	_command_id_counter += 1
	return packet
