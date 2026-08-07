class_name CombatManager extends Node

## Orchestrates the WeGo simultaneous resolution.
## Gathers intended actions from all units and executes them concurrently.
## Tracks win/loss conditions.

var _active_units: Array[Node] = []
var _is_executing: bool = false
var _combat_ended: bool = false

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Subscribing to EventBus signals
	EventBus.turn_phase_changed.connect(_on_phase_changed)
	EventBus.execution_tick.connect(_on_execution_tick)
	EventBus.unit_died.connect(_on_unit_died)

## Dependency Injection: Called by the BattlefieldManager to register units.
## @param units: Array of Unit nodes present on the board.
func initialize(units: Array[Node]) -> void:
	_active_units = units.duplicate()
	_combat_ended = false
	print("CombatManager initialized with %d units." % _active_units.size())

func _on_phase_changed(new_phase: StringName) -> void:
	_is_executing = (new_phase == &"execution")

## The core WeGo loop. Called every frame/tick during the Execution Phase.
func _on_execution_tick(_delta: float) -> void:
	if not _is_executing or _combat_ended:
		return

	var queued_actions: Array[Dictionary] = []

	# 1. GATHER INTENTIONS
	for unit: Node in _active_units:
		# Safety check to ensure unit has the required component
		if not unit.has_node("AIConditionEvaluator"):
			continue

		var evaluator = unit.get_node("AIConditionEvaluator")

		# Build the context blackboard (can be expanded to include MapManager data)
		var blackboard: Dictionary = {
			"delta": _delta,
			"all_units": _active_units
		}

		# EXTERNAL ACCESS NOTE: Querying the component
		# Assuming determine_next_action returns an ActionData resource
		var intended_action = evaluator.determine_next_action(blackboard)

		if intended_action:
			# Calculate target position based on action logic (simplified here)
			# Assuming unit has movement_component with current_coord
			var target_pos: Vector3i = Vector3i.ZERO
			if unit.has_node("MovementComponent"):
				target_pos = unit.get_node("MovementComponent").current_coord

			queued_actions.append({
				"action": intended_action,
				"unit": unit,
				"target_pos": target_pos,
				"blackboard": blackboard
			})

	# 2. EXECUTE CONCURRENTLY
	# Because we gathered all intentions before executing any, a unit cannot
	# kill another unit before the second unit has a chance to queue its attack.
	for command: Dictionary in queued_actions:
		var action = command["action"]

		# EXTERNAL ACCESS NOTE: Calling the Resource script
		action.execute(command["unit"], command["target_pos"], command["blackboard"])

## Cleans up the roster so dead units do not participate in the next tick.
## Also checks for win/loss conditions.
func _on_unit_died(unit_id: StringName) -> void:
	var team_id_of_dead_unit: int = -1

	for i: int in range(_active_units.size() - 1, -1, -1):
		var unit: Node = _active_units[i]
		# Assuming unit has a property 'unit_id' and 'team_id'
		if unit.get("unit_id") == unit_id:
			team_id_of_dead_unit = unit.get("team_id") if "team_id" in unit else -1
			_active_units.remove_at(i)
			print("CombatManager: Removed dead unit %s from active roster." % unit_id)
			break

	_check_win_loss_conditions()

func _check_win_loss_conditions() -> void:
	if _combat_ended:
		return

	var teams_alive: Dictionary = {}
	for unit: Node in _active_units:
		if "team_id" in unit:
			var t_id = unit.get("team_id")
			teams_alive[t_id] = true

	if teams_alive.size() <= 1:
		_combat_ended = true
		var winning_team: StringName = &"none"
		if teams_alive.size() == 1:
			var t_id = teams_alive.keys()[0]
			winning_team = StringName(str(t_id))
			print("CombatManager: Combat ended. Winning team: %s" % winning_team)
		else:
			print("CombatManager: Combat ended in a draw.")

		EventBus.combat_ended.emit(winning_team)
