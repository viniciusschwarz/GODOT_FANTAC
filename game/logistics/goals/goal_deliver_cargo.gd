class_name GoalDeliverCargo
extends GoapGoal

func _init():
	super._init(&"DeliverCargo", 1.0)

	desired_conditions.append(GoapNumericRule.new(&"cargo_balance", GoapTypes.ComparisonOperator.LESS_THAN_OR_EQUAL, 0.0))
	desired_conditions.append(GoapSymbolicRule.new(&"cargo_delivered", true))
