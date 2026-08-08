# File: res://data/resources/ai_conditions/condition_enemy_in_ranged_los.gd
class_name ConditionEnemyInRangedLOS extends ConditionData

## AI CONDITION (UPDATED)
## Returns true if an enemy is visible and within the targeting range.

@export var targeting_range: float = 6.0 ## Maximum distance to acquire targets

func evaluate(unit: Node, blackboard: Dictionary) -> bool:
	var los_comp: LOSComponent = unit.get("los_component")
	var move_comp: MovementComponent = unit.get("movement_component")
	
	if not los_comp or not move_comp:
		return false
		
	var all_units: Array[Node] = blackboard.get("all_units", [])
	
	for potential_target: Node in all_units:
		if potential_target == unit:
			continue 
			
		var target_move: MovementComponent = potential_target.get("movement_component")
		var target_health: HealthComponent = potential_target.get("health_component")
		
		if target_move and target_health and target_health.current_health > 0:
			var target_coord: Vector3i = target_move.current_coord
			
			var distance: float = _calculate_3d_distance(move_comp.current_coord, target_coord)
			
			if distance <= targeting_range:
				# EXTERNAL ACCESS NOTE: Querying the heavy LOS algorithm
				if los_comp.has_line_of_sight(target_coord):
					blackboard["default_target_coord"] = target_coord
					return true
					
	return false

func _calculate_3d_distance(a: Vector3i, b: Vector3i) -> float:
	var dx: float = float(a.x - b.x)
	var dy: float = float(a.y - b.y)
	var dz: float = float(a.z - b.z)
	return sqrt((dx * dx) + (dy * dy) + (dz * dz))