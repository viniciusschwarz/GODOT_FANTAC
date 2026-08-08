# File: res://data/resources/actions/action_melee_attack_nearest.gd
class_name ActionMeleeAttackNearest extends ActionData

## DUMMY ACTION FOR TESTING (UPDATED PHASE 11)
## Finds the nearest valid target and applies damage during the MELEE phase.

@export var attack_damage: int = 25

func _init() -> void:
	# Explicitly assign this action to the Melee phase queue
	execution_phase = ExecutionPhase.MELEE

func execute(unit: Node, _target_pos: Vector3i, blackboard: Dictionary) -> void:
	var all_units: Array[Node] = blackboard.get("all_units", [])
	var target: Node = null
	
	# EXTERNAL ACCESS NOTE: Querying components of sibling units in the blackboard
	for potential_target: Node in all_units:
		if potential_target != unit:
			var health_comp: HealthComponent = potential_target.health_component
			if health_comp and health_comp.current_health > 0:
				target = potential_target
				break
				
	if target:
		print("COMBAT LOG: %s executes Melee Attack on %s for %d damage!" % [unit.name, target.name, attack_damage])
		# EXTERNAL ACCESS NOTE: Applying damage directly to the target's HealthComponent
		target.health_component.take_damage(attack_damage)
	else:
		print("COMBAT LOG: %s found no valid targets to attack." % unit.name)