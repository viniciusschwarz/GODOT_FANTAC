extends Node
## Governs the flow of turn execution using a WEGO (Simultaneous Execution) cycle.

enum Phase {
	IDLE,
	PLANNING,
	EXECUTION,
	RESOLUTION
}

var current_phase: Phase = Phase.IDLE
var turn_counter: int = 1
var units_executing: int = 0

func _ready() -> void:
	# In a real game, this would be triggered by a "Start Combat" signal
	# SignalBus.connect("combat_started", start_combat)

	# Connect to unit completion signals
	SignalBus.connect("unit_action_finished", _on_unit_action_finished)
	pass

func start_combat() -> void:
	turn_counter = 1
	start_planning_phase()

func start_planning_phase() -> void:
	current_phase = Phase.PLANNING
	Engine.time_scale = 0.0 # Pause game time

	print("--- Turn ", turn_counter, " ---")
	print("PhaseManager: Started PLANNING Phase.")
	SignalBus.wego_phase_started.emit("planning")

	# Wait for AIManager to finish building action queues
	# Assuming AIManager will call start_execution_phase when done.

func start_execution_phase(total_units: int) -> void:
	current_phase = Phase.EXECUTION
	units_executing = total_units
	Engine.time_scale = 1.0 # Resume time

	print("PhaseManager: Started EXECUTION Phase. Waiting for ", units_executing, " units.")
	SignalBus.wego_phase_started.emit("execution")

	# Fallback if no units are active
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

	# Apply damage, casualties, morale (Handled by CombatManager/HealthComponents)

	end_turn()

func end_turn() -> void:
	# Evaluate victory/defeat here
	turn_counter += 1
	start_planning_phase()
