extends Node
## Pure logic/math service that calculates physical interaction results between units.

## Calculates damage based on weapon type, armor type, elevation, and facing.
func calculate_damage(attacker: Node, defender: Node, weapon: WeaponData, armor: ArmorData, attacker_elevation: int, defender_elevation: int, attack_vector: Vector2, defender_facing: Vector2) -> int:
	if not weapon:
		return 0

	var base_dmg = weapon.base_damage
	var damage_modifier = 1.0
	var final_damage = base_dmg

	# Elevation Bonus
	if attacker_elevation > defender_elevation:
		damage_modifier += 0.2 # 20% bonus from high ground

	# Armor vs Damage Type Logic (Simplified)
	if armor:
		match weapon.damage_type:
			WeaponData.DamageType.SLASHING:
				if armor.armor_type == ArmorData.ArmorType.HEAVY:
					damage_modifier -= 0.5 # Slashing is weak against plate
			WeaponData.DamageType.PIERCING:
				if armor.armor_type == ArmorData.ArmorType.SHIELD:
					# Check facing for shield block
					var angle = attack_vector.angle_to(defender_facing)
					if abs(angle) > PI / 2: # Attacking from the front arc
						if randf() <= armor.block_chance:
							return 0 # Attack blocked
			WeaponData.DamageType.BLUNT:
				# Blunt bypasses some armor damage reduction
				pass

		final_damage = int(base_dmg * damage_modifier)

		# Apply flat armor reduction, minimum 1 damage if attack hits
		var reduction = max(0, armor.damage_reduction - weapon.armor_penetration)
		final_damage = max(1, final_damage - reduction)

	return final_damage

## Calculates the physical impact (knockback) vector.
func calculate_impact(weapon: WeaponData, attack_direction: Vector2) -> Vector2:
	if weapon and weapon.knockback_force > 0:
		return attack_direction.normalized() * weapon.knockback_force
	return Vector2.ZERO
