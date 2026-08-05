extends Node
## Global AI evaluation processor that coordinates the Planning Phase.

var active_units: Array[Node] = []

func _ready() -> void:
	SignalBus.connect("wego_phase_started", _on_phase_started)

## Registers a unit to be processed during the Planning Phase.
func register_unit(unit: Node) -> void:
	if not active_units.has(unit):
		active_units.append(unit)

## Removes a unit (e.g., when it dies).
func unregister_unit(unit: Node) -> void:
	if active_units.has(unit):
		active_units.erase(unit)

func _on_phase_started(phase_name: String) -> void:
	if phase_name == "planning":
		process_planning_phase()

## Iterates through all registered units and evaluates their Behavior Trees.
func process_planning_phase() -> void:
	print("AIManager: Processing behavior trees for ", active_units.size(), " units.")

	for unit in active_units:
		if is_instance_valid(unit) and unit.has_node("AIComponent"):
			var ai_comp = unit.get_node("AIComponent")
			ai_comp.evaluate_behavior()

	# Once all units have planned, tell PhaseManager to execute.
	# Assuming PhaseManager is registered as an Autoload named 'PhaseManager'
	if has_node("/root/PhaseManager"):
		get_node("/root/PhaseManager").start_execution_phase(active_units.size())
