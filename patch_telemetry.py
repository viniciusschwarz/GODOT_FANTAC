import re

with open('./scripts/sim/turn_telemetry_logger.gd', 'r') as f:
    content = f.read()

# Add new functions for UI_INTENT, PATHFINDING, AI_CONDITION
new_funcs = """
static func log_ui_intent(tick: int, unit_id: int, target_id: int, intent_type: String) -> Dictionary:
	var msg = "[Tick %d] [UI_INTENT] Unit %d received manual override: %s Target %d" % [tick, unit_id, intent_type, target_id]
	return { "tick": tick, "msg": msg }

static func log_pathfinding(tick: int, unit_id: int, result: String) -> Dictionary:
	var msg = "[Tick %d] [PATHFINDING] Unit %d %s" % [tick, unit_id, result]
	return { "tick": tick, "msg": msg }

static func log_ai_condition(tick: int, unit_id: int, condition_msg: String) -> Dictionary:
	var msg = "[Tick %d] [AI_CONDITION] Unit %d %s" % [tick, unit_id, condition_msg]
	return { "tick": tick, "msg": msg }
"""

content = content + new_funcs

with open('./scripts/sim/turn_telemetry_logger.gd', 'w') as f:
    f.write(content)
