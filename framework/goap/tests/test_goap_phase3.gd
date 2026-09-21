extends SceneTree

func _init() -> void:
	print("Running test_goap_phase3.gd...")

	test_direct_plan_solving()
	test_branching_and_cost_selection()
	test_parameter_binding_expansion()
	test_node_budget_cutoff()
	test_depth_limit_cutoff()
	test_cycle_and_loop_safety()

	print("test_goap_phase3.gd passed successfully.")
	quit(0)

func _assert_true(condition: bool, msg: String) -> void:
	if not condition:
		printerr("ASSERTION FAILED: " + msg)
		quit(1)

func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		printerr("ASSERTION FAILED: " + msg + " (Actual: " + str(actual) + " | Expected: " + str(expected) + ")")
		quit(1)

# Helper classes for testing
class DummyAction extends GoapAction:
	func _init(name: StringName, cost: float = 1.0):
		self.action_name = name
		self.base_cost = cost

	func calculate_cost(_s: GoapStateSnapshot, _b: GoapActionBinding, _c: Dictionary) -> float:
		return base_cost

class BindingAction extends GoapAction:
	var bindings_to_generate: Array[Dictionary]

	func _init(name: StringName, p_bindings: Array[Dictionary]):
		self.action_name = name
		self.bindings_to_generate = p_bindings

	func generate_bindings(_s: GoapStateSnapshot, _c: Dictionary) -> Array[GoapActionBinding]:
		var res: Array[GoapActionBinding] = []
		for b_params in bindings_to_generate:
			res.append(GoapActionBinding.new(self, b_params))
		return res

	func check_procedural_precondition(_s: GoapStateSnapshot, binding: GoapActionBinding, _c: Dictionary) -> bool:
		return binding.get_param(&"target_id", 0) > 100

func test_direct_plan_solving() -> void:
	var planner = GoapPlanner.new()

	var goal = GoapGoal.new(&"reach_c")
	var cond_c = GoapSymbolicRule.new(&"state", "C")
	goal.add_condition(cond_c)

	var initial_state = GoapStateSnapshot.new()
	initial_state.set_symbol(&"state", "A")

	var action_ab = DummyAction.new(&"A_to_B")
	var pre_ab = GoapSymbolicRule.new(&"state", "A")
	var eff_ab = GoapSymbolicEffect.new(&"state", "B")
	action_ab.preconditions.append(pre_ab)
	action_ab.effects.append(eff_ab)

	var action_bc = DummyAction.new(&"B_to_C")
	var pre_bc = GoapSymbolicRule.new(&"state", "B")
	var eff_bc = GoapSymbolicEffect.new(&"state", "C")
	action_bc.preconditions.append(pre_bc)
	action_bc.effects.append(eff_bc)

	var plan = planner.plan(initial_state, goal, [action_bc, action_ab])

	_assert_true(plan.is_valid(), "Plan should be valid")
	_assert_eq(plan.get_step_count(), 2, "Plan should have 2 steps")
	_assert_eq(plan.bindings[0].action.action_name, &"A_to_B", "First action should be A_to_B")
	_assert_eq(plan.bindings[1].action.action_name, &"B_to_C", "Second action should be B_to_C")
	_assert_eq(plan.total_cost, 2.0, "Total cost should be 2.0")

func test_branching_and_cost_selection() -> void:
	var planner = GoapPlanner.new()

	var goal = GoapGoal.new(&"reach_end")
	goal.add_condition(GoapSymbolicRule.new(&"state", "END"))

	var initial_state = GoapStateSnapshot.new()
	initial_state.set_symbol(&"state", "START")

	# Expensive path
	var action_expensive = DummyAction.new(&"path_expensive", 10.0)
	action_expensive.preconditions.append(GoapSymbolicRule.new(&"state", "START"))
	action_expensive.effects.append(GoapSymbolicEffect.new(&"state", "END"))

	# Cheap path
	var action_cheap = DummyAction.new(&"path_cheap", 3.0)
	action_cheap.preconditions.append(GoapSymbolicRule.new(&"state", "START"))
	action_cheap.effects.append(GoapSymbolicEffect.new(&"state", "END"))

	var plan = planner.plan(initial_state, goal, [action_expensive, action_cheap])

	_assert_true(plan.is_valid(), "Plan should be valid")
	_assert_eq(plan.get_step_count(), 1, "Plan should have 1 step")
	_assert_eq(plan.bindings[0].action.action_name, &"path_cheap", "Planner should choose the cheaper path")
	_assert_eq(plan.total_cost, 3.0, "Total cost should be 3.0")

