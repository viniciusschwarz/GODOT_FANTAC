class_name TestLogisticsDomain
extends SceneTree

class MockCommandBus extends RefCounted:
	var submitted_commands: Array[Dictionary] = []
	func submit(command: Dictionary) -> void:
		submitted_commands.append(command)

class MockReservationRegistry extends RefCounted:
	var claims: Dictionary = {}
	func get_claimant(depot_id: int) -> int:
		return claims.get(depot_id, 0)
	func set_claimant(depot_id: int, claimant_id: int) -> void:
		claims[depot_id] = claimant_id

class MockResourceRegistry extends RefCounted:
	var balances: Dictionary = {}
	func get_balance(container_id: int, resource_type: StringName) -> int:
		var container = balances.get(container_id, {})
		return container.get(resource_type, 0)
	func set_balance(container_id: int, resource_type: StringName, amount: int) -> void:
		var container = balances.get(container_id, {})
		container[resource_type] = amount
		balances[container_id] = container

func _init() -> void:
	print("[TEST] Running Logistics Domain Tests...")

	test_target_depot_resolver()
	test_logistics_state_mapper()
	test_action_navigate_to()
	test_e2e_goap_plan()

	print("[TEST] All tests passed.")
	quit(0)

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		printerr("[FAIL] " + message)
		quit(1)

func test_target_depot_resolver() -> void:
	var resolver = TargetDepotResolver.new()
	var res_reg = MockReservationRegistry.new()
	var rec_reg = MockResourceRegistry.new()

	var depots: Array[Dictionary] = [
		{"id": 1, "type": &"SUPPLY", "coord": Vector2i(10, 10)},
		{"id": 2, "type": &"SUPPLY", "coord": Vector2i(5, 5)},
		{"id": 3, "type": &"DEMAND", "coord": Vector2i(20, 20)}
	]

	rec_reg.set_balance(1, &"wood", 50)
	rec_reg.set_balance(2, &"wood", 0) # empty

	res_reg.set_claimant(1, 999) # reserved by someone else

	var best_supply = resolver.resolve_best_supply(Vector2i(0, 0), &"wood", 10, depots, res_reg, rec_reg, 123)
	_assert_true(best_supply.is_empty(), "Should not find supply since depot 1 is reserved and 2 is empty")

	res_reg.set_claimant(1, 0) # unreserve
	best_supply = resolver.resolve_best_supply(Vector2i(0, 0), &"wood", 10, depots, res_reg, rec_reg, 123)
	_assert_true(best_supply.get("id") == 1, "Should find depot 1 now")

	var best_demand = resolver.resolve_best_demand(Vector2i(10, 10), depots, res_reg, 123)
	_assert_true(best_demand.get("id") == 3, "Should find demand depot")

func test_logistics_state_mapper() -> void:
	var mapper = LogisticsStateMapper.new()
	var res_reg = MockReservationRegistry.new()
	var rec_reg = MockResourceRegistry.new()

	rec_reg.set_balance(100, &"wood", 25)
	res_reg.set_claimant(10, 123)

	var snapshot = mapper.build_snapshot(123, Vector2i(5, 5), 100, rec_reg, res_reg, {"id": 10, "coord": Vector2i(5, 5)})

	_assert_true(snapshot.get_number(&"cargo_balance") == 25.0, "Cargo balance should be 25")
	_assert_true(snapshot.get_symbol(&"pawn_at_target") == true, "Pawn at target should be true")
	_assert_true(snapshot.get_symbol(&"has_depot_claim") == true, "Has claim should be true")

func test_action_navigate_to() -> void:
	var action = ActionNavigateTo.new()
	var cmd_bus = MockCommandBus.new()
	var binding = GoapActionBinding.new(action, {&"target_coord": Vector2i(2, 1)})
	var context = {"pawn_id": 1, "pawn_coord": Vector2i(0, 0)}

	var status = action.on_step(1, binding, context, cmd_bus)
	_assert_true(status == GoapTypes.ActionStatus.RUNNING, "Step 1 should be RUNNING")
	_assert_true(context["pawn_coord"] == Vector2i(1, 0), "Context should update X first")

	status = action.on_step(2, binding, context, cmd_bus)
	_assert_true(status == GoapTypes.ActionStatus.RUNNING, "Step 2 should be RUNNING")
	_assert_true(context["pawn_coord"] == Vector2i(2, 0), "Context should update X first")

	status = action.on_step(3, binding, context, cmd_bus)
	_assert_true(status == GoapTypes.ActionStatus.COMPLETED, "Step 3 should be COMPLETED")
	_assert_true(context["pawn_coord"] == Vector2i(2, 1), "Context should update Y")

	_assert_true(cmd_bus.submitted_commands.size() == 3, "Should submit 3 commands")

func test_e2e_goap_plan() -> void:
	var planner = GoapPlanner.new()
	var actions: Array[GoapAction] = [
		ActionNavigateTo.new(),
		ActionClaimDepot.new(),
		ActionWithdrawCargo.new(),
		ActionReleaseDepot.new()
	]
	var goal = GoalRestockCargo.new()

	var snapshot = GoapStateSnapshot.new()
	snapshot.set_number(&"cargo_balance", 0.0)
	snapshot.set_symbol(&"pawn_at_target", false)
	snapshot.set_symbol(&"has_depot_claim", false)

	var context = {
		&"target_coord": Vector2i(10, 10),
		&"depot_id": 1,
		&"resource_type": &"wood",
		&"amount": 10
	}


	# For the planner to evaluate the graph accurately, it just uses the action's base effects and preconditions.
	# By default `GoapAction.generate_bindings` returns an empty parameter binding `{}`,
	# which is perfectly fine for the graph topological test.

	var plan = planner.plan(snapshot, goal, actions, context)

	_assert_true(plan.status == GoapPlan.Status.SOLVED, "Plan status should be SOLVED")
	_assert_true(plan.bindings.size() == 4, "Plan should have exactly 4 steps: Navigate -> Claim -> Withdraw -> Release")
