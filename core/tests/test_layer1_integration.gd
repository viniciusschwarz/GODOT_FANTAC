# Test
# &"C:\Users\vinic\Documents\DEV\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe" --headless -s res://core/tests/test_layer1_integration.gd
extends SceneTree

var clock: SimClock
var cmd_bus: CommandBus
var event_bus: EventBus
var save_reg: SaveRegistry

var spatial_reg: SpatialCellRegistry
var resource_reg: ResourceContainerRegistry
var reservation_reg: ReservationRegistry

var _command_id_counter: int = 1

func _init() -> void:
	clock = SimClock.new()
	cmd_bus = CommandBus.new()
	event_bus = EventBus.new()
	save_reg = SaveRegistry.new()

	spatial_reg = SpatialCellRegistry.new()
	spatial_reg.init(10, 10)
	resource_reg = ResourceContainerRegistry.new()
	reservation_reg = ReservationRegistry.new()

	_register_commands()
	_register_saves()

	_run_scenario()

func _assert_true(condition: bool, test_name: String) -> void:
	if not condition:
		printerr("[FAIL] " + test_name)
		quit(1)

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
	cmd_bus.register_command(&"SPATIAL_RELOCATION", _validate_spatial_relocation, _execute_spatial_relocation)
	cmd_bus.register_command(&"RESERVATION_CLAIM", _validate_reservation_claim, _execute_reservation_claim)
	cmd_bus.register_command(&"RESOURCE_TRANSFER", _validate_resource_transfer, _execute_resource_transfer)

func _register_saves() -> void:
	save_reg.register_domain(&"SPATIAL", Callable(spatial_reg, "get_save_state"), Callable(spatial_reg, "load_save_state"))
	save_reg.register_domain(&"RESOURCE", Callable(resource_reg, "get_save_state"), Callable(resource_reg, "load_save_state"))
	save_reg.register_domain(&"RESERVATION", Callable(reservation_reg, "get_save_state"), Callable(reservation_reg, "load_save_state"))

# --- SPATIAL RELOCATION ---
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
	return _success_res(packet)

# --- RESERVATION CLAIM ---
func _validate_reservation_claim(packet: Dictionary) -> Dictionary:
	# Validation handled mostly in execute for atomicity in this mock
	return _success_res(packet)

func _execute_reservation_claim(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	var res = reservation_reg.try_claim(pl["claimant_id"], pl["target_id"], pl["claim_type"], pl["duration"], clock.current_tick)
	if not res:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_TARGET_LOCKED, &"TARGET_LOCKED")
	return _success_res(packet)

# --- RESOURCE TRANSFER ---
func _validate_resource_transfer(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	if resource_reg.get_balance(pl["src_id"], pl["resource_type"]) < pl["amount"]:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_INSUFFICIENT_FUNDS, &"INSUFFICIENT_BALANCE")
	return _success_res(packet)

func _execute_resource_transfer(packet: Dictionary) -> Dictionary:
	var pl = packet["payload"]
	var res = resource_reg.transfer(pl["src_id"], pl["dst_id"], pl["resource_type"], pl["amount"])
	if not res:
		return _error_res(packet, CoreEnums.ExecutionStatusCode.REJECTED_INSUFFICIENT_FUNDS, &"TRANSFER_FAILED")
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

