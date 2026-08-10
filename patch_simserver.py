import re

with open('./scripts/sim/simulation_server.gd', 'r') as f:
    content = f.read()

# We need to inject the logic to check `plan.unit_directives` before AI evaluation.
# Let's write a function to simulate what the AI should output for an ATTACK directive.
# Actually, the user asked: "During the SimulationServer's Execution Phase (Step B), before the AITreeEvaluator runs its standard logic, it must check unit_directives for an override. If an override exists, it forces that intent and skips standard AI evaluation."
# What intent does it force? It should force an attack.
# Wait, if we force an attack, do we force MELEE_ATTACK or RANGED_ATTACK or ADVANCE_TO_OBJECTIVE?
# The prompt: "If an override exists, it forces that intent and skips standard AI evaluation."
# And: "The player clicked the UI to order Unit 1 to attack Unit 3, but the simulation log shows [AI] Unit 1 evaluated ADVANCE_TO_OBJECTIVE (Target: -1). The player's explicit override intent is not reaching the TurnPlanResource."
# We should probably evaluate range:
# If in melee range, MELEE_ATTACK.
# If in ranged range, RANGED_ATTACK.
# If neither, ADVANCE_TO_OBJECTIVE to the target coord.
# Let's do that.

# Wait, `plan` might be null in `run_turn_simulation`.
patch_step_b = """		# STEP B: Evaluate unit AI tree conditions and interrupts
		for unit_id in working_units:
			var unit: UnitDataResource = working_units[unit_id]
			if unit.current_hp <= 0:
				continue

			var eval_result = {}
			var has_override = false

			if plan and plan.unit_directives.has(unit_id):
				var directive = plan.unit_directives[unit_id]
				if directive.type == "ATTACK":
					has_override = true
					var target_id = directive.target_id
					var target_coord = directive.target_coord

					if working_units.has(target_id):
						var target_unit = working_units[target_id]
						var unit_coord = Vector3i(unit.template_parameters.get("last_coord_x", 0), unit.template_parameters.get("last_coord_y", 0), unit.template_parameters.get("last_coord_z", 0))
						var t_coord = Vector3i(target_unit.template_parameters.get("last_coord_x", 0), target_unit.template_parameters.get("last_coord_y", 0), target_unit.template_parameters.get("last_coord_z", 0))

						var dx = t_coord.x - unit_coord.x
						var dy = t_coord.y - unit_coord.y
						var dist = abs(t_coord.x - unit_coord.x) + abs(t_coord.y - unit_coord.y) + abs(t_coord.z - unit_coord.z)

						if abs(dx) + abs(dy) == 1 and unit_coord.z == t_coord.z:
							eval_result["action_type"] = AITreeEvaluator.ActionType.MELEE_ATTACK
							eval_result["target_id"] = target_id
							eval_result["target_coord"] = t_coord
						elif dist >= unit.attack_range_min and dist <= unit.attack_range_max:
							eval_result["action_type"] = AITreeEvaluator.ActionType.RANGED_ATTACK
							eval_result["target_id"] = target_id
							eval_result["target_coord"] = t_coord
						else:
							eval_result["action_type"] = AITreeEvaluator.ActionType.ADVANCE_TO_OBJECTIVE
							eval_result["target_coord"] = t_coord

							var recalc_cooldown = unit.template_parameters.get("path_recalculation_cooldown", 0)
							if recalc_cooldown > 0:
								unit.template_parameters["path_recalculation_cooldown"] = recalc_cooldown - 1
								eval_result["path_array"] = unit.template_parameters.get("current_path", [])
							else:
								var current_path = unit.template_parameters.get("current_path", [])
								if current_path.is_empty():
									var pf = PathfindingEngine.new()
									var new_path = pf.calculate_path(working_matrix, unit_coord, t_coord, unit)
									unit.template_parameters["current_path"] = new_path
									eval_result["path_array"] = new_path
								else:
									eval_result["path_array"] = current_path
					else:
						# Target is dead, clear override
						has_override = false

			if not has_override:
				eval_result = ai_evaluator.evaluate_unit_behavior(unit, working_matrix, working_units, current_tick)

			if eval_result.has("action_type"):"""

content = re.sub(
    r'		# STEP B: Evaluate unit AI tree conditions and interrupts\n		for unit_id in working_units:\n			var unit: UnitDataResource = working_units\[unit_id\]\n			if unit.current_hp <= 0:\n				continue\n\n			var eval_result = ai_evaluator.evaluate_unit_behavior\(unit, working_matrix, working_units, current_tick\)\n			if eval_result.has\("action_type"\):',
    patch_step_b,
    content
)

with open('./scripts/sim/simulation_server.gd', 'w') as f:
    f.write(content)
