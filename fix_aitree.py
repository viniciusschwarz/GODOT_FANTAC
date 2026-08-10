with open("scripts/ai/ai_tree_evaluator.gd", "r") as f:
    content = f.read()

# Replace the method for evaluate_ranged_attack
import re

old_ranged = r"func evaluate_ranged_attack\(unit: UnitDataResource, matrix: BattlefieldMatrix, ranged_targets: Array\) -> Dictionary:.*?return \{ \"success\": false \}"
new_ranged = """func evaluate_ranged_attack(unit: UnitDataResource, unit_coord: Vector3i, matrix: BattlefieldMatrix, ranged_targets: Array) -> Dictionary:
	for target in ranged_targets:
		var los_result = matrix.calculate_3d_line_of_sight(unit_coord, target.coord)
		if los_result.get("has_los", false):
			return { "success": true, "target": target }
	return { "success": false }"""
content = re.sub(old_ranged, new_ranged, content, flags=re.DOTALL)

# Now fix the branch evaluations where evaluate_ranged_attack is called twice
def replacer(match):
    return """		elif true:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			if r_eval.success:
				result["action_type"] = ActionType.RANGED_ATTACK
				result["target_coord"] = r_eval.target.coord
				result["target_id"] = r_eval.target.unit.unit_id
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
			else:"""

content = re.sub(r"		elif evaluate_ranged_attack\(unit, (unit_coord, )?matrix, ranged_targets\)\.success:\n.*?result\[\"telemetry_entries\"\].*?\n		else:", replacer, content, flags=re.DOTALL)

with open("scripts/ai/ai_tree_evaluator.gd", "w") as f:
    f.write(content)
