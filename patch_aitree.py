with open("scripts/ai/ai_tree_evaluator.gd", "r") as f:
    content = f.read()

# Replace method signature
old_sig = "func evaluate_unit_behavior(unit: UnitDataResource, matrix: BattlefieldMatrix, all_units: Dictionary, current_tick: int) -> Dictionary:"
new_sig = "func evaluate_unit_behavior(unit: UnitDataResource, matrix: BattlefieldMatrix, all_units: Dictionary, current_tick: int, telemetry_logger: TurnTelemetryLogger) -> Dictionary:"
content = content.replace(old_sig, new_sig)

# Replace TurnTelemetryLogger with telemetry_logger
content = content.replace("TurnTelemetryLogger.", "telemetry_logger.")

# Inject evaluate_ranged_attack helper
helper = """
func evaluate_ranged_attack(unit: UnitDataResource, matrix: BattlefieldMatrix, ranged_targets: Array) -> Dictionary:
	if ranged_targets.size() > 0:
		return { "success": true, "target": ranged_targets[0] }
	return { "success": false }
"""
content = content.replace("func evaluate_unit_behavior", helper + "\nfunc evaluate_unit_behavior")

# Update AGGRESSIVE_ASSAULT
old_aggressive = """		# Branch 2: If enemy in melee range -> Action: Melee_Attack.
		elif melee_targets.size() > 0:
			result["action_type"] = ActionType.MELEE_ATTACK
			result["target_coord"] = melee_targets[0]["coord"]
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))
		# Default: Action: Advance_Shortest_Path_To_Objective.
		else:"""

new_aggressive = """		# Branch 2: If enemy in melee range -> Action: Melee_Attack.
		elif melee_targets.size() > 0:
			result["action_type"] = ActionType.MELEE_ATTACK
			result["target_coord"] = melee_targets[0]["coord"]
			result["target_id"] = melee_targets[0]["unit"].unit_id
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))
		# Branch 3 (NEW): Ranged check before advancing
		elif evaluate_ranged_attack(unit, matrix, ranged_targets).success:
			var r_eval = evaluate_ranged_attack(unit, matrix, ranged_targets)
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = r_eval.target.coord
			result["target_id"] = r_eval.target.unit.unit_id
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
		# Default: Action: Advance_Shortest_Path_To_Objective.
		else:"""
content = content.replace(old_aggressive, new_aggressive)

# Update CAUTIOUS_OVERWATCH
old_cautious = """		# Branch 2: If enemy in ranged threat envelope -> Action: Ranged_Trade_From_Cover (RANGED_ATTACK)
		elif ranged_targets.size() > 0:
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = ranged_targets[0]["coord"]
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
		# Default: Action: Advance_Via_Cover_Tiles (ADVANCE_TO_OBJECTIVE)
		else:"""

new_cautious = """		# Branch 2: If enemy in ranged threat envelope -> Action: Ranged_Trade_From_Cover (RANGED_ATTACK)
		elif evaluate_ranged_attack(unit, matrix, ranged_targets).success:
			var r_eval = evaluate_ranged_attack(unit, matrix, ranged_targets)
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = r_eval.target.coord
			result["target_id"] = r_eval.target.unit.unit_id
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
		# Default: Action: Advance_Via_Cover_Tiles (ADVANCE_TO_OBJECTIVE)
		else:"""
content = content.replace(old_cautious, new_cautious)

# Update POINT_GUARD
old_point = """		# Branch 1: If enemy in melee/threat range -> Action: Attack_Target.
		if melee_targets.size() > 0:
			result["action_type"] = ActionType.MELEE_ATTACK
			result["target_coord"] = melee_targets[0]["coord"]
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))
		elif ranged_targets.size() > 0:
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = ranged_targets[0]["coord"]
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
		# Default: Action: Hold_Anchor_Tile."""

new_point = """		# Branch 1: If enemy in melee/threat range -> Action: Attack_Target.
		if melee_targets.size() > 0:
			result["action_type"] = ActionType.MELEE_ATTACK
			result["target_coord"] = melee_targets[0]["coord"]
			result["target_id"] = melee_targets[0]["unit"].unit_id
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))
		elif evaluate_ranged_attack(unit, matrix, ranged_targets).success:
			var r_eval = evaluate_ranged_attack(unit, matrix, ranged_targets)
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = r_eval.target.coord
			result["target_id"] = r_eval.target.unit.unit_id
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
		# Default: Action: Hold_Anchor_Tile."""
content = content.replace(old_point, new_point)

with open("scripts/ai/ai_tree_evaluator.gd", "w") as f:
    f.write(content)
