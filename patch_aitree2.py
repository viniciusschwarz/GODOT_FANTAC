import re

with open('./scripts/ai/ai_tree_evaluator.gd', 'r') as f:
    content = f.read()

# Make result use `telemetry_entries` array
content = re.sub(
    r'"telemetry_entry": {}',
    r'"telemetry_entries": []',
    content
)

# And change old `telemetry_entry` assignments
content = re.sub(
    r'result\["telemetry_entry"\] = { "tick": current_tick, "msg": "Aggressive Assault: Falling back to cover" }',
    r'result["telemetry_entries"].append(TurnTelemetryLogger.log_ai_condition(current_tick, unit.unit_id, "Aggressive Assault: Falling back to cover due to low HP."))',
    content
)

content = re.sub(
    r'result\["telemetry_entry"\] = { "tick": current_tick, "msg": "Cautious Overwatch: Falling back to cover" }',
    r'result["telemetry_entries"].append(TurnTelemetryLogger.log_ai_condition(current_tick, unit.unit_id, "Cautious Overwatch: Falling back to cover due to low HP."))',
    content
)

# Add AI conditions for other branches
# Wait, let's inject AI condition logs into the branches.

def replace_block(text, search, replace):
    if search in text:
        return text.replace(search, replace)
    return text

content = replace_block(content,
    'result["action_type"] = ActionType.MELEE_ATTACK\n\t\t\tresult["target_coord"] = melee_targets[0]["coord"]',
    'result["action_type"] = ActionType.MELEE_ATTACK\n\t\t\tresult["target_coord"] = melee_targets[0]["coord"]\n\t\t\tresult["telemetry_entries"].append(TurnTelemetryLogger.log_ai_condition(current_tick, unit.unit_id, "Enemy in melee range, engaging in melee."))'
)

content = replace_block(content,
    'result["action_type"] = ActionType.RANGED_ATTACK\n\t\t\tresult["target_coord"] = ranged_targets[0]["coord"]',
    'result["action_type"] = ActionType.RANGED_ATTACK\n\t\t\tresult["target_coord"] = ranged_targets[0]["coord"]\n\t\t\tresult["telemetry_entries"].append(TurnTelemetryLogger.log_ai_condition(current_tick, unit.unit_id, "Enemy in ranged threat envelope, engaging from cover."))'
)

content = replace_block(content,
    'result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE\n\t\t\tresult["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)',
    'result["action_type"] = ActionType.ADVANCE_TO_OBJECTIVE\n\t\t\tresult["target_coord"] = unit.template_parameters.get("objective_coord", closest_visible_enemy_coord)\n\t\t\tresult["telemetry_entries"].append(TurnTelemetryLogger.log_ai_condition(current_tick, unit.unit_id, "No immediate threat, advancing to objective."))'
)

content = replace_block(content,
    'result["action_type"] = ActionType.HOLD_ANCHOR\n\t\t\tresult["target_coord"] = unit.template_parameters.get("anchor_coord", unit_coord)',
    'result["action_type"] = ActionType.HOLD_ANCHOR\n\t\t\tresult["target_coord"] = unit.template_parameters.get("anchor_coord", unit_coord)\n\t\t\tresult["telemetry_entries"].append(TurnTelemetryLogger.log_ai_condition(current_tick, unit.unit_id, "No immediate threat, holding anchor tile."))'
)

# And add PATHFINDING telemetry
content = replace_block(content,
    'var new_path = pf.calculate_path(matrix, unit_coord, result["target_coord"], unit)\n\t\t\t\tunit.template_parameters["current_path"] = new_path\n\t\t\t\tresult["path_array"] = new_path',
    'var new_path = pf.calculate_path(matrix, unit_coord, result["target_coord"], unit)\n\t\t\t\tif new_path.size() > 0:\n\t\t\t\t\tresult["telemetry_entries"].append(TurnTelemetryLogger.log_pathfinding(current_tick, unit.unit_id, "Path generated (Length: " + str(new_path.size()) + ")"))\n\t\t\t\telse:\n\t\t\t\t\tresult["telemetry_entries"].append(TurnTelemetryLogger.log_pathfinding(current_tick, unit.unit_id, "Path failed (Unreachable)"))\n\t\t\t\tunit.template_parameters["current_path"] = new_path\n\t\t\t\tresult["path_array"] = new_path'
)


with open('./scripts/ai/ai_tree_evaluator.gd', 'w') as f:
    f.write(content)
