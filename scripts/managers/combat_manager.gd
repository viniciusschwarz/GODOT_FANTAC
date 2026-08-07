extends Node
## Pure logic/math service that calculates physical interaction results between units.


func _ready() -> void:
	SignalBus.wego_phase_started.connect(_on_phase_started)
	SignalBus.unit_died.connect(_on_unit_died)

func _on_unit_died(unit: Node) -> void:
	# Check win/loss condition
	# Count active units for each team. We can iterate over AIManager.active_units
	var player_units_alive = 0
	var enemy_units_alive = 0

	if AIManager:
		for u in AIManager.active_units:
			# Skip the unit that just died since it might still be in the array
			if u == unit:
				continue

			if u.get("team_id") != null:
				if u.team_id == 0:
					player_units_alive += 1
				elif u.team_id == 1:
					enemy_units_alive += 1

	if player_units_alive == 0 and enemy_units_alive > 0:
		_end_combat("defeat")
	elif enemy_units_alive == 0 and player_units_alive > 0:
		_end_combat("victory")
	elif player_units_alive == 0 and enemy_units_alive == 0:
		_end_combat("draw")

func _end_combat(result: String) -> void:
	print("CombatManager: Combat ended with result: ", result)
	GameState.last_battle_results = {"result": result}
	SignalBus.combat_ended.emit(result)


func _on_phase_started(phase_name: String) -> void:
	pass

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
