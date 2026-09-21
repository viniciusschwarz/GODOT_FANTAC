class_name GoapAction
extends RefCounted

var action_name: StringName
var base_cost: float = 1.0
var preconditions: Array[GoapCondition] = []
var effects: Array[GoapEffect] = []

func generate_bindings(_snapshot: GoapStateSnapshot, _context: Dictionary) -> Array[GoapActionBinding]:
	return [GoapActionBinding.new(self, {})]

func calculate_cost(_snapshot: GoapStateSnapshot, _binding: GoapActionBinding, _context: Dictionary) -> float:
	return base_cost

func check_procedural_precondition(_snapshot: GoapStateSnapshot, _binding: GoapActionBinding, _context: Dictionary) -> bool:
	return true

func on_enter(_binding: GoapActionBinding, _context: Dictionary) -> void:
	pass

func on_step(_tick: int, _binding: GoapActionBinding, _context: Dictionary, _cmd_bus: Object = null) -> int:
	return GoapTypes.ActionStatus.COMPLETED

func on_exit(_binding: GoapActionBinding, _context: Dictionary) -> void:
	pass

func on_abort(_binding: GoapActionBinding, _context: Dictionary) -> void:
	pass
