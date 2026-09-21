class_name GoapCondition
extends RefCounted

## Evaluates whether the state snapshot satisfies this condition against dynamic runtime context.
func evaluates(_snapshot: GoapStateSnapshot, _context: Dictionary = {}) -> bool:
	return false
