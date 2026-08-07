Commander, we now enter **Phase 5: The WeGo Engine**. This is the beating heart of your tactical simulation.

We will build the state machine that dictates the flow of time and the engine that resolves combat conflicts fairly and simultaneously.

### 1. Architectural Logic: The Engine

**The Turn State Machine:**
A WeGo system operates in distinct, rigid phases. The `TurnManager` is responsible for transitioning between these states and broadcasting the current state to the rest of the game via the `EventBus`.

1. **Planning:** Time is paused. The UI accepts player inputs and AI tree modifications.
2. **Commit:** Inputs are locked. The system pre-calculates any immediate data requirements.
3. **Execution:** Real-time simulation. The `TurnManager` runs a timer (e.g., 5 seconds) and emits an `execution_tick` signal every frame or fixed interval.
4. **Resolution:** The phase halts. The engine cleans up dead units and resets AP before returning to Planning.

**Simultaneous Combat Resolution:**
If two units strike each other simultaneously, both must deal damage before either dies. The `CombatManager` achieves this by decoupling the *decision* to act from the *application* of the action.
During an execution tick, the `CombatManager`:

1. **Gathers:** Asks every unit's `AIConditionEvaluator` what they want to do.
2. **Queues:** Stores these intended actions.
3. **Executes:** Fires all queued actions in a single batch, ensuring damage and state changes happen concurrently.

---

### 2. Phase 5 Directory Tree

```text
res://
├── Core/
│   └── Systems/
│       ├── TurnManager.gd        # State machine managing the flow of time
│       └── CombatManager.gd      # Orchestrates simultaneous action resolution

```

---

### 3. Modular Node Scripts

#### A. The Turn Manager (State Machine)

This system governs time. It uses the `_process` loop only during the Execution phase to broadcast ticks to the simulation.

```gdscript
# File: res://Core/Systems/TurnManager.gd
class_name TurnManager extends Node

## Governs the WeGo turn phases and controls the flow of simulated time.
## Emits phase changes globally so UI and Combat systems can react.

enum TurnPhase {
	PLANNING,
	COMMIT,
	EXECUTION,
	RESOLUTION
}

@export var execution_phase_duration: float = 5.0 ## How many seconds the real-time execution lasts

var current_phase: TurnPhase = TurnPhase.PLANNING
var _execution_timer: float = 0.0

func _ready() -> void:
	# Ensure process only runs when we actually need it
	set_process(false)

## Called by the UI (e.g., "End Turn" button) to transition states.
func advance_phase() -> void:
	match current_phase:
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
		TurnPhase.PLANNING: return &"planning"
		TurnPhase.COMMIT: return &"commit"
		TurnPhase.EXECUTION: return &"execution"
		TurnPhase.RESOLUTION: return &"resolution"
	return &"unknown"

```

#### B. The Combat Manager (Simultaneous Resolution)

This manager listens to the execution ticks. It acts as the puppet master during the real-time simulation phase, querying units for their intended actions and resolving them in a synchronized batch.

```gdscript
# File: res://Core/Systems/CombatManager.gd
class_name CombatManager extends Node

## Orchestrates the WeGo simultaneous resolution.
## Gathers intended actions from all units and executes them concurrently.

var _active_units: Array[Node] = []
var _is_executing: bool = false

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Subscribing to EventBus signals
	EventBus.turn_phase_changed.connect(_on_phase_changed)
	EventBus.execution_tick.connect(_on_execution_tick)
	EventBus.unit_died.connect(_on_unit_died)

## Dependency Injection: Called by the BattlefieldManager to register units.
## @param units: Array of Unit nodes present on the board.
func initialize(units: Array[Node]) -> void:
	_active_units = units.duplicate()
	print("CombatManager initialized with %d units." % _active_units.size())

func _on_phase_changed(new_phase: StringName) -> void:
	_is_executing = (new_phase == &"execution")

## The core WeGo loop. Called every frame/tick during the Execution Phase.
func _on_execution_tick(_delta: float) -> void:
	if not _is_executing:
		return
		
	var queued_actions: Array[Dictionary] = []
	
	# 1. GATHER INTENTIONS
	for unit: Node in _active_units:
		# Safety check to ensure unit has the required component
		if not unit.has_node("AIConditionEvaluator"):
			continue
			
		var evaluator: AIConditionEvaluator = unit.get_node("AIConditionEvaluator")
		
		# Build the context blackboard (can be expanded to include MapManager data)
		var blackboard: Dictionary = {
			"delta": _delta,
			"all_units": _active_units
		}
		
		# EXTERNAL ACCESS NOTE: Querying the component from Phase 4
		var intended_action: ActionData = evaluator.determine_next_action(blackboard)
		
		if intended_action:
			# Calculate target position based on action logic (simplified here)
			var target_pos: Vector3i = unit.movement_component.current_coord
			
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
		var action: ActionData = command["action"]
		
		# EXTERNAL ACCESS NOTE: Calling the Resource script from Phase 1
		action.execute(command["unit"], command["target_pos"], command["blackboard"])

## Cleans up the roster so dead units do not participate in the next tick.
func _on_unit_died(unit_id: StringName) -> void:
	for i: int in range(_active_units.size() - 1, -1, -1):
		var unit: Node = _active_units[i]
		if unit.unit_id == unit_id:
			_active_units.remove_at(i)
			print("CombatManager: Removed dead unit %s from active roster." % unit_id)
			break

```

---