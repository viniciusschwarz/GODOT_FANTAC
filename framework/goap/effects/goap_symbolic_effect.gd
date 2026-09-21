class_name GoapSymbolicEffect
extends GoapEffect

var key: StringName
var operation: int
var value: Variant = null

func _init(p_key: StringName, p_operation: int, p_value: Variant = null):
	key = p_key
	operation = p_operation
	value = p_value

func apply_to(snapshot: GoapStateSnapshot) -> void:
	match operation:
		GoapTypes.SymbolicEffectOp.ASSIGN:
			snapshot.set_symbol(key, value)
		GoapTypes.SymbolicEffectOp.UNSET:
			snapshot.erase_symbol(key)
