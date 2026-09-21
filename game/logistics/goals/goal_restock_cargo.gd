class_name GoalRestockCargo
extends GoapGoal

func _init():
	super._init(&"RestockCargo", 1.0)

	desired_conditions.append(GoapNumericRule.new(&"cargo_balance", GoapTypes.ComparisonOperator.GREATER_THAN_OR_EQUAL, 1.0))
