class_name GoapNumericRule
extends GoapCondition

var key: StringName
var operator: int
var target_value: float
var range_max: float = 0.0

func _init(p_key: StringName, p_operator: int, p_target_value: float, p_range_max: float = 0.0):
	key = p_key
	operator = p_operator
	target_value = p_target_value
	range_max = p_range_max

func evaluates(snapshot: GoapStateSnapshot, _context: Dictionary = {}) -> bool:
	if not snapshot.has_number(key):
		return false

	var val: float = snapshot.get_number(key)

	match operator:
		GoapTypes.ComparisonOperator.EQUALS:
			return val == target_value
		GoapTypes.ComparisonOperator.NOT_EQUALS:
			return val != target_value
		GoapTypes.ComparisonOperator.GREATER_THAN:
			return val > target_value
		GoapTypes.ComparisonOperator.GREATER_THAN_OR_EQUAL:
			return val >= target_value
		GoapTypes.ComparisonOperator.LESS_THAN:
			return val < target_value
		GoapTypes.ComparisonOperator.LESS_THAN_OR_EQUAL:
			return val <= target_value
		GoapTypes.ComparisonOperator.RANGE_INCLUSIVE:
			return val >= target_value and val <= range_max
		GoapTypes.ComparisonOperator.HAS_BITMASK:
			return (int(val) & int(target_value)) == int(target_value)

	return false
