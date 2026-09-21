class_name GoapStateSnapshot
extends RefCounted

var symbols: Dictionary = {}
var numbers: Dictionary = {}

func set_symbol(key: StringName, value: Variant) -> void:
	symbols[key] = value

func get_symbol(key: StringName, default_value: Variant = null) -> Variant:
	return symbols.get(key, default_value)

func has_symbol(key: StringName) -> bool:
	return symbols.has(key)

func erase_symbol(key: StringName) -> void:
	symbols.erase(key)

func set_number(key: StringName, value: float) -> void:
	numbers[key] = value

func get_number(key: StringName, default_value: float = 0.0) -> float:
	return numbers.get(key, default_value)

func has_number(key: StringName) -> bool:
	return numbers.has(key)

func erase_number(key: StringName) -> void:
	numbers.erase(key)

func duplicate_snapshot() -> GoapStateSnapshot:
	var copy = GoapStateSnapshot.new()
	copy.symbols = symbols.duplicate(true)
	copy.numbers = numbers.duplicate(true)
	return copy

static func _serialize_symbol_value(val: Variant) -> String:
	match typeof(val):
		TYPE_BOOL:
			return "b:" + str(val)
		TYPE_INT:
			return "i:" + str(val)
		TYPE_STRING_NAME, TYPE_STRING:
			return "s:" + str(val)
		_:
			return "v:" + str(val)

func compute_hash() -> String:
	var s_keys = symbols.keys()
	s_keys.sort()
	var s_parts = []
	for k in s_keys:
		s_parts.append(str(k) + "=" + _serialize_symbol_value(symbols[k]))

	var n_keys = numbers.keys()
	n_keys.sort()
	var n_parts = []
	for k in n_keys:
		n_parts.append(str(k) + "=" + ("%.4f" % numbers[k]))

	var s_str = ";".join(s_parts)
	var n_str = ";".join(n_parts)

	return "s:[" + s_str + "]|n:[" + n_str + "]"
