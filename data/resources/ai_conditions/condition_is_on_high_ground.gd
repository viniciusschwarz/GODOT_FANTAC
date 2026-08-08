# File: res://data/resources/ai_conditions/condition_is_on_high_ground.gd
class_name ConditionIsOnHighGround extends ConditionData

## AI CONDITION
## Returns true if the unit's current Z coordinate is greater than 0.

func evaluate(unit: Node, _blackboard: Dictionary) -> bool:
	# EXTERNAL ACCESS NOTE: Querying the unit's movement component
	var move_comp: MovementComponent = unit.get("movement_component")
	
	if move_comp:
		return move_comp.current_coord.z > 0
		
	return false