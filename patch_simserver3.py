import re

with open('./scripts/sim/simulation_server.gd', 'r') as f:
    content = f.read()

# Modify SimulationServer to append multiple telemetry_entries from AI
# Wait, SimulationServer doesn't even append `eval_result.telemetry_entry` anywhere currently. Let's add it!
content = re.sub(
    r'if not has_override:\n\t\t\t\teval_result = ai_evaluator.evaluate_unit_behavior\(unit, working_matrix, working_units, current_tick\)\n\n\t\t\tif eval_result.has\("action_type"\):',
    r'if not has_override:\n\t\t\t\teval_result = ai_evaluator.evaluate_unit_behavior(unit, working_matrix, working_units, current_tick)\n\t\t\t\tif eval_result.has("telemetry_entries"):\n\t\t\t\t\tfor t_entry in eval_result.telemetry_entries:\n\t\t\t\t\t\ttelemetry_events.append(t_entry)\n\n\t\t\tif eval_result.has("action_type"):',
    content
)

# Wait, `has_override` in SimulationServer also does a pathfinding calculation for ADVANCE_TO_OBJECTIVE!
# Let's add PATHFINDING telemetry for has_override ADVANCE_TO_OBJECTIVE in SimulationServer too.
content = re.sub(
    r'var new_path = pf.calculate_path\(working_matrix, unit_coord, t_coord, unit\)\n\t\t\t\t\t\t\t\t\tunit.template_parameters\["current_path"\] = new_path\n\t\t\t\t\t\t\t\t\teval_result\["path_array"\] = new_path',
    r'var new_path = pf.calculate_path(working_matrix, unit_coord, t_coord, unit)\n\t\t\t\t\t\t\t\t\tif new_path.size() > 0:\n\t\t\t\t\t\t\t\t\t\ttelemetry_events.append(TurnTelemetryLogger.log_pathfinding(current_tick, unit_id, "Path generated (Length: " + str(new_path.size()) + ")"))\n\t\t\t\t\t\t\t\t\telse:\n\t\t\t\t\t\t\t\t\t\ttelemetry_events.append(TurnTelemetryLogger.log_pathfinding(current_tick, unit_id, "Path failed (Unreachable)"))\n\t\t\t\t\t\t\t\t\tunit.template_parameters["current_path"] = new_path\n\t\t\t\t\t\t\t\t\teval_result["path_array"] = new_path',
    content
)

with open('./scripts/sim/simulation_server.gd', 'w') as f:
    f.write(content)
