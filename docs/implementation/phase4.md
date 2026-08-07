Commander, we have reached **Phase 4: The Brains**. This is where your players will spend hours optimizing their strategies.

Our units are currently empty shells. To give them autonomy during the simultaneous Execution Phase, we need a logic parser. By adhering to our Data-Driven Design, we will not hardcode AI behaviors. Instead, we will create a priority-based list of rules (a simplified Behavior Tree) that the player configures in the UI and saves as a `Resource`.

### 1. Architectural Logic: The AI Evaluator

**The Rule Structure:**
Instead of a complex branching tree which can be visually overwhelming in a UI, we will use a **Priority List of Rules**. Each rule (an `AIRuleData` resource) asks a simple question: *"If this `ConditionData` is true, then perform this `ActionData`."*

**The Evaluator Component:**
The `AIConditionEvaluator` is a script attached to the `Unit`. During the WeGo combat execution, a higher-level system (like a `TurnManager`) will ask this component: *"What should this unit do right now?"*
The component iterates through its injected list of rules from top to bottom. The first condition that evaluates to `true` instantly returns its associated action.

**The Blackboard:**
Because conditions need context (e.g., "Where are the enemies?", "What is the map state?"), we pass a `blackboard` (a generic Dictionary) into the evaluation function. This keeps the AI decoupled from the physical scene tree; it only knows what data is handed to it.

---

### 2. Phase 4 Directory Tree

```text
res://
├── Core/
│   └── Components/
│       └── AIConditionEvaluator.gd # Parses rules and returns valid actions
└── Data/
    └── Resources/
        ├── AI_Conditions/
        │   └── AIRuleData.gd       # Pairs 1 Condition with 1 Action
        └── AITreeData.gd           # The full list of rules for a unit

```

---

### 3. Data-Driven Resources

First, we define a single rule, and then the container that holds the player's custom priority list.

```gdscript
# File: res://Data/Resources/AI_Conditions/AIRuleData.gd
class_name AIRuleData extends Resource

## A single tactical directive configured by the player.
## Matches a specific tactical condition to an executable action.

@export var rule_name: String = "New Rule"

## EXTERNAL DATA DEPENDENCY: ConditionData from Phase 1
@export var condition: ConditionData

## EXTERNAL DATA DEPENDENCY: ActionData from Phase 1
@export var action: ActionData

```

```gdscript
# File: res://Data/Resources/AITreeData.gd
class_name AITreeData extends Resource

## The complete "Brain" of a unit. 
## Configured by the player in the Tactics Board UI.

@export var tree_name: String = "Default Defensive Tree"

## A prioritized array of rules. Evaluated from index 0 downwards.
## EXTERNAL DATA DEPENDENCY: Array of AIRuleData resources.
@export var rules: Array[AIRuleData] = []

## Fallback action if absolutely no conditions are met (e.g., Idle/Defend)
## EXTERNAL DATA DEPENDENCY: ActionData from Phase 1
@export var fallback_action: ActionData

```

---

### 4. Modular Node Scripts (The Evaluator Component)

This component will be added to the `Unit.tscn` right next to the `HealthComponent` and `MovementComponent`. Notice how it has zero combat logic inside it; it purely routes the data.

```gdscript
# File: res://Core/Components/AIConditionEvaluator.gd
class_name AIConditionEvaluator extends Node

## Reads the unit's AITreeData resource and evaluates tactical conditions.
## Returns the highest-priority valid action to the simulation engine.

var _ai_tree: AITreeData
var _parent_unit: Node

## Injected by the Unit container upon spawning.
## @param tree_data: The specific AI strategy assigned to this unit by the player.
## @param parent: The unit node this AI belongs to (needed for context).
func initialize(tree_data: AITreeData, parent: Node) -> void:
	if not tree_data:
		push_warning("AIConditionEvaluator initialized without AITreeData. Unit will be inert.")
		
	_ai_tree = tree_data
	_parent_unit = parent
	print("AIConditionEvaluator initialized for %s" % _parent_unit.name)

## Called by the simulation (e.g., TurnManager) during the Execution Phase.
## Parses the rules top-to-bottom and returns the first valid action.
## @param blackboard: A dictionary containing battlefield context (enemies, map grid, etc.)
## @return ActionData: The action the unit intends to execute.
func determine_next_action(blackboard: Dictionary) -> ActionData:
	if not _ai_tree:
		return null
		
	# 1. Iterate through the priority list of rules
	for rule: AIRuleData in _ai_tree.rules:
		# Safety check for unconfigured rules
		if not rule.condition or not rule.action:
			continue
			
		# 2. Evaluate the condition (EXTERNAL ACCESS: Calls Resource logic)
		# We pass the parent unit and the blackboard so the condition can analyze the board state
		var is_condition_met: bool = rule.condition.evaluate(_parent_unit, blackboard)
		
		if is_condition_met:
			print("AI Evaluator: Condition '%s' met. Executing '%s'." % [rule.condition.condition_name, rule.action.action_name])
			return rule.action
			
	# 3. If no conditions match, return the default behavior
	if _ai_tree.fallback_action:
		print("AI Evaluator: No conditions met. Executing Fallback Action.")
		return _ai_tree.fallback_action
		
	return null

```

---