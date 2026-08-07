Commander, welcome to **Phase 6: The Tactics Board UI**.

This is where many strategy games devolve into spaghetti code. Interface logic has a dangerous tendency to entangle itself with simulation math. We will prevent this by strictly enforcing the **"No Logic in UI"** directive.

### 1. Architectural Logic: The Centralized UI Manager

**The Visual Container (`AINodePrefab`):**
The individual slots on the screen (representing a "Condition" or an "Action") are completely lobotomized. They do not know what an AI Tree is. They only know two things:

1. How to display the icon/text of the Godot `Resource` injected into them.
2. How to catch Godot's built-in GUI drag-and-drop events and instantly broadcast them to the `EventBus`.

**The Brain (`TacticsBoardUIManager`):**
This Manager acts as the sole authority over the interface. It takes the `AITreeData` resource, dynamically instantiates the `AINodePrefab` for every rule, and listens to the `EventBus`. When a player drops an "Action" into a new slot, the Manager receives the signal, modifies the underlying `AITreeData` array, and commands the UI to visually refresh.

---

### 2. Phase 6 Directory Tree

```text
res://
└── UI/
    ├── Managers/
    │   └── TacticsBoardUIManager.gd # Centralized drag/drop logic & instantiator
    └── Prefabs/
        ├── AINodePrefab.tscn        # Reusable UI slot (Control Node)
        └── AINodePrefab.gd          # Purely visual rendering & input catching

```

*Note: This relies on the `ui_tactics_node_dropped` signal we defined in the `EventBus` during Phase 1.*

---

### 3. Modular Node Scripts

#### A. The Dynamic Prefab (Visual & Input Only)

This script is attached to a `PanelContainer` or `TextureRect`. It handles Godot's native drag-and-drop GUI methods but explicitly delegates the *resolution* of the drop to the Manager via the global Event Bus.

```gdscript
# File: res://UI/Prefabs/AINodePrefab.gd
class_name AINodePrefab extends Control

## PURE VISUAL PREFAB
## Displays a ConditionData or ActionData. Contains zero game logic.
## Emits drag-and-drop events globally for managers to resolve.

@onready var label: Label = $Label # Assuming a Label child exists in the scene

var _held_resource: Resource
var _rule_index: int
var _slot_type: StringName ## E.g., &"condition" or &"action"

## Dependency Injection: Called by the TacticsBoardUIManager to setup visuals.
## @param data: The ConditionData or ActionData resource.
## @param rule_index: Which row this slot belongs to in the AI Tree array.
## @param slot_type: Identifies if this is the IF or THEN slot.
func initialize(data: Resource, rule_index: int, slot_type: StringName) -> void:
	_held_resource = data
	_rule_index = rule_index
	_slot_type = slot_type
	
	_refresh_visuals()

func _refresh_visuals() -> void:
	if not _held_resource:
		label.text = "Empty %s" % _slot_type.capitalize()
		return
		
	# EXTERNAL ACCESS NOTE: Reading properties from the Data Resources (Phase 1 & 4)
	if _held_resource is ConditionData:
		label.text = (_held_resource as ConditionData).condition_name
	elif _held_resource is ActionData:
		label.text = (_held_resource as ActionData).action_name

# ==========================================
# GODOT NATIVE DRAG & DROP API
# ==========================================

## Called by Godot when the player clicks and drags this Control node.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not _held_resource:
		return null
		
	# Generate a visual preview for the mouse cursor
	var preview: Label = Label.new()
	preview.text = label.text
	set_drag_preview(preview)
	
	# Create the payload dictionary
	var payload: Dictionary = {
		"source_resource": _held_resource,
		"source_index": _rule_index,
		"source_type": _slot_type
	}
	
	return payload

## Called by Godot as a dragged item hovers over this Control.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
		
	# Only allow dropping if the types match (e.g., Condition into Condition slot)
	var dict_data: Dictionary = data as Dictionary
	return dict_data.has("source_type") and dict_data["source_type"] == _slot_type

## Called by Godot when the player releases the mouse over this Control.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var payload: Dictionary = data as Dictionary
	
	var target_slot_info: Dictionary = {
		"target_index": _rule_index,
		"target_type": _slot_type
	}
	
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload.
	# We strictly do NOT swap the resources here. The Manager handles the logic.
	EventBus.ui_tactics_node_dropped.emit(payload, target_slot_info)

```

