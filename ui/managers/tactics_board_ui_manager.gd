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
	if rules_container:
		for child: Node in rules_container.get_children():
			child.queue_free()

	if not _current_tree or not rules_container or not node_prefab_scene:
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
