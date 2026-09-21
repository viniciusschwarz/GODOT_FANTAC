extends SceneTree

# Mock classes for testing without any game dependencies
class MockChopWoodAction extends GoapAction:
	func _init() -> void:
		action_name = &"ChopWood"
		preconditions = {"has_axe": true}
		effects = {"has_wood": true}

class MockCraftPlankAction extends GoapAction:
	func _init() -> void:
		action_name = &"CraftPlank"
		preconditions = {"has_wood": true}
		effects = {"has_plank": true}

class MockFailAction extends GoapAction:
	var _check_count = 0
	func _init() -> void:
		action_name = &"FailAction"
		preconditions = {"can_fail": true}
		effects = {"is_failed": true}

	func check_procedural_precondition(blackboard: Dictionary) -> bool:
		_check_count += 1
		# Return true during planner check, false during agent execution check
		return _check_count == 1

func _assert_true(condition: bool, test_name: String) -> void:
	if not condition:
		printerr("[FAIL] Assertion failed in: ", test_name)
		quit(1)

func _init() -> void:
	print("Running GOAP Framework Tests...")

	# 1. Verify simple A* chaining
	var state = {"has_axe": true, "has_wood": false, "has_plank": false}
	var goal = {"has_plank": true}
	var actions: Array[GoapAction] = [MockChopWoodAction.new(), MockCraftPlankAction.new()]

	var plan = GoapPlanner.plan(state, goal, actions)
	_assert_true(plan.size() == 2, "Test A* Chaining - Plan length")
	_assert_true(plan[0].action_name == &"ChopWood", "Test A* Chaining - Action 1")
	_assert_true(plan[1].action_name == &"CraftPlank", "Test A* Chaining - Action 2")

	# 2. Verify procedural precondition failure aborts plan and replans (simulated via GoapAgent)
	var cmd_bus = CommandBus.new()
	var evt_bus = EventBus.new()

	var agent = GoapAgent.new(1, cmd_bus, evt_bus)
	agent.register_action(MockFailAction.new())

	var agent_state = {"can_fail": true}
	var agent_goal = {"is_failed": true}

	# Keep track of events
	var emitted_events: Array[StringName] = []
	evt_bus.event_emitted.connect(func(evt: StringName, _tick: int, _src: int, _dst: int, _data: Dictionary):
		emitted_events.append(evt)
	)

	agent.tick(1, agent_state, agent_goal)

	# agent ticked, it should formulate plan, but pop front, fail procedural precondition, and emit GOAP_PLAN_FAILED
	_assert_true(emitted_events.has(&"GOAP_PLAN_FORMULATED"), "Test Procedural Failure - Formulated")
	_assert_true(emitted_events.has(&"GOAP_PLAN_FAILED"), "Test Procedural Failure - Failed")
	_assert_true(agent.active_plan.is_empty(), "Test Procedural Failure - Plan cleared")
	_assert_true(agent.active_action == null, "Test Procedural Failure - Active action cleared")

	print("[PASS] All GOAP Framework unit tests passed.")
	quit(0)