func test_parameter_binding_expansion() -> void:
	var planner = GoapPlanner.new()

	var goal = GoapGoal.new(&"has_target")
	goal.add_condition(GoapSymbolicRule.new(&"has_target", true))

	var initial_state = GoapStateSnapshot.new()

	var bindings_list = [
		{ &"target_id": 99 }, # fails procedural precond
		{ &"target_id": 102 } # passes procedural precond
	]

	var action_bind = BindingAction.new(&"bind_target", bindings_list)
	action_bind.effects.append(GoapSymbolicEffect.new(&"has_target", true))

	var plan = planner.plan(initial_state, goal, [action_bind])

	_assert_true(plan.is_valid(), "Plan should be valid")
	_assert_eq(plan.get_step_count(), 1, "Plan should have 1 step")
	_assert_eq(plan.bindings[0].get_param(&"target_id"), 102, "Planner should bind the valid candidate")

func test_node_budget_cutoff() -> void:
	var planner = GoapPlanner.new()
	planner.max_nodes_evaluated = 5

	var goal = GoapGoal.new(&"unsolvable_goal")
	goal.add_condition(GoapSymbolicRule.new(&"impossible", true))

	var initial_state = GoapStateSnapshot.new()
	initial_state.set_symbol(&"counter", 0)

	var action_loop = DummyAction.new(&"increment_counter")
	action_loop.effects.append(GoapNumericEffect.new(&"counter", GoapNumericEffect.Operation.ADD, 1.0))

	var plan = planner.plan(initial_state, goal, [action_loop])

	_assert_true(not plan.is_valid(), "Plan should not be valid")
	_assert_eq(plan.status, GoapPlan.Status.BUDGET_EXHAUSTED, "Planner should hit budget exhaustion")

func test_depth_limit_cutoff() -> void:
	var planner = GoapPlanner.new()
	planner.max_depth = 2

	var goal = GoapGoal.new(&"reach_d")
	goal.add_condition(GoapSymbolicRule.new(&"state", "D"))

	var initial_state = GoapStateSnapshot.new()
	initial_state.set_symbol(&"state", "A")

	var action_ab = DummyAction.new(&"A_to_B")
	action_ab.preconditions.append(GoapSymbolicRule.new(&"state", "A"))
	action_ab.effects.append(GoapSymbolicEffect.new(&"state", "B"))

	var action_bc = DummyAction.new(&"B_to_C")
	action_bc.preconditions.append(GoapSymbolicRule.new(&"state", "B"))
	action_bc.effects.append(GoapSymbolicEffect.new(&"state", "C"))

	var action_cd = DummyAction.new(&"C_to_D")
	action_cd.preconditions.append(GoapSymbolicRule.new(&"state", "C"))
	action_cd.effects.append(GoapSymbolicEffect.new(&"state", "D"))

	var plan = planner.plan(initial_state, goal, [action_ab, action_bc, action_cd])

	_assert_true(not plan.is_valid(), "Plan should not be valid due to depth limit")
	_assert_eq(plan.status, GoapPlan.Status.DEPTH_LIMIT_REACHED, "Planner should hit depth limit reached status")

func test_cycle_and_loop_safety() -> void:
	var planner = GoapPlanner.new()
	planner.max_nodes_evaluated = 1000 # Enough budget
	planner.max_depth = 50

	var goal = GoapGoal.new(&"impossible")
	goal.add_condition(GoapSymbolicRule.new(&"win", true))

	var initial_state = GoapStateSnapshot.new()
	initial_state.set_symbol(&"toggle", true)

	var action_a = DummyAction.new(&"toggle_off")
	action_a.preconditions.append(GoapSymbolicRule.new(&"toggle", true))
	action_a.effects.append(GoapSymbolicEffect.new(&"toggle", false))

	var action_b = DummyAction.new(&"toggle_on")
	action_b.preconditions.append(GoapSymbolicRule.new(&"toggle", false))
	action_b.effects.append(GoapSymbolicEffect.new(&"toggle", true))

	var plan = planner.plan(initial_state, goal, [action_a, action_b])

	_assert_true(not plan.is_valid(), "Plan should not be valid")
	_assert_eq(plan.status, GoapPlan.Status.UNSOLVABLE, "Planner should exit cleanly as UNSOLVABLE due to closed set, not budget exhausted")