#### B. The Tactics Board UI Manager (The Logic Authority)

This script sits on the root of the Tactics Board UI screen. It holds the active `AITreeData` resource, dynamically spawns the rows, and resolves any drag-and-drop operations, adhering to our Data-Driven mandate.

```gdscript
# File: res://UI/Managers/TacticsBoardUIManager.gd
class_name TacticsBoardUIManager extends Control

## CENTRALIZED UI LOGIC AUTHORITY
## Manages the AITreeData editing interface. Resolves all drag-and-drop events.

@export var node_prefab_scene: PackedScene ## Reference to AINodePrefab.tscn
@export var rules_container: VBoxContainer ## The UI container for the dynamic list

var _current_tree: AITreeData

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Subscribe to the global UI event
	EventBus.ui_tactics_node_dropped.connect(_on_node_dropped)

## Called when the player opens the Tactics Board for a specific unit.
## @param tree_data: The Resource representing the unit's brain.
func load_tree(tree_data: AITreeData) -> void:
	_current_tree = tree_data
	_rebuild_interface()

## Clears the current UI and instantiates fresh prefabs based on the Resource data.
func _rebuild_interface() -> void:
	# Clear existing children (Dynamic Instantiation rule)
	for child: Node in rules_container.get_children():
		child.queue_free()
		
	if not _current_tree:
		return
		
	# EXTERNAL ACCESS NOTE: Looping through the AIRuleData resources
	for i: int in range(_current_tree.rules.size()):
		var rule: AIRuleData = _current_tree.rules[i]
		
		# Create a horizontal row container for the Rule
		var row: HBoxContainer = HBoxContainer.new()
		rules_container.add_child(row)
		
		# Instantiate IF (Condition) Prefab
		var condition_node: AINodePrefab = node_prefab_scene.instantiate() as AINodePrefab
		row.add_child(condition_node)
		condition_node.initialize(rule.condition, i, &"condition")
		
		# Instantiate THEN (Action) Prefab
		var action_node: AINodePrefab = node_prefab_scene.instantiate() as AINodePrefab
		row.add_child(action_node)
		action_node.initialize(rule.action, i, &"action")

## Resolves the logic when a node is dragged and dropped.
## @param payload: Data from the slot that was dragged.
## @param target_info: Data from the slot that received the drop.
func _on_node_dropped(payload: Dictionary, target_info: Dictionary) -> void:
	if not _current_tree:
		return
		
	var source_idx: int = payload["source_index"]
	var target_idx: int = target_info["target_index"]
	var slot_type: StringName = payload["source_type"]
	
	# Execute the logical swap within the Resource data
	# EXTERNAL ACCESS NOTE: Modifying AIRuleData resources directly
	if slot_type == &"condition":
		var temp: ConditionData = _current_tree.rules[target_idx].condition
		_current_tree.rules[target_idx].condition = _current_tree.rules[source_idx].condition
		_current_tree.rules[source_idx].condition = temp
		print("Swapped Conditions between Rule %d and Rule %d" % [source_idx, target_idx])
		
	elif slot_type == &"action":
		var temp: ActionData = _current_tree.rules[target_idx].action
		_current_tree.rules[target_idx].action = _current_tree.rules[source_idx].action
		_current_tree.rules[source_idx].action = temp
		print("Swapped Actions between Rule %d and Rule %d" % [source_idx, target_idx])
		
	# Trigger a total UI rebuild to reflect the new data state
	_rebuild_interface()

```

---