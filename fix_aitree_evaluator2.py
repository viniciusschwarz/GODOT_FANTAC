with open("scripts/ai/ai_tree_evaluator.gd", "r") as f:
    content = f.read()

# Fix the AGGRESSIVE_ASSAULT which got broken during earlier replace
import re

content = re.sub(
    r"""		# Branch 3 \(NEW\): Ranged check before advancing\n		# Default: Action: Advance_Shortest_Path_To_Objective\.\n		else:""",
    """		# Branch 3 (NEW): Ranged check before advancing
		else:
			var r_eval = evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)
			if r_eval.success:
				result["action_type"] = ActionType.RANGED_ATTACK
				result["target_coord"] = r_eval.target.coord
				result["target_id"] = r_eval.target.unit.unit_id
				result["telemetry_entries"].append(telemetry_logger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))
			else:""",
    content
)

# And fix the bad indentation in CAUTIOUS_OVERWATCH and POINT_GUARD
content = content.replace("""			else:
			result["action_type"]""", """			else:
				result["action_type"]""")

content = content.replace("""			else:
				result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
			result["target_coord"]""", """			else:
				result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE
				result["target_coord"]""")

content = content.replace("""			else:
				result["action_type"] = ActionType.HOLD_ANCHOR
			result["target_coord"]""", """			else:
				result["action_type"] = ActionType.HOLD_ANCHOR
				result["target_coord"]""")

content = content.replace("""				result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
			result["telemetry_entries"]""", """				result["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)
				result["telemetry_entries"]""")

content = content.replace("""				result["target_coord"] = unit.template_parameters.get("anchor_coord", unit_coord)
			result["telemetry_entries"]""", """				result["target_coord"] = unit.template_parameters.get("anchor_coord", unit_coord)
				result["telemetry_entries"]""")

with open("scripts/ai/ai_tree_evaluator.gd", "w") as f:
    f.write(content)
