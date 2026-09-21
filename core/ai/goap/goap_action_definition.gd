class_name GoapActionDefinition
extends RefCounted

var action_id: StringName
var base_cost: int = 1
var preconditions: Dictionary = {} # Key: StringName -> Value: Variant (primitives only)
var effects: Dictionary = {}       # Key: StringName -> Value: Variant (primitives only)
