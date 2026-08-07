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
