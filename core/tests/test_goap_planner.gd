# &"C:\Users\vinic\Documents\DEV\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe" --headless -s res://core/tests/test_goap_planner.gd
extends SceneTree

func _init() -> void:
	_run_tests()
	quit(0)

func _assert_true(condition: bool, test_name: String) -> void:
	if not condition:
		printerr("[FAIL] " + test_name)
		quit(1)

func _run_tests() -> void:
	test_unsolvable_goal()
	test_precondition_resolution()
	test_action_chaining()

	print("[INTEGRATION PASS] GoapPlannerEvaluator headless simulation passed cleanly.")

func test_unsolvable_goal() -> void:
	var current_state = {"has_wood": false}
	var goal_state = {"has_wood": true}
	var available_actions: Array[GoapActionDefinition] = []

	var plan = GoapPlannerEvaluator.plan(current_state, goal_state, available_actions)
	_assert_true(plan.size() == 0, "Unsolvable goal returns empty plan")

func test_precondition_resolution() -> void:
	var current_state = {"has_wood": false, "at_depot": true}
	var goal_state = {"has_wood": true}

	var action1 = GoapActionDefinition.new()
	action1.action_id = &"WITHDRAW_WOOD"
	action1.preconditions = {"at_depot": true}
	action1.effects = {"has_wood": true}

	var action2 = GoapActionDefinition.new()
	action2.action_id = &"INVALID_ACTION"
	action2.preconditions = {"at_depot": false}
	action2.effects = {"has_wood": true}

	var available_actions: Array[GoapActionDefinition] = [action1, action2]

	var plan = GoapPlannerEvaluator.plan(current_state, goal_state, available_actions)
	_assert_true(plan.size() == 1, "Plan should have 1 action")
	_assert_true(plan[0].action_id == &"WITHDRAW_WOOD", "Plan should use the valid action")

func test_action_chaining() -> void:
	var current_state = {"at_supply": false, "has_wood": false, "at_demand": false}
	var goal_state = {"wood_delivered": true}

	var move_supply = GoapActionDefinition.new()
	move_supply.action_id = &"TRAVEL_TO_SUPPLY"
	move_supply.effects = {"at_supply": true, "at_demand": false}

	var load_wood = GoapActionDefinition.new()
	load_wood.action_id = &"WITHDRAW_CARGO"
	load_wood.preconditions = {"at_supply": true}
	load_wood.effects = {"has_wood": true}

	var move_demand = GoapActionDefinition.new()
	move_demand.action_id = &"TRAVEL_TO_DEMAND"
	move_demand.preconditions = {"has_wood": true}
	move_demand.effects = {"at_demand": true, "at_supply": false}

	var deposit = GoapActionDefinition.new()
	deposit.action_id = &"DEPOSIT_CARGO"
	deposit.preconditions = {"at_demand": true, "has_wood": true}
	deposit.effects = {"wood_delivered": true, "has_wood": false}

	var available_actions: Array[GoapActionDefinition] = [move_supply, load_wood, move_demand, deposit]

	var plan = GoapPlannerEvaluator.plan(current_state, goal_state, available_actions)
	_assert_true(plan.size() == 4, "Plan should have 4 actions")
	_assert_true(plan[0].action_id == &"TRAVEL_TO_SUPPLY", "Step 1: TRAVEL_TO_SUPPLY")
	_assert_true(plan[1].action_id == &"WITHDRAW_CARGO", "Step 2: WITHDRAW_CARGO")
	_assert_true(plan[2].action_id == &"TRAVEL_TO_DEMAND", "Step 3: TRAVEL_TO_DEMAND")
	_assert_true(plan[3].action_id == &"DEPOSIT_CARGO", "Step 4: DEPOSIT_CARGO")
