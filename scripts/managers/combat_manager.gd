extends Node
## Pure logic/math service that calculates physical interaction results between units.

func _ready() -> void:
	SignalBus.wego_phase_started.connect(_on_phase_started)

func _on_phase_started(phase_name: String) -> void:
	if phase_name == "deployment":
		var roster: Array = []
		if GameState.current_mission and GameState.current_mission is MissionData:
			roster = GameState.current_mission.enemy_roster
		else:
			print("CombatManager: No current mission found, using empty roster for deployment.")

		var enemy_zones = MapGenerator.get_enemy_deployment_zones()
		SignalBus.enemy_deployment_requested.emit(roster, enemy_zones)

## Calculates damage based on weapon type, armor type, elevation, and facing.
func calculate_damage(attacker: Node, defender: Node, weapon: WeaponData, armor: ArmorData, attacker_elevation: int, defender_elevation: int, attack_vector: Vector2, defender_facing: Vector2) -> int:
	if not weapon:
		return 0

	var base_dmg: int = weapon.base_damage
	var damage_modifier: float = 1.0
	var final_damage: int = base_dmg

	# Elevation Bonus
	if attacker_elevation > defender_elevation:
		damage_modifier += 0.2 # 20% bonus from high ground
	elif attacker_elevation < defender_elevation:
		damage_modifier -= 0.1 # 10% penalty for attacking uphill

	# Armor vs Damage Type Logic (Simplified)
	if armor:
		match weapon.damage_type:
			WeaponData.DamageType.SLASHING:
				if armor.armor_type == ArmorData.ArmorType.HEAVY:
					damage_modifier -= 0.5
			WeaponData.DamageType.PIERCING:
				if armor.armor_type == ArmorData.ArmorType.SHIELD:
					var angle: float = attack_vector.angle_to(defender_facing)
					if abs(angle) > PI / 2:
						if randf() <= armor.block_chance:
							return 0
			WeaponData.DamageType.BLUNT:
				pass

		final_damage = int(base_dmg * damage_modifier)

		var reduction: int = max(0, armor.damage_reduction - weapon.armor_penetration)
		final_damage = max(1, final_damage - reduction)

	return final_damage

## Calculates the physical impact (knockback) vector.
func calculate_impact(weapon: WeaponData, attack_direction: Vector2) -> Vector2:
	if weapon and weapon.knockback_force > 0:
		return attack_direction.normalized() * weapon.knockback_force
	return Vector2.ZERO
