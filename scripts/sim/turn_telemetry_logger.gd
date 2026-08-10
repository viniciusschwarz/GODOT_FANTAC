class_name TurnTelemetryLogger extends RefCounted

static func log_ai_decision(tick: int, unit_id: int, action_name: String, target_id: int, target_coord: Vector3i) -> Dictionary:
	var msg = "[Tick %d] [AI] Unit %d evaluated %s (Target: %d at %s)" % [tick, unit_id, action_name, target_id, str(target_coord)]
	return { "tick": tick, "msg": msg }

static func log_movement(tick: int, unit_id: int, coord: Vector3i, cost_ticks: int, remaining_cooldown: int) -> Dictionary:
	var msg = "[Tick %d] [MOVE] Unit %d stepped to %s (Cost: %d Ticks, Remaining Cooldown: %d)" % [tick, unit_id, str(coord), cost_ticks, remaining_cooldown]
	return { "tick": tick, "msg": msg }

static func log_rejection(tick: int, unit_id: int, coord: Vector3i, occupant_id: int) -> Dictionary:
	var msg = "[Tick %d] [REJECT] Unit %d movement to %s blocked by Unit %d" % [tick, unit_id, str(coord), occupant_id]
	return { "tick": tick, "msg": msg }

static func log_ranged_fire(tick: int, unit_id: int, target_id: int, has_los: bool) -> Dictionary:
	var los_str = "PASSED" if has_los else "FAILED"
	var msg = "[Tick %d] [RANGED] Unit %d fired projectile at Target %d (LOS: %s)" % [tick, unit_id, target_id, los_str]
	return { "tick": tick, "msg": msg }

static func log_projectile_result(tick: int, proj_id: int, pos: Vector3, result: String) -> Dictionary:
	var msg = "[Tick %d] [PROJECTILE] Projectile %d Pos: %s -> Result: %s" % [tick, proj_id, str(pos), result]
	return { "tick": tick, "msg": msg }
