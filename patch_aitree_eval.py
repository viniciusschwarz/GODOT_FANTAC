import re

with open("scripts/ai/ai_tree_evaluator.gd", "r") as f:
    content = f.read()

# Update evaluate_ranged_attack to actually check LOS
old_helper = """func evaluate_ranged_attack(unit: UnitDataResource, matrix: BattlefieldMatrix, ranged_targets: Array) -> Dictionary:
	if ranged_targets.size() > 0:
		return { "success": true, "target": ranged_targets[0] }
	return { "success": false }"""

new_helper = """func evaluate_ranged_attack(unit: UnitDataResource, unit_coord: Vector3i, matrix: BattlefieldMatrix, ranged_targets: Array) -> Dictionary:
	for target in ranged_targets:
		var los_result = matrix.calculate_3d_line_of_sight(unit_coord, target.coord)
		if los_result.get("has_los", false):
			return { "success": true, "target": target }
	return { "success": false }"""

content = content.replace(old_helper, new_helper)

# Fix references to evaluate_ranged_attack (need to pass unit_coord)
content = content.replace("evaluate_ranged_attack(unit, matrix, ranged_targets)", "evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)")

# Fix the duplicate calls to evaluate_ranged_attack by computing it once
old_aggressive = """		# Branch 3 (NEW): Ranged check before advancing
		elif evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets).success:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			result["action_type"] = ActionType.RANGED_ATTACK
			result["target_coord"] = r_eval.target.coord
			result["target_id"] = r_eval.target.unit.unit_id
			result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))"""

new_aggressive = """		# Branch 3 (NEW): Ranged check before advancing
		elif true:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			if r_eval.success:
				result["action_type"] = ActionType.RANGED_ATTACK
				result["target_coord"] = r_eval.target.coord
				result["target_id"] = r_eval.target.unit.unit_id
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
			else:
				result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
				result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "No immediate threat, advancing to objective."))"""
# We have to be careful with the elif true logic replacing the fallback, let's do it cleaner

content = content.replace(old_aggressive, """		# Branch 3 (NEW): Ranged check before advancing""") # this is messy, let's write a python script that just does regex

with open("scripts/ai/ai_tree_evaluator.gd", "w") as f:
    f.write(content)
