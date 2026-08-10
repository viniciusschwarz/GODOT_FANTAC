class_name TurnTelemetryLogger extends RefCounted

var _last_logged_event_per_unit: Dictionary = {}

func reset_turn_cache() -> void:
	_last_logged_event_per_unit.clear()

func _deduplicate(unit_id: Variant, category: String, tick: int, signature: String, full_msg: String) -> Dictionary:
	if not _last_logged_event_per_unit.has(unit_id):
		_last_logged_event_per_unit[unit_id] = {}

	if _last_logged_event_per_unit[unit_id].get(category, "") == signature:
		return {}

	_last_logged_event_per_unit[unit_id][category] = signature
	return { "tick": tick, "msg": full_msg }

func log_ai_decision(tick: int, unit_id: int, action_name: String, target_id: int, target_coord: Vector3i) -> Dictionary:
	var msg = "[Tick %d] [AI] Unit %d evaluated %s (Target: %d at %s)" % [tick, unit_id, action_name, target_id, str(target_coord)]
	var sig = "[AI] evaluated %s (Target: %d at %s)" % [action_name, target_id, str(target_coord)]
	return _deduplicate(unit_id, "ai_decision", tick, sig, msg)

func log_movement(tick: int, unit_id: int, coord: Vector3i, cost_ticks: int, remaining_cooldown: int) -> Dictionary:
	var msg = "[Tick %d] [MOVE] Unit %d stepped to %s (Cost: %d Ticks, Remaining Cooldown: %d)" % [tick, unit_id, str(coord), cost_ticks, remaining_cooldown]
	var sig = "[MOVE] stepped to %s (Cost: %d Ticks, Remaining Cooldown: %d)" % [str(coord), cost_ticks, remaining_cooldown]
	return _deduplicate(unit_id, "move", tick, sig, msg)

func log_rejection(tick: int, unit_id: int, coord: Vector3i, occupant_id: int) -> Dictionary:
	var msg = "[Tick %d] [REJECT] Unit %d movement to %s blocked by Unit %d" % [tick, unit_id, str(coord), occupant_id]
	var sig = "[REJECT] movement to %s blocked by Unit %d" % [str(coord), occupant_id]
	return _deduplicate(unit_id, "reject", tick, sig, msg)

func log_ranged_fire(tick: int, unit_id: int, target_id: int, has_los: bool) -> Dictionary:
	var los_str = "PASSED" if has_los else "FAILED"
	var msg = "[Tick %d] [RANGED] Unit %d fired projectile at Target %d (LOS: %s)" % [tick, unit_id, target_id, los_str]
	var sig = "[RANGED] fired projectile at Target %d (LOS: %s)" % [target_id, los_str]
	return _deduplicate(unit_id, "ranged", tick, sig, msg)

func log_projectile_result(tick: int, proj_id: int, pos: Vector3, result: String) -> Dictionary:
	var msg = "[Tick %d] [PROJECTILE] Projectile %d Pos: %s -> Result: %s" % [tick, proj_id, str(pos), result]
	var sig = "[PROJECTILE] Pos: %s -> Result: %s" % [str(pos), result]
	return _deduplicate("proj_" + str(proj_id), "proj", tick, sig, msg)

func log_ui_intent(tick: int, unit_id: int, target_id: int, intent_type: String) -> Dictionary:
	var msg = "[Tick %d] [UI_INTENT] Unit %d received manual override: %s Target %d" % [tick, unit_id, intent_type, target_id]
	var sig = "[UI_INTENT] received manual override: %s Target %d" % [intent_type, target_id]
	return _deduplicate(unit_id, "ui_intent", tick, sig, msg)

func log_pathfinding(tick: int, unit_id: int, result: String) -> Dictionary:
	var msg = "[Tick %d] [PATHFINDING] Unit %d %s" % [tick, unit_id, result]
	var sig = "[PATHFINDING] %s" % [result]
	return _deduplicate(unit_id, "pathfinding", tick, sig, msg)

func log_ai_condition(tick: int, unit_id: int, condition_msg: String) -> Dictionary:
	var msg = "[Tick %d] [AI_CONDITION] Unit %d %s" % [tick, unit_id, condition_msg]
	var sig = "[AI_CONDITION] %s" % [condition_msg]
	return _deduplicate(unit_id, "ai_condition", tick, sig, msg)
