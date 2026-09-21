class_name GoapAgent
extends RefCounted

var agent_id: int
var command_bus: CommandBus
var event_bus: EventBus

var available_actions: Array[GoapAction] = []
var active_plan: Array[GoapAction] = []
var active_action: GoapAction = null

func _init(p_agent_id: int, p_cmd_bus: CommandBus, p_evt_bus: EventBus) -> void:
	agent_id = p_agent_id
	command_bus = p_cmd_bus
	event_bus = p_evt_bus

## Registers an action instance to this agent's repertoire
func register_action(action: GoapAction) -> void:
	available_actions.append(action)

## Primary simulation tick. Driven externally by SimClock or a system sequencer.
## blackboard: Clean perception dictionary produced by external sensors.
## goal_state: Key-value map representing desired state.
func tick(current_tick: int, blackboard: Dictionary, goal_state: Dictionary) -> void:
	# 1. If active_plan is empty, formulate a new plan using GoapPlanner.plan()
	if active_plan.is_empty() and active_action == null:
		var plan = GoapPlanner.plan(blackboard, goal_state, available_actions, blackboard)
		if not plan.is_empty():
			active_plan = plan
			event_bus.emit_now(&"GOAP_PLAN_FORMULATED", current_tick, agent_id, -1, {"plan_size": active_plan.size()})
		else:
			event_bus.emit_now(&"GOAP_PLAN_FAILED", current_tick, agent_id, -1, {"reason": "no_plan_possible"})
			return

	# 2. If active_action is null and active_plan has actions:
	if active_action == null and not active_plan.is_empty():
		active_action = active_plan.pop_front()

		# Verify active_action.check_procedural_precondition(blackboard). If false, abort plan.
		if not active_action.check_procedural_precondition(blackboard):
			abort_plan(blackboard)
			event_bus.emit_now(&"GOAP_PLAN_FAILED", current_tick, agent_id, -1, {"reason": "procedural_precondition_failed", "action": active_action.action_name})
			active_action = null
			return

		active_action.start(blackboard)
		event_bus.emit_now(&"GOAP_ACTION_STARTED", current_tick, agent_id, -1, {"action": active_action.action_name})

	# 3. Step the active action:
	if active_action != null:
		var status = active_action.step(current_tick, blackboard, command_bus)

		if status == GoapAction.Status.COMPLETED:
			active_action.terminate(blackboard)
			event_bus.emit_now(&"GOAP_ACTION_COMPLETED", current_tick, agent_id, -1, {"action": active_action.action_name})
			active_action = null

		elif status == GoapAction.Status.FAILED:
			active_action.terminate(blackboard)
			event_bus.emit_now(&"GOAP_ACTION_FAILED", current_tick, agent_id, -1, {"action": active_action.action_name})
			active_action = null
			active_plan.clear() # Forces replan next tick

func abort_plan(blackboard: Dictionary) -> void:
	if active_action:
		active_action.terminate(blackboard)
		active_action = null
	active_plan.clear()
