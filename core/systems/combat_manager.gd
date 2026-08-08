# File: res://core/systems/combat_manager.gd
class_name CombatManager extends Node

## THE COMBAT ENGINE
## Handles WeGo Phased Execution, sorting ranged attacks before movement and melee.[cite: 6]

var _active_units: Array[Node] = []

func initialize(units: Array[Node]) -> void:
	_active_units = units
	
	# EXTERNAL ACCESS NOTE: Subscribing to EventBus to clean up dead units[cite: 6]
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.turn_phase_changed.connect(_on_phase_changed)

func _on_phase_changed(new_phase: StringName) -> void:
	if new_phase == &"execution": 
		_execute_wego_phase()

func _execute_wego_phase() -> void:
	print("CombatManager: Commencing Phased Execution...")
	
	var intents_queue: Array[ActionIntent] = []
	var combat_blackboard: Dictionary = {
		"all_units": _active_units
	}
	
	# 1. GATHER INTENTS (Commit Phase Logic)[cite: 6]
	for unit: Node in _active_units:
		if unit.health_component.current_health > 0:
			var intent: ActionIntent = unit.ai_evaluator.get_intended_action(combat_blackboard)
			if intent and intent.action:
				intents_queue.append(intent)
				
	# 2. SORT INTENTS (Micro-Phase Queue)[cite: 6]
	intents_queue.sort_custom(func(a: ActionIntent, b: ActionIntent) -> bool:
		return a.action.execution_phase < b.action.execution_phase
	)
	
	# 3. EXECUTE INTENTS[cite: 6]
	for intent: ActionIntent in intents_queue:
		if intent.executor.health_component.current_health <= 0:
			print("CombatManager: %s was killed before executing their action." % intent.executor.name)
			continue
			
		print("CombatManager: Executing %s (Phase %d) for %s" % [
			intent.action.action_name, 
			intent.action.execution_phase, 
			intent.executor.name
		])
		
		# EXTERNAL ACCESS NOTE: Executing the ActionData logic[cite: 6]
		intent.action.execute(intent.executor, intent.target_coord, combat_blackboard)
		
	print("CombatManager: Execution Phase Complete.")

func _on_unit_died(unit: Node) -> void:
	if unit in _active_units:
		_active_units.erase(unit)
	
	_check_combat_resolution()

func _check_combat_resolution() -> void:
	if _active_units.size() <= 1:
		print("CombatManager: Combat has concluded!")
