class_name GoapActionBinding
extends RefCounted

var action: GoapAction
var parameters: Dictionary

func _init(p_action: GoapAction, p_parameters: Dictionary = {}):
	action = p_action
	parameters = p_parameters

func get_param(key: StringName, default_value: Variant = null) -> Variant:
	return parameters.get(key, default_value)

func has_param(key: StringName) -> bool:
	return parameters.has(key)

func get_action_name() -> StringName:
	return action.action_name
