class_name GoapAction
extends RefCounted

enum Status {
	READY = 0,
	RUNNING = 1,
	COMPLETED = 2,
	FAILED = 3
}

var action_name: StringName = &""
var base_cost: int = 1
var preconditions: Dictionary = {} # Key: StringName -> Variant (primitives: bool, int, StringName)
var effects: Dictionary = {}       # Key: StringName -> Variant (primitives: bool, int, StringName)

## Dynamic heuristic cost hook (allows overriding base_cost using blackboard context)
func get_cost(blackboard: Dictionary) -> int:
	return base_cost

## Procedural precondition check evaluated at runtime before starting or during execution
func check_procedural_precondition(blackboard: Dictionary) -> bool:
	return true

## Called once when the action begins execution
func start(blackboard: Dictionary) -> void:
	pass

## Called on every simulation tick while this action is active.
## Must return Status (RUNNING, COMPLETED, or FAILED).
## Interacts with the game world exclusively via cmd_bus.
func step(tick: int, blackboard: Dictionary, cmd_bus: CommandBus) -> int:
	return Status.COMPLETED

## Called when the action is finished or interrupted
func terminate(blackboard: Dictionary) -> void:
	pass
