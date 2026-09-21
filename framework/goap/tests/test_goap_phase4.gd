class_name TestGoapPhase4
extends SceneTree

const GoapTypesClass = preload("res://framework/goap/common/goap_types.gd")
const GoapSequencerClass = preload("res://framework/goap/sequencer/goap_sequencer.gd")
const GoapStateSnapshotClass = preload("res://framework/goap/planner/goap_state_snapshot.gd")
const GoapActionClass = preload("res://framework/goap/actions/goap_action.gd")
const GoapGoalClass = preload("res://framework/goap/goals/goap_goal.gd")
const GoapGoalArbitratorClass = preload("res://framework/goap/goals/goap_goal_arbitrator.gd")
const GoapPlanClass = preload("res://framework/goap/planner/goap_plan.gd")
const GoapActionBindingClass = preload("res://framework/goap/actions/goap_action_binding.gd")

class MockEventBus extends RefCounted:
	var events: Array = []
	func emit_now(payload: Dictionary) -> void:
		events.append(payload)

class MockAction extends GoapAction:
	var running_ticks: int = 1
	var procedural_failure: bool = false
	var fail_on_step: bool = false

	func _init(name: StringName, ticks: int = 1):
		action_name = name
		running_ticks = ticks

	func check_procedural_precondition(snapshot: GoapStateSnapshotClass, binding: GoapActionBindingClass, context: Dictionary) -> bool:
		return not procedural_failure

	func on_enter(binding: GoapActionBindingClass, context: Dictionary) -> void:
		pass

	func on_step(current_tick: int, binding: GoapActionBindingClass, context: Dictionary, command_bus: Object) -> int:
		if fail_on_step:
			return GoapTypesClass.ActionStatus.FAILED

		var elapsed = context.get_or_add(binding.get_action_name() + "_elapsed", 0)
		elapsed += 1
		context[binding.get_action_name() + "_elapsed"] = elapsed

		if elapsed >= running_ticks:
			return GoapTypesClass.ActionStatus.COMPLETED

		return GoapTypesClass.ActionStatus.RUNNING

	func on_exit(binding: GoapActionBindingClass, context: Dictionary) -> void:
		pass

	func on_abort(binding: GoapActionBindingClass, context: Dictionary) -> void:
		pass

	func get_all_possible_bindings(snapshot: GoapStateSnapshotClass) -> Array[GoapActionBindingClass]:
		var binding = GoapActionBindingClass.new()
		binding.action = self
		return [binding]

class MockGoal extends GoapGoal:
	var util: float = 1.0
	var satisfied: bool = false

	func _init(name: StringName, base_util: float):
		goal_name = name
		util = base_util

	func calculate_utility(snapshot: GoapStateSnapshotClass, context: Dictionary) -> float:
		return util

	func is_satisfied(snapshot: GoapStateSnapshotClass, context: Dictionary) -> bool:
		return satisfied

# We need a mock planner to directly supply our plan since we just want to test the sequencer.
class MockPlanner extends RefCounted:
	var bindings: Array = []

	func plan(snapshot: GoapStateSnapshotClass, goal: GoapGoalClass, available_actions: Array, context: Dictionary) -> GoapPlanClass:
		var p = GoapPlanClass.new()
		p.bindings = bindings
		p.status = GoapPlanClass.PlanStatus.SOLVED if bindings.size() > 0 else GoapPlanClass.PlanStatus.UNSOLVABLE
		return p

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		printerr("[FAIL] " + message)
		quit(1)

func _init() -> void:
	print("Running TestGoapPhase4...")

	test_multi_tick_action()
	test_end_to_end_plan()
	test_procedural_precondition_failure()
	test_goal_preemption()

	print("[PASS] All GOAP Phase 4 unit tests passed successfully.")
	quit(0)

func test_multi_tick_action():
	print("test_multi_tick_action")
	var event_bus = MockEventBus.new()
	var sequencer = GoapSequencerClass.new(1, null, null, null, event_bus)

	var goal = MockGoal.new(&"Survive", 1.0)
	var action = MockAction.new(&"Run", 2) # Takes 2 ticks

	var binding = GoapActionBindingClass.new()
	binding.action = action

	var planner = MockPlanner.new()
	planner.bindings = [binding]
	sequencer.planner = planner

	sequencer.register_goal(goal)
	sequencer.register_action(action)

	var snapshot = GoapStateSnapshotClass.new()
	var context = {}

	sequencer.tick(1, snapshot, context) # Formulates plan, runs tick 1 (RUNNING)

	_assert_true(event_bus.events.size() == 2, "Should have 2 events: formulated, started")
	_assert_true(event_bus.events[0].event_type == &"GOAP_PLAN_FORMULATED", "First event formulated")
	_assert_true(event_bus.events[1].event_type == &"GOAP_ACTION_STARTED", "Second event started")
	_assert_true(sequencer.active_binding != null, "Action should be active")

	sequencer.tick(2, snapshot, context) # Runs tick 2 (COMPLETED)

	_assert_true(event_bus.events.size() == 3, "Should have 3 events: + completed")
	_assert_true(event_bus.events[2].event_type == &"GOAP_ACTION_COMPLETED", "Third event completed")
	_assert_true(sequencer.active_binding == null, "Action should not be active")
	_assert_true(sequencer.active_plan == null, "Plan should be completed")

func test_end_to_end_plan():
	print("test_end_to_end_plan")
	var event_bus = MockEventBus.new()
	var sequencer = GoapSequencerClass.new(1, null, null, null, event_bus)

	var goal = MockGoal.new(&"Win", 1.0)
	var a1 = MockAction.new(&"A1", 1)
	var a2 = MockAction.new(&"A2", 1)

	var b1 = GoapActionBindingClass.new()
	b1.action = a1
	var b2 = GoapActionBindingClass.new()
	b2.action = a2

	var planner = MockPlanner.new()
	planner.bindings = [b1, b2]
	sequencer.planner = planner

	sequencer.register_goal(goal)

	var snapshot = GoapStateSnapshotClass.new()
	var context = {}

	sequencer.tick(1, snapshot, context) # a1 completed
	goal.satisfied = true
	sequencer.tick(2, snapshot, context) # a2 starts and completes
	# tick 2 will see a2 completed and finish the plan

	# Events: FORMULATED, STARTED (A1), COMPLETED (A1), STARTED (A2), COMPLETED (A2), GOAL_ACHIEVED
	_assert_true(event_bus.events.size() == 6, "Expected 6 events for 2-step plan with goal achieved")
	_assert_true(event_bus.events[-1].event_type == &"GOAP_GOAL_ACHIEVED", "Last event should be achieved")

func test_procedural_precondition_failure():
	print("test_procedural_precondition_failure")
	var event_bus = MockEventBus.new()
	var sequencer = GoapSequencerClass.new(1, null, null, null, event_bus)

	var goal = MockGoal.new(&"Survive", 1.0)
	var a1 = MockAction.new(&"A1", 1)
	var a2 = MockAction.new(&"A2", 1)
	a2.procedural_failure = true

	var b1 = GoapActionBindingClass.new()
	b1.action = a1
	var b2 = GoapActionBindingClass.new()
	b2.action = a2

	var planner = MockPlanner.new()
	planner.bindings = [b1, b2]
	sequencer.planner = planner

	sequencer.register_goal(goal)
	var snapshot = GoapStateSnapshotClass.new()
	var context = {}

	sequencer.tick(1, snapshot, context) # A1 starts and completes
	sequencer.tick(2, snapshot, context) # A2 fails procedural check

	var failure_found = false
	for e in event_bus.events:
		if e.event_type == &"GOAP_ACTION_FAILED" and e.event_data.get("reason") == "procedural_precondition_failed":
			failure_found = true

	_assert_true(failure_found, "Should have failed procedural check")
	_assert_true(sequencer.active_plan == null, "Plan should be aborted")
	_assert_true(sequencer.active_binding == null, "Binding should be cleared")

func test_goal_preemption():
	print("test_goal_preemption")
	var event_bus = MockEventBus.new()
	var sequencer = GoapSequencerClass.new(1, null, null, null, event_bus)

	var goal_econ = MockGoal.new(&"Economic", 1.0)
	var goal_survive = MockGoal.new(&"Survive", 0.0) # Initially low

	var action = MockAction.new(&"Farm", 5) # Long action
	var binding = GoapActionBindingClass.new()
	binding.action = action

	var planner = MockPlanner.new()
	planner.bindings = [binding]
	sequencer.planner = planner

	sequencer.register_goal(goal_econ)
	sequencer.register_goal(goal_survive)

	var snapshot = GoapStateSnapshotClass.new()
	var context = {}

	sequencer.tick(1, snapshot, context) # Economic plan starts
	_assert_true(sequencer.active_goal.goal_name == &"Economic", "Economic active")
	_assert_true(sequencer.active_binding != null, "Binding active")

	# Now survive utility goes up
	goal_survive.util = 5.0

	sequencer.tick(2, snapshot, context) # Tick 2, arbitrator switches to survive

	_assert_true(sequencer.active_goal.goal_name == &"Survive", "Survive active now")
	# Econ plan is aborted but a new Survive plan is formulated immediately
	_assert_true(sequencer.active_plan != null, "New survive plan formulated")

	var preempted = false
	for e in event_bus.events:
		if e.event_type == &"GOAP_PLAN_PREEMPTED":
			preempted = true

	_assert_true(preempted, "Preemption event should be emitted")
