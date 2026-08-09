class_name AITreeEvaluator extends Node

enum ActionType {
	NONE,
	FALLBACK_TO_COVER,
	MELEE_ATTACK,
	RANGED_ATTACK,
	ADVANCE_TO_OBJECTIVE,
	HOLD_ANCHOR
}

func evaluate_unit_behavior(unit: UnitDataResource, matrix: BattlefieldMatrix, all_units: Dictionary, current_tick: int) -> Dictionary:
	var result := {
		"action_type": ActionType.NONE,
		"target_coord": Vector3i.ZERO,
		"telemetry_entry": {}
	}

	# Pre-compute all unit positions
	var all_unit_coords: Dictionary = {}
	for x in range(matrix._width):
		for y in range(matrix._depth):
			for z in range(matrix._height_levels):
				var coord := Vector3i(x, y, z)
				var tile := matrix.get_tile(coord)
				if tile and tile.occupying_unit_id != -1:
					all_unit_coords[tile.occupying_unit_id] = coord

	var unit_coord = all_unit_coords.get(unit.unit_id, Vector3i.ZERO)
	if not all_unit_coords.has(unit.unit_id):
		# If the unit is not on the board, return NONE
		return result

	# Identify valid enemy targets
	var melee_targets: Array[Dictionary] = []
	var ranged_targets: Array[Dictionary] = []
	var visible_enemies: Array[Dictionary] = []
	var all_alive_enemies: Array[Dictionary] = []

	for enemy_id in all_units:
		var enemy: UnitDataResource = all_units[enemy_id] # [EXTERNAL DATA ACCESS]
		if enemy.faction_id != unit.faction_id and enemy.current_hp > 0:
			if not all_unit_coords.has(enemy.unit_id):
				continue

			var enemy_coord = all_unit_coords[enemy.unit_id]

			# Melee Check
			var dx = enemy_coord.x - unit_coord.x
			var dy = enemy_coord.y - unit_coord.y
			if abs(dx) + abs(dy) == 1 and unit_coord.z == enemy_coord.z:
				melee_targets.append({ "unit": enemy, "coord": enemy_coord })

			# Ranged and Visibility Check
			var grid_dist = abs(enemy_coord.x - unit_coord.x) + abs(enemy_coord.y - unit_coord.y) + abs(enemy_coord.z - unit_coord.z)
			var in_range = (grid_dist >= unit.attack_range_min and grid_dist <= unit.attack_range_max)

			all_alive_enemies.append({ "unit": enemy, "coord": enemy_coord, "dist": grid_dist })

			# We only need to check LOS if they are in range OR for the visibility check
			var los_result = matrix.calculate_3d_line_of_sight(unit_coord, enemy_coord)
			var has_los = los_result.get("has_los", false)

			if has_los:
				visible_enemies.append({ "unit": enemy, "coord": enemy_coord, "dist": grid_dist })
				if in_range:
					ranged_targets.append({ "unit": enemy, "coord": enemy_coord })

	# Determine closest visible enemy coord for defaults
	var closest_visible_enemy_coord = Vector3i.ZERO
	if visible_enemies.size() > 0:
		visible_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
		closest_visible_enemy_coord = visible_enemies[0]["coord"]
	elif all_alive_enemies.size() > 0:
		all_alive_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
		closest_visible_enemy_coord = all_alive_enemies[0]["coord"]

	# Hysteresis Check
	var is_locked = current_tick < unit.template_parameters.get("fallback_lock_until_tick", 0)

	if is_locked:
		result["action_type"] = ActionType.FALLBACK_TO_COVER
		result["target_coord"] = unit_coord
		return result

	var hp_pct = float(unit.current_hp) / float(unit.max_hp)
	var active_template = unit.active_template_id

	if active_template == &"AGGRESSIVE_ASSAULT":
		# Branch 1: If current_hp / max_hp < 0.15 -> Action: Fallback_To_Cover.
		if hp_pct < 0.15:
			unit.template_parameters["fallback_lock_until_tick"] = current_tick + 15
			result["action_type"] = ActionType.FALLBACK_TO_COVER
			result["target_coord"] = unit_coord
			result["telemetry_entry"] = { "tick": current_tick, "msg": "Aggressive Assault: Falling back to cover" }
			return result

		# Branch 2: If enemy in melee range -> Action: Melee_Attack.
		if melee_targets.size() > 0:
			result["action_type"] = ActionType.MELEE_ATTACK
			result["target_coord"] = melee_targets[0]["coord"]
			return result

		# Default: Action: Advance_Shortest_Path_To_Objective.
		result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
		result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
		return result

	elif active_template == &"CAUTIOUS_OVERWATCH":
		# Branch 1: If current_hp / max_hp < 0.40 -> Action: Fallback_To_Cover.
		if hp_pct < 0.40:
			unit.template_parameters["fallback_lock_until_tick"] = current_tick + 15
			result["action_type"] = ActionType.FALLBACK_TO_COVER
			result["target_coord"] = unit_coord
			result["telemetry_entry"] = { "tick": current_tick, "msg": "Cautious Overwatch: Falling back to cover" }
			return result

		# Branch 2: If enemy in ranged threat envelope -> Action: Ranged_Trade_From_Cover (RANGED_ATTACK)
		if ranged_targets.size() > 0:
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = ranged_targets[0]["coord"]
			return result

		# Default: Action: Advance_Via_Cover_Tiles (ADVANCE_TO_OBJECTIVE)
		result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
		result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
		return result

	elif active_template == &"POINT_GUARD":
		# Branch 1: If enemy in melee/threat range -> Action: Attack_Target.
		if melee_targets.size() > 0:
			result["action_type"] = ActionType.MELEE_ATTACK
			result["target_coord"] = melee_targets[0]["coord"]
			return result

		if ranged_targets.size() > 0:
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = ranged_targets[0]["coord"]
			return result

		# Default: Action: Hold_Anchor_Tile.
		result["action_type"] = ActionType.HOLD_ANCHOR
		result["target_coord"] = unit.template_parameters.get("anchor_coord", unit_coord)
		return result

	if result["action_type"] == ActionType.ADVANCE_TO_OBJECTIVE or result["action_type"] == ActionType.FALLBACK_TO_COVER:
		var recalc_cooldown = unit.template_parameters.get("path_recalculation_cooldown", 0)
		if recalc_cooldown > 0:
			unit.template_parameters["path_recalculation_cooldown"] = recalc_cooldown - 1
			result["path_array"] = unit.template_parameters.get("current_path", [])
		else:
			var current_path = unit.template_parameters.get("current_path", [])
			if current_path.is_empty():
				var pf = PathfindingEngine.new()
				var new_path = pf.calculate_path(matrix, unit_coord, result["target_coord"], unit)
				unit.template_parameters["current_path"] = new_path
				result["path_array"] = new_path
			else:
				result["path_array"] = current_path

	return result
