class_name TurnManager extends Node

## Governs the WeGo turn phases and controls the flow of simulated time.
## Emits phase changes globally so UI and Combat systems can react.

enum TurnPhase {
	DEPLOYMENT,
	PLANNING,
	COMMIT,
	EXECUTION,
	RESOLUTION
}

@export var execution_phase_duration: float = 5.0 ## How many seconds the real-time execution lasts

var current_phase: TurnPhase = TurnPhase.DEPLOYMENT
var _execution_timer: float = 0.0

func _ready() -> void:
	# Ensure process only runs when we actually need it
	set_process(false)

## Called by the UI (e.g., "End Turn" button) or internally to transition states.
func advance_phase() -> void:
	match current_phase:
		TurnPhase.DEPLOYMENT:
			_change_phase(TurnPhase.PLANNING)
		TurnPhase.PLANNING:
			_change_phase(TurnPhase.COMMIT)
			# Pre-calculations happen here, then we automatically start execution
			_change_phase(TurnPhase.EXECUTION)
		TurnPhase.EXECUTION:
			_change_phase(TurnPhase.RESOLUTION)
		TurnPhase.RESOLUTION:
			_change_phase(TurnPhase.PLANNING)

func _change_phase(new_phase: TurnPhase) -> void:
	current_phase = new_phase

	# EXTERNAL ACCESS NOTE: Emitting state change to the global EventBus
	EventBus.turn_phase_changed.emit(_get_phase_string(current_phase))

	if current_phase == TurnPhase.EXECUTION:
		_execution_timer = execution_phase_duration
		set_process(true)
		print("TurnManager: Execution Phase Started.")
	else:
		set_process(false)

func _process(delta: float) -> void:
	if current_phase != TurnPhase.EXECUTION:
		return

	_execution_timer -= delta

	# EXTERNAL ACCESS NOTE: Emitting tick to drive the CombatManager
	EventBus.execution_tick.emit(delta)

	if _execution_timer <= 0.0:
		advance_phase()

## Helper to convert enum to StringName for the EventBus
func _get_phase_string(phase: TurnPhase) -> StringName:
	match phase:
		TurnPhase.DEPLOYMENT: return &"deployment"
		TurnPhase.PLANNING: return &"planning"
		TurnPhase.COMMIT: return &"commit"
		TurnPhase.EXECUTION: return &"execution"
		TurnPhase.RESOLUTION: return &"resolution"
	return &"unknown"
