extends SceneTree

func _init() -> void:
	print("Starting GOAP Phase 2 Tests...")

	test_snapshot_encapsulation()
	test_action_bindings()
	test_dynamic_cost_evaluation()
	test_goal_satisfaction()
	test_goal_utility_arbitration()

	print("[PASS] All GOAP Phase 2 unit tests passed successfully.")
	quit(0)

func _assert_true(condition: bool, test_name: String) -> void:
	if not condition:
		printerr("[FAIL] Assertion failed in: ", test_name)
		quit(1)

func test_snapshot_encapsulation() -> void:
	var snapshot = GoapStateSnapshot.new()

	snapshot.set_symbol(&"test_symbol", true)
	_assert_true(snapshot.has_symbol(&"test_symbol"), "test_snapshot_encapsulation: set_symbol")
	snapshot.erase_symbol(&"test_symbol")
	_assert_true(not snapshot.has_symbol(&"test_symbol"), "test_snapshot_encapsulation: erase_symbol")

	snapshot.set_number(&"test_number", 42.0)
	_assert_true(snapshot.has_number(&"test_number"), "test_snapshot_encapsulation: set_number")
	snapshot.erase_number(&"test_number")
	_assert_true(not snapshot.has_number(&"test_number"), "test_snapshot_encapsulation: erase_number")

	snapshot.set_symbol(&"eff_symbol", true)
	var effect = GoapSymbolicEffect.new(&"eff_symbol", GoapTypes.SymbolicEffectOp.UNSET)
	effect.apply_to(snapshot)
	_assert_true(not snapshot.has_symbol(&"eff_symbol"), "test_snapshot_encapsulation: effect UNSET uses erase_symbol")

func test_action_bindings() -> void:
	var action = GoapAction.new()
	action.action_name = &"TestAction"

	var params = { &"target_id": 10, &"destination": Vector2i(5, 5) }
	var binding = GoapActionBinding.new(action, params)

	_assert_true(binding.get_action_name() == &"TestAction", "test_action_bindings: get_action_name proxies to action")
	_assert_true(binding.has_param(&"target_id"), "test_action_bindings: has_param finds target_id")
	_assert_true(binding.get_param(&"target_id") == 10, "test_action_bindings: get_param target_id")
	_assert_true(binding.get_param(&"missing", 99) == 99, "test_action_bindings: get_param missing returns default")

class MockDynamicCostAction extends GoapAction:
	func _init():
		action_name = &"MockDynamicCostAction"
		base_cost = 5.0

	func calculate_cost(_snapshot: GoapStateSnapshot, _binding: GoapActionBinding, context: Dictionary) -> float:
		return base_cost + context.get("distance", 0.0)

func test_dynamic_cost_evaluation() -> void:
	var action = MockDynamicCostAction.new()
	var snapshot = GoapStateSnapshot.new()
	var binding = GoapActionBinding.new(action, {})

	var cost1 = action.calculate_cost(snapshot, binding, {})
	_assert_true(cost1 == 5.0, "test_dynamic_cost_evaluation: no distance in context")

	var cost2 = action.calculate_cost(snapshot, binding, {"distance": 10.0})
	_assert_true(cost2 == 15.0, "test_dynamic_cost_evaluation: with distance in context")

func test_goal_satisfaction() -> void:
	var goal = GoapGoal.new(&"TestGoal", 1.0)
	var cond = GoapNumericRule.new(&"health", GoapTypes.ComparisonOperator.GREATER_THAN, 50.0)
	goal.add_condition(cond)

	var snapshot = GoapStateSnapshot.new()
	_assert_true(not goal.is_satisfied(snapshot), "test_goal_satisfaction: numeric rule unsatisfied initially")

	snapshot.set_number(&"health", 60.0)
	_assert_true(goal.is_satisfied(snapshot), "test_goal_satisfaction: numeric rule satisfied")

class MockGoal extends GoapGoal:
	var custom_utility: float = 1.0
	func _init(name: StringName, util: float):
		super(name, util)
		custom_utility = util
	func calculate_utility(_s: GoapStateSnapshot, _c: Dictionary = {}) -> float:
		return custom_utility

func test_goal_utility_arbitration() -> void:
	var arbitrator = GoapGoalArbitrator.new()
	arbitrator.hysteresis_margin = 0.5
	var snapshot = GoapStateSnapshot.new()
	var context = {}

	var goal1 = MockGoal.new(&"Goal1", 1.0)
	var goal2 = MockGoal.new(&"Goal2", 2.0)

	# Test 1: No active goal
	var best = arbitrator.select_best_goal([goal1, goal2], snapshot, context)
	_assert_true(best == goal2, "test_goal_utility_arbitration: select best utility without active goal")

	# Test 2: Active goal with hysteresis defense
	# goal2 is active (util 2.0), goal3 is candidate (util 2.4). Difference is 0.4 < 0.5 (hysteresis margin)
	var goal3 = MockGoal.new(&"Goal3", 2.4)
	best = arbitrator.select_best_goal([goal1, goal2, goal3], snapshot, context, goal2)
	_assert_true(best == goal2, "test_goal_utility_arbitration: hysteresis protects active goal")

	# Test 3: Candidate preempts active goal
	# goal2 is active (util 2.0), goal4 is candidate (util 2.6). Difference is 0.6 > 0.5 (hysteresis margin)
	var goal4 = MockGoal.new(&"Goal4", 2.6)
	best = arbitrator.select_best_goal([goal1, goal2, goal4], snapshot, context, goal2)
	_assert_true(best == goal4, "test_goal_utility_arbitration: candidate preempts active goal")

	# Test 4: Satisfied goals are bypassed
	var satisfied_goal = MockGoal.new(&"SatisfiedGoal", 10.0)
	satisfied_goal.add_condition(GoapNumericRule.new(&"val", GoapTypes.ComparisonOperator.EQUALS, 1.0))
	snapshot.set_number(&"val", 1.0)
	best = arbitrator.select_best_goal([goal1, satisfied_goal], snapshot, context)
	_assert_true(best == goal1, "test_goal_utility_arbitration: satisfied goals are ignored")

	# Test 5: Satisfied active goal
	best = arbitrator.select_best_goal([goal1, satisfied_goal], snapshot, context, satisfied_goal)
	_assert_true(best == goal1, "test_goal_utility_arbitration: satisfied active goal loses hysteresis")
