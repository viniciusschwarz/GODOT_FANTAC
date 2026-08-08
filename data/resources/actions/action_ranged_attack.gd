# File: res://data/resources/actions/action_ranged_attack.gd
class_name ActionRangedAttack extends ActionData

## RANGED COMBAT ACTION
## Verifies Line of Sight and executes during the Ranged micro-phase.

@export var attack_damage: int = 15

func _init() -> void:
	# Explicitly assign this action to the Ranged phase queue
	execution_phase = ExecutionPhase.RANGED_AND_MAGIC
	action_range = 5
	target_required = true

func execute(unit: Node, target_coord: Vector3i, blackboard: Dictionary) -> void:
	# 1. Component Verification
	var los_comp: LOSComponent = unit.get("los_component")
	if not los_comp:
		push_error("ActionRangedAttack: Executing unit missing LOSComponent.")
		return
		
	# 2. Line of Sight Verification
	# EXTERNAL ACCESS NOTE: Querying the Unit's LOSComponent
	if not los_comp.has_line_of_sight(target_coord):
		print("COMBAT LOG: %s's shot is blocked! Target out of sight." % unit.name)
		return
		
	# 3. Target Resolution
	var target: Node = _find_unit_at_coord(target_coord, blackboard)
	
	if target:
		print("COMBAT LOG: %s fires an arrow at %s for %d damage!" % [unit.name, target.name, attack_damage])
		# EXTERNAL ACCESS NOTE: Applying damage via dependency injection routing
		target.health_component.take_damage(attack_damage)
	else:
		print("COMBAT LOG: %s fired at an empty coordinate." % unit.name)

## Helper function to find a unit based on its position in the grid
func _find_unit_at_coord(coord: Vector3i, blackboard: Dictionary) -> Node:
	var all_units: Array[Node] = blackboard.get("all_units", [])
	# EXTERNAL ACCESS NOTE: Querying sibling units' movement components
	for u: Node in all_units:
		if u.movement_component and u.movement_component.current_coord == coord:
			return u
	return null