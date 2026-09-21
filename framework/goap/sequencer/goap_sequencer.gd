class_name GoapSequencer
extends RefCounted

const GoapPlannerClass = preload("res://framework/goap/planner/goap_planner.gd")
const GoapGoalArbitratorClass = preload("res://framework/goap/goals/goap_goal_arbitrator.gd")

var agent_id: int
var planner: GoapPlanner
var arbitrator: GoapGoalArbitrator
var command_bus: Object = null
var event_bus: Object = null
var available_goals: Array[GoapGoal] = []
var available_actions: Array[GoapAction] = []
var active_goal: GoapGoal = null
var active_plan: GoapPlan = null
var current_binding_index: int = 0
var active_binding: GoapActionBinding = null
var replan_requested: bool = false

func _init(
	p_agent_id: int,
	p_planner: GoapPlanner = null,
	p_arbitrator: GoapGoalArbitrator = null,
	p_cmd_bus: Object = null,
	p_evt_bus: Object = null
) -> void:
	agent_id = p_agent_id
	planner = p_planner if p_planner != null else GoapPlannerClass.new()
	arbitrator = p_arbitrator if p_arbitrator != null else GoapGoalArbitratorClass.new()
	command_bus = p_cmd_bus
	event_bus = p_evt_bus

func register_goal(goal: GoapGoal) -> void:
	available_goals.append(goal)

func register_action(action: GoapAction) -> void:
	available_actions.append(action)

func request_replan() -> void:
	replan_requested = true

func tick(current_tick: int, snapshot: GoapStateSnapshot, context: Dictionary = {}) -> void:
	# 1. Goal Arbitration & Preemption Check
	var best_goal: GoapGoal = arbitrator.select_best_goal(available_goals, snapshot, context, active_goal)

	if best_goal != active_goal:
		if active_goal != null and active_binding != null:
			active_binding.action.on_abort(active_binding, context)

			_emit_event(&"GOAP_PLAN_PREEMPTED", current_tick, {
				"old_goal": active_goal.goal_name,
				"new_goal": best_goal.goal_name if best_goal != null else &""
			})

		active_goal = best_goal
		active_plan = null
		active_binding = null
		current_binding_index = 0
		replan_requested = false

	# 2. Plan Formulation
	if active_goal == null:
		return

	if active_plan == null or not active_plan.is_valid() or replan_requested:
		replan_requested = false
		active_plan = planner.plan(snapshot, active_goal, available_actions, context)
		current_binding_index = 0
		active_binding = null

		if not active_plan.is_valid():
			_emit_event(&"GOAP_PLAN_FAILED", current_tick, {
				"goal": active_goal.goal_name,
				"status": active_plan.status
			})
			return

		_emit_event(&"GOAP_PLAN_FORMULATED", current_tick, {
			"goal": active_goal.goal_name,
			"plan_size": active_plan.get_step_count(),
			"cost": active_plan.total_cost
		})

	# 3. Action Advance & Precondition Validation
	if active_binding == null:
		if current_binding_index >= active_plan.bindings.size():
			active_plan = null
			active_goal = null
			return

		var candidate = active_plan.bindings[current_binding_index]

		if not candidate.action.check_procedural_precondition(snapshot, candidate, context):
			var target_id = candidate.get_param(&"target_id", 0) if candidate else 0
			_emit_event(&"GOAP_ACTION_FAILED", current_tick, {
				"action": candidate.get_action_name(),
				"reason": "procedural_precondition_failed",
				"target_id": target_id
			})
			active_plan = null
			active_binding = null
			return

		active_binding = candidate
		active_binding.action.on_enter(active_binding, context)

		var target_id = active_binding.get_param(&"target_id", 0) if active_binding else 0
		_emit_event(&"GOAP_ACTION_STARTED", current_tick, {
			"action": active_binding.get_action_name(),
			"step_index": current_binding_index,
			"target_id": target_id
		})

	# 4. Action Stepping
	var status: int = active_binding.action.on_step(current_tick, active_binding, context, command_bus)

	if status == GoapTypes.ActionStatus.COMPLETED:
		active_binding.action.on_exit(active_binding, context)

		var target_id = active_binding.get_param(&"target_id", 0) if active_binding else 0
		_emit_event(&"GOAP_ACTION_COMPLETED", current_tick, {
			"action": active_binding.get_action_name(),
			"step_index": current_binding_index,
			"target_id": target_id
		})

		active_binding = null
		current_binding_index += 1

		if current_binding_index >= active_plan.bindings.size():
			if active_goal != null and active_goal.is_satisfied(snapshot, context):
				_emit_event(&"GOAP_GOAL_ACHIEVED", current_tick, {
					"goal": active_goal.goal_name
				})
			active_plan = null
			active_goal = null

	elif status == GoapTypes.ActionStatus.FAILED:
		active_binding.action.on_abort(active_binding, context)

		var target_id = active_binding.get_param(&"target_id", 0) if active_binding else 0
		_emit_event(&"GOAP_ACTION_FAILED", current_tick, {
			"action": active_binding.get_action_name(),
			"reason": "step_execution_failed",
			"target_id": target_id
		})

		active_binding = null
		active_plan = null
		replan_requested = true

	elif status == GoapTypes.ActionStatus.RUNNING:
		pass

func _emit_event(event_type: StringName, current_tick: int, data: Dictionary) -> void:
	if event_bus != null and event_bus.has_method("emit_now"):
		var target_entity_id: int = data.get("target_id", 0)
		data.erase("target_id")

		event_bus.emit_now({
			"event_type": event_type,
			"tick_timestamp": current_tick,
			"source_entity_id": agent_id,
			"target_entity_id": target_entity_id,
			"event_data": data
		})

func abort_current_plan(context: Dictionary = {}) -> void:
	if active_binding != null:
		active_binding.action.on_abort(active_binding, context)
		active_binding = null
	active_plan = null
	active_goal = null
	current_binding_index = 0
	replan_requested = false
