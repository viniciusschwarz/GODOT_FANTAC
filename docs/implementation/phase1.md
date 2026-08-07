Commander, the foundation of a robust, commercial-grade tactical simulation begins with its data schema and communication backbone. Before a single sprite is drawn or a physics calculation is made, we must establish the immutable rules of the universe.

Welcome to **Phase 1: The Bedrock**.

In this phase, we will construct the global Event Bus to enforce strict decoupling, and we will define the core `Resource` classes that will drive our systemic, data-oriented gameplay.

---

### 1. Phase 1 Directory Tree

Before writing any code, set up the following directory structure in your Godot 4.x project:

```text
res://
├── Autoloads/
│   └── EventBus.gd                # Global Signal Hub
└── Data/
    └── Resources/
        ├── UnitStats.gd           # Core attributes
        ├── WeaponData.gd          # Equipment definitions
        ├── Actions/
        │   └── ActionData.gd      # Base class for AI/Player actions
        └── AI_Conditions/
            └── ConditionData.gd   # Base class for AI logic evaluation

```

*Make sure to add `res://Autoloads/EventBus.gd` to your project's Autoloads (Project -> Project Settings -> Globals -> Autoload).*

---

### 2. Architectural Logic: The Event Bus

**Why?** In a decoupled architecture, a `HealthComponent` should never know that a `UIHealthBar` exists. When a unit takes damage, it simply shouts into the void: *"I took damage!"* The UI, listening to the Event Bus, updates itself. This guarantees that if the UI breaks or is missing, the simulation continues flawlessly.

```gdscript
# File: res://Autoloads/EventBus.gd
extends Node

## THE EVENT BUS
## The global communication hub for cross-domain decoupling.
## External systems (UI, Audio, VFX) will subscribe to these signals.
## Simulation components will emit them.

# ==========================================
# COMBAT & SIMULATION SIGNALS
# ==========================================
signal unit_spawned(unit_node: Node)
signal unit_took_damage(unit_id: StringName, amount: int, current_health: int)
signal unit_died(unit_id: StringName)

# ==========================================
# WEGO TURN STATE SIGNALS
# ==========================================
## Phases could be: "planning", "commit", "execution", "halt"
signal turn_phase_changed(new_phase: StringName)
signal execution_tick(delta: float)

# ==========================================
# UI & INPUT SIGNALS
# ==========================================
## Fired when the player drags an AI node in the Tactics Board
signal ui_tactics_node_dropped(node_data: Resource, target_slot_id: StringName)
## Fired when the player selects a unit in the world
signal ui_unit_selected(unit_id: StringName)

```

---

### 3. Architectural Logic: Data-Driven Resources

**Why?** Units are just "dumb" physical containers. Their capabilities, stats, and AI intelligence are injected into them via Resources (`.tres` files). This allows us to create entirely new unit types, weapons, and AI behaviors directly in the Godot Inspector without writing new scripts.

#### A. Unit Stats Base

This resource holds the immutable base stats of a unit.

```gdscript
# File: res://Data/Resources/UnitStats.gd
class_name UnitStats extends Resource

## Defines the base attributes of a unit. 
## Does not contain active state (like current HP), only maximums and definitions.

@export var unit_name: String = "Unknown Conscript"
@export var max_health: int = 100
@export var max_ap: int = 10 ## Action Points available per Execution Phase
@export var base_movement_speed: int = 3 ## Grid tiles per AP

@export_category("Tactical Properties")
## If true, this unit can bypass ground obstacles (ignores Z-level pathing restrictions)
@export var is_flying: bool = false
@export var base_vision_range: int = 5 

```

#### B. Weapon & Equipment Data

Weapons are not just stat sticks; they alter how the WeGo system calculates Z-levels and grant new Actions to the unit's AI tree.

```gdscript
# File: res://Data/Resources/WeaponData.gd
class_name WeaponData extends Resource

## Defines weapon statistics and the tactical actions they unlock.
## External Data Dependency: Will reference ActionData resources.

@export var weapon_name: String = "Standard Sword"
@export var base_damage: int = 15

@export_category("Range & Verticality")
@export var base_range: int = 1 ## 1 is melee
## Multiplier applied when calculating Line of Sight from a higher Z-level
@export var height_range_multiplier: float = 1.0 

@export_category("Granted Abilities")
## Actions unlocked in the Tactics Board when equipped (e.g., "Thrust", "Block")
## EXTERNAL DATA: Array of ActionData Resources
@export var granted_actions: Array[ActionData] = []

```

#### C. The AI Engine: Conditions & Actions

The WeGo AI is a Behavior Tree built by the player. It relies on evaluating a `ConditionData` and, if true, executing an `ActionData`. We define their base classes here using the Strategy Pattern. Later, we will create specific scripts (e.g., `Condition_HPBelow.gd`) that inherit from these.

```gdscript
# File: res://Data/Resources/AI_Conditions/ConditionData.gd
class_name ConditionData extends Resource

## Base class for all AI Tactics Board Conditions.
## Player logic is built by chaining these (e.g., IF [Condition] -> THEN [Action])

@export var condition_name: String = "Base Condition"

## Evaluates the tactical situation. Must be overridden by child classes.
## @param unit: The Node executing the logic.
## @param blackboard: A Dictionary storing temporary state/context (e.g., current targets).
## @return bool: True if the condition is met.
func evaluate(unit: Node, blackboard: Dictionary) -> bool:
	# EXTERNAL ACCESS NOTE: Child classes will query the MapManager and LOSComponent here.
	push_warning("evaluate() called on base ConditionData. Must be overridden.")
	return false

```

```gdscript
# File: res://Data/Resources/Actions/ActionData.gd
class_name ActionData extends Resource

## Base class for all executable actions in the WeGo system.
## Includes Attacks, Movement, Spellcasting, and Defensive stances.

@export var action_name: String = "Base Action"
@export var ap_cost: int = 2
@export var target_required: bool = true

## Executes the physical action in the simulation. Must be overridden.
## @param unit: The unit performing the action.
## @param target_pos: The Vector3i grid position being targeted.
## @param blackboard: Context dictionary.
func execute(unit: Node, target_pos: Vector3i, blackboard: Dictionary) -> void:
	# EXTERNAL ACCESS NOTE: Child classes will interact with the EventBus and CombatComponent here.
	push_warning("execute() called on base ActionData. Must be overridden.")
	pass

```

---
