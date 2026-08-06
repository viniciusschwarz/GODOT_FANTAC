extends Node
## Governs the flow of turn execution using a WEGO (Simultaneous Execution) cycle.

enum Phase {
	IDLE,
	DEPLOYMENT,
	PLANNING,
	EXECUTION,
	RESOLUTION
}

var current_phase: Phase = Phase.IDLE
var turn_counter: int = 1
var units_executing: int = 0

func _ready() -> void:
	SignalBus.unit_action_finished.connect(_on_unit_action_finished)

func start_combat() -> void:
	turn_counter = 1
	start_deployment_phase()

func start_deployment_phase() -> void:
	current_phase = Phase.DEPLOYMENT
	Engine.time_scale = 0.0 # Pause game time

	print("--- BATTLE START ---")
	print("PhaseManager: Started DEPLOYMENT Phase.")
	SignalBus.wego_phase_started.emit("deployment")

func end_deployment_phase() -> void:
	# Ensure game time resumes for the subsequent phases
	# Depending on original logic, planning phase might pause again.
	Engine.time_scale = 1.0
	start_planning_phase()

func start_planning_phase() -> void:
	current_phase = Phase.PLANNING
	Engine.time_scale = 0.0 # Pause game time

	print("--- Turn ", turn_counter, " ---")
	print("PhaseManager: Started PLANNING Phase.")
	SignalBus.wego_phase_started.emit("planning")

func start_execution_phase(total_units: int) -> void:
	current_phase = Phase.EXECUTION
	units_executing = total_units
	Engine.time_scale = 1.0 # Resume time

	print("PhaseManager: Started EXECUTION Phase. Waiting for ", units_executing, " units.")
	SignalBus.wego_phase_started.emit("execution")

	if units_executing <= 0:
		start_resolution_phase()

func _on_unit_action_finished(unit: Node) -> void:
	if current_phase != Phase.EXECUTION:
		return

	units_executing -= 1
	if units_executing <= 0:
		start_resolution_phase()

func start_resolution_phase() -> void:
	current_phase = Phase.RESOLUTION
	print("PhaseManager: Started RESOLUTION Phase.")
	SignalBus.wego_phase_started.emit("resolution")
	end_turn()

func end_turn() -> void:
	turn_counter += 1
	start_planning_phase()
