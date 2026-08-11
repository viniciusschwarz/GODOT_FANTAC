class_name AITreeEvaluator extends Node

enum ActionType {
	NONE,
	FALLBACK_TO_COVER,
	MELEE_ATTACK,
	RANGED_ATTACK,
	ADVANCE_TO_OBJECTIVE,
	HOLD_ANCHOR,
	HOLD_ENGAGEMENT
}

const NULL_COORD = Vector3i(-1, -1, -1)


func evaluate_ranged_attack(unit: UnitDataResource, unit_coord: Vector3i, matrix: BattlefieldMatrix, ranged_targets: Array) -> Dictionary:
	for target in ranged_targets:
		var los_result = matrix.calculate_3d_line_of_sight(unit_coord, target.coord)
		if los_result.get("has_los", false):
			return { "success": true, "target": target }
	return { "success": false }

func evaluate_unit_behavior(unit: UnitDataResource, matrix: BattlefieldMatrix, all_units: Dictionary, current_tick: int, telemetry_logger: TurnTelemetryLogger, directive: Dictionary = {}) -> Dictionary:
	var result := {
		"action_type": ActionType.NONE,
		"target_coord": NULL_COORD,
		"telemetry_entries": []
	}

	var pf = PathfindingEngine.new()

	# Pre-compute all unit positions
	var all_unit_coords: Dictionary = {}
	for u_id in all_units:
		var u = all_units[u_id]
		var ux = u.template_parameters.get("last_coord_x", -1)
		var uy = u.template_parameters.get("last_coord_y", -1)
		var uz = u.template_parameters.get("last_coord_z", -1)
		if ux != -1:
			all_unit_coords[u_id] = Vector3i(ux, uy, uz)

	var unit_coord = all_unit_coords.get(unit.unit_id, NULL_COORD)
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
			if pf._is_cardinal_adjacent(unit_coord, enemy_coord, matrix):
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
	var closest_visible_enemy_coord = NULL_COORD
	if visible_enemies.size() > 0:
		visible_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
		closest_visible_enemy_coord = visible_enemies[0]["coord"]
	elif all_alive_enemies.size() > 0:
		all_alive_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
		closest_visible_enemy_coord = all_alive_enemies[0]["coord"]

	var on_cooldown = unit.template_parameters.get("attack_cooldown", 0) > 0

	# Process Manual UI Override Directive
	if directive and directive.has("type") and directive.type == "ATTACK":
		var target_id = directive.get("target_id", -1)
		if all_units.has(target_id):
			var target_unit = all_units[target_id]
			if target_unit.current_hp > 0 and all_unit_coords.has(target_id):
				var target_coord = all_unit_coords[target_id]
				result["telemetry_entries"].append(telemetry_logger.log_ui_intent(current_tick, unit.unit_id, target_id, "ATTACK"))

				var dx = target_coord.x - unit_coord.x
				var dy = target_coord.y - unit_coord.y
				var dz = target_coord.z - unit_coord.z
				var dist = abs(dx) + abs(dy) + abs(dz)

				var is_adjacent = pf._is_cardinal_adjacent(unit_coord, target_coord, matrix)
				var in_ranged_envelope = dist >= unit.attack_range_min and dist <= unit.attack_range_max
				var los_result = matrix.calculate_3d_line_of_sight(unit_coord, target_coord)
				var has_los = los_result.get("has_los", false)

				if is_adjacent:
					if not on_cooldown:
						result["action_type"] = ActionType.MELEE_ATTACK
						result["target_id"] = target_id
						result["target_coord"] = target_coord
					else:
						result["action_type"] = ActionType.HOLD_ENGAGEMENT
						result["target_coord"] = unit_coord
					return result
				elif in_ranged_envelope and has_los:
					if not on_cooldown:
						result["action_type"] = ActionType.RANGED_ATTACK
						result["target_id"] = target_id
						result["target_coord"] = target_coord
					else:
						result["action_type"] = ActionType.HOLD_ENGAGEMENT
						result["target_coord"] = unit_coord
					return result
				else:
					result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
					result["target_coord"] = target_coord

					var recalc_cooldown = unit.template_parameters.get("path_recalculation_cooldown", 0)
					if recalc_cooldown > 0:
						unit.template_parameters["path_recalculation_cooldown"] = recalc_cooldown - 1
						result["path_array"] = unit.template_parameters.get("current_path", [])
					else:
						var current_path = unit.template_parameters.get("current_path", [])
						if current_path.is_empty():
							var new_path = pf.calculate_path(matrix, unit_coord, target_coord, unit)
							if new_path.size() > 0:
								result["telemetry_entries"].append(telemetry_logger.log_pathfinding(current_tick, unit.unit_id, "Path generated (Length: " + str(new_path.size()) + ")"))
								unit.template_parameters["current_path"] = new_path
								result["path_array"] = new_path
							else:
								result["telemetry_entries"].append(telemetry_logger.log_pathfinding(current_tick, unit.unit_id, "Path failed (Unreachable)"))
								result["action_type"] = ActionType.HOLD_ANCHOR
								result["target_coord"] = unit_coord
								unit.template_parameters["fallback_lock_until_tick"] = current_tick + 10
								unit.template_parameters["locked_action_type"] = ActionType.HOLD_ANCHOR
								unit.template_parameters["current_path"] = []
								result["path_array"] = []
						else:
							result["path_array"] = current_path
					return result

	# Hysteresis Check
	var is_locked = current_tick < unit.template_parameters.get("fallback_lock_until_tick", 0)

	if is_locked:
		result["action_type"] = unit.template_parameters.get("locked_action_type", ActionType.FALLBACK_TO_COVER)
		result["target_coord"] = unit_coord
		return result

	var hp_pct = float(unit.current_hp) / float(unit.max_hp)
	var active_template = unit.active_template_id

	if active_template == &"AGGRESSIVE_ASSAULT":
		# Branch 1: If current_hp / max_hp < 0.15 -> Action: Fallback_To_Cover.
		if hp_pct < 0.15:
			unit.template_parameters["fallback_lock_until_tick"] = current_tick + 15
			unit.template_parameters["locked_action_type"] = ActionType.FALLBACK_TO_COVER
			result["action_type"] = ActionType.FALLBACK_TO_COVER
			result["target_coord"] = unit_coord
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Aggressive Assault: Falling back to cover due to low HP."))
		# Branch 2: If enemy in melee range -> Action: Melee_Attack.
		elif melee_targets.size() > 0:
			if not on_cooldown:
				result["action_type"] = ActionType.MELEE_ATTACK
				result["target_coord"] = melee_targets[0]["coord"]
				result["target_id"] = melee_targets[0]["unit"].unit_id
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))
			else:
				result["action_type"] = ActionType.HOLD_ENGAGEMENT
				result["target_coord"] = unit_coord
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, holding engagement (on cooldown)."))
		# Branch 3 (NEW): Ranged check before advancing
		else:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			if r_eval.success:
				if not on_cooldown:
					result["action_type"] = ActionType.RANGED_ATTACK
					result["target_coord"] = r_eval.target.coord
					result["target_id"] = r_eval.target.unit.unit_id
					result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
				else:
					result["action_type"] = ActionType.HOLD_ENGAGEMENT
					result["target_coord"] = unit_coord
					result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, holding engagement (on cooldown)."))
			else:
				result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
				result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "No immediate threat, advancing to objective."))

	elif active_template == &"CAUTIOUS_OVERWATCH":
		# Branch 1: If current_hp / max_hp < 0.40 -> Action: Fallback_To_Cover.
		if hp_pct < 0.40:
			unit.template_parameters["fallback_lock_until_tick"] = current_tick + 15
			unit.template_parameters["locked_action_type"] = ActionType.FALLBACK_TO_COVER
			result["action_type"] = ActionType.FALLBACK_TO_COVER
			result["target_coord"] = unit_coord
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Cautious Overwatch: Falling back to cover due to low HP."))
		# Branch 2: If enemy in ranged threat envelope -> Action: Ranged_Trade_From_Cover (RANGED_ATTACK)
		elif true:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			if r_eval.success:
				if not on_cooldown:
					result["action_type"] = ActionType.RANGED_ATTACK
					result["target_coord"] = r_eval.target.coord
					result["target_id"] = r_eval.target.unit.unit_id
					result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
				else:
					result["action_type"] = ActionType.HOLD_ENGAGEMENT
					result["target_coord"] = unit_coord
					result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, holding engagement (on cooldown)."))
			else:
				result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
				result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "No immediate threat, advancing to objective."))

	elif active_template == &"POINT_GUARD":
		# Branch 1: If enemy in melee/threat range -> Action: Attack_Target.
		if melee_targets.size() > 0:
			if not on_cooldown:
				result["action_type"] = ActionType.MELEE_ATTACK
				result["target_coord"] = melee_targets[0]["coord"]
				result["target_id"] = melee_targets[0]["unit"].unit_id
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))
			else:
				result["action_type"] = ActionType.HOLD_ENGAGEMENT
				result["target_coord"] = unit_coord
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, holding engagement (on cooldown)."))
		elif true:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			if r_eval.success:
				if not on_cooldown:
					result["action_type"] = ActionType.RANGED_ATTACK
					result["target_coord"] = r_eval.target.coord
					result["target_id"] = r_eval.target.unit.unit_id
					result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
				else:
					result["action_type"] = ActionType.HOLD_ENGAGEMENT
					result["target_coord"] = unit_coord
					result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, holding engagement (on cooldown)."))
			else:
				result["action_type"] = ActionType.HOLD_ANCHOR
				result["target_coord"] = unit.template_parameters.get("anchor_coord", unit_coord)
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "No immediate threat, holding anchor tile."))

	if result["action_type"] == ActionType.ADVANCE_TO_OBJECTIVE or result["action_type"] == ActionType.FALLBACK_TO_COVER:
		if result["target_coord"] == NULL_COORD:
			result["action_type"] = ActionType.HOLD_ANCHOR
			result["target_coord"] = unit_coord
			unit.template_parameters["fallback_lock_until_tick"] = current_tick + 10
			unit.template_parameters["locked_action_type"] = ActionType.HOLD_ANCHOR
			result["path_array"] = []
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "No valid target coordinate found, holding anchor."))
			return result

		var recalc_cooldown = unit.template_parameters.get("path_recalculation_cooldown", 0)
		if recalc_cooldown > 0:
			unit.template_parameters["path_recalculation_cooldown"] = recalc_cooldown - 1
			result["path_array"] = unit.template_parameters.get("current_path", [])
		else:
			var current_path = unit.template_parameters.get("current_path", [])
			if current_path.is_empty():
				var new_path = pf.calculate_path(matrix, unit_coord, result["target_coord"], unit)
				if new_path.size() > 0:
					result["telemetry_entries"].append(telemetry_logger.log_pathfinding(current_tick, unit.unit_id, "Path generated (Length: " + str(new_path.size()) + ")"))
					unit.template_parameters["current_path"] = new_path
					result["path_array"] = new_path
				else:
					result["telemetry_entries"].append(telemetry_logger.log_pathfinding(current_tick, unit.unit_id, "Path failed (Unreachable)"))
					result["action_type"] = ActionType.HOLD_ANCHOR
					result["target_coord"] = unit_coord
					unit.template_parameters["fallback_lock_until_tick"] = current_tick + 10
					unit.template_parameters["locked_action_type"] = ActionType.HOLD_ANCHOR
					unit.template_parameters["current_path"] = []
					result["path_array"] = []
			else:
				result["path_array"] = current_path

	return result