func _run_scenario() -> void:
	# Setup Depot A (100) at (0,0) with 50 wood
	resource_reg.create_container(100)
	resource_reg.deposit(100, &"WOOD", 50)

	# Setup Depot B (200) at (0,2) with 0 wood
	resource_reg.create_container(200)

	# Setup Worker (1) at (0,0)
	resource_reg.create_container(1)
	spatial_reg.set_occupant(Vector2i(0, 0), 1)

	var res: Dictionary
	var results: Array

	# Step 1 (Tick 1): Worker reserves Depot A
	clock.current_tick = 1
	var c1 = _create_cmd(&"RESERVATION_CLAIM", {"claimant_id": 1, "target_id": 100, "claim_type": CoreEnums.ReservationClaimType.EXCLUSIVE_WRITE, "duration": 10}, 1)
	cmd_bus.submit(c1)
	results = cmd_bus.flush_tick(1)
	_assert_true(results[0]["status_code"] == CoreEnums.ExecutionStatusCode.SUCCESS, "Worker reserves Depot A")

	# Step 2 (Tick 2): Competitor Worker 2 attempts exclusive reservation on Depot A
	clock.current_tick = 2
	var c2 = _create_cmd(&"RESERVATION_CLAIM", {"claimant_id": 2, "target_id": 100, "claim_type": CoreEnums.ReservationClaimType.EXCLUSIVE_WRITE, "duration": 10}, 2)
	cmd_bus.submit(c2)
	results = cmd_bus.flush_tick(2)
	_assert_true(results[0]["status_code"] == CoreEnums.ExecutionStatusCode.REJECTED_TARGET_LOCKED, "Competitor rejected")

	# Step 3 (Tick 3): Worker transfers 10 WOOD from Depot A to Worker container
	clock.current_tick = 3
	var c3 = _create_cmd(&"RESOURCE_TRANSFER", {"src_id": 100, "dst_id": 1, "resource_type": &"WOOD", "amount": 10}, 3)
	cmd_bus.submit(c3)
	cmd_bus.flush_tick(3)
	_assert_true(resource_reg.get_balance(100, &"WOOD") == 40, "Depot A has 40 wood")
	_assert_true(resource_reg.get_balance(1, &"WOOD") == 10, "Worker has 10 wood")

	# Step 4 (Tick 4): Worker moves to (0,1)
	clock.current_tick = 4
	var c4 = _create_cmd(&"SPATIAL_RELOCATION", {"entity_id": 1, "from": Vector2i(0, 0), "to": Vector2i(0, 1)}, 4)
	cmd_bus.submit(c4)
	cmd_bus.flush_tick(4)
	_assert_true(spatial_reg.get_occupant(Vector2i(0, 1)) == 1, "Worker moved to (0,1)")
	_assert_true(spatial_reg.get_occupant(Vector2i(0, 0)) == 0, "(0,0) is clear")

	# Step 5 (Tick 5): Snapshot
	clock.current_tick = 5
	var snapshot = save_reg.capture_snapshot(5)

	# Step 6: Reset/wipe simulation state completely. Restore snapshot.
	spatial_reg.init(10, 10)
	resource_reg = ResourceContainerRegistry.new()
	reservation_reg = ReservationRegistry.new()
	# Update callbacks since object references changed
	_register_saves()

	_assert_true(save_reg.restore_snapshot(snapshot), "Restore snapshot successful")
	clock.current_tick = snapshot["current_tick"]
	_assert_true(clock.current_tick == 5, "Tick is 5")
	_assert_true(resource_reg.get_balance(100, &"WOOD") == 40, "Restored Depot A has 40 wood")
	_assert_true(resource_reg.get_balance(1, &"WOOD") == 10, "Restored Worker has 10 wood")
	_assert_true(spatial_reg.get_occupant(Vector2i(0, 1)) == 1, "Restored Worker at (0,1)")

	# Step 7 (Tick 6): Worker moves to (0,2) (Depot B)
	clock.current_tick = 6
	var c7 = _create_cmd(&"SPATIAL_RELOCATION", {"entity_id": 1, "from": Vector2i(0, 1), "to": Vector2i(0, 2)}, 6)
	cmd_bus.submit(c7)
	cmd_bus.flush_tick(6)
	_assert_true(spatial_reg.get_occupant(Vector2i(0, 2)) == 1, "Worker at (0,2)")

	# Step 8 (Tick 7): Worker transfers 10 WOOD into Depot B
	clock.current_tick = 7
	var c8 = _create_cmd(&"RESOURCE_TRANSFER", {"src_id": 1, "dst_id": 200, "resource_type": &"WOOD", "amount": 10}, 7)
	cmd_bus.submit(c8)
	cmd_bus.flush_tick(7)
	_assert_true(resource_reg.get_balance(200, &"WOOD") == 10, "Depot B has 10 wood")
	_assert_true(resource_reg.get_balance(1, &"WOOD") == 0, "Worker has 0 wood")

	# Step 9 (Tick 8): Worker releases reservation on Depot A
	clock.current_tick = 8
	var c9 = reservation_reg.release_claim(1, 100)
	_assert_true(c9, "Claim released")
	_assert_true(not reservation_reg.is_reserved(100), "Depot A lock released")

	print("[INTEGRATION PASS] Worker & Depots headless simulation passed cleanly.")
	quit(0)
