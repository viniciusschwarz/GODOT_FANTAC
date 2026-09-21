class_name GoapNumericEffect
extends GoapEffect

var key: StringName
var operation: int
var operand: float

func _init(p_key: StringName, p_operation: int, p_operand: float):
	key = p_key
	operation = p_operation
	operand = p_operand

func apply_to(snapshot: GoapStateSnapshot) -> void:
	match operation:
		GoapTypes.NumericEffectOp.ASSIGN:
			snapshot.set_number(key, operand)
		GoapTypes.NumericEffectOp.ADD:
			snapshot.set_number(key, snapshot.get_number(key, 0.0) + operand)
		GoapTypes.NumericEffectOp.SUBTRACT:
			snapshot.set_number(key, snapshot.get_number(key, 0.0) - operand)
		GoapTypes.NumericEffectOp.MIN:
			snapshot.set_number(key, minf(snapshot.get_number(key, 0.0), operand))
		GoapTypes.NumericEffectOp.MAX:
			snapshot.set_number(key, maxf(snapshot.get_number(key, 0.0), operand))
