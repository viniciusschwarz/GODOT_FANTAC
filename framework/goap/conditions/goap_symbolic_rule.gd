class_name GoapSymbolicRule
extends GoapCondition

var key: StringName
var target_value: Variant
var negate: bool = false

func _init(p_key: StringName, p_target_value: Variant, p_negate: bool = false):
	key = p_key
	target_value = p_target_value
	negate = p_negate

func evaluates(snapshot: GoapStateSnapshot, _context: Dictionary = {}) -> bool:
	var val = snapshot.get_symbol(key, null)
	var matches: bool = (val == target_value)

	if negate:
		return not matches
	else:
		return matches
