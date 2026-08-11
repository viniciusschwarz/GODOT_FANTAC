class_name InitiativeReservationServer extends RefCounted

func resolve_tile_reservation(tile: TileSpatialNodeResource, requesting_unit: UnitDataResource, units_map: Dictionary, micro_tick: int) -> Dictionary:
	var req_initiative: float = float(requesting_unit.base_initiative) - requesting_unit.encumbrance_penalty + (float(requesting_unit.unit_id) * 0.001)

	if tile.occupying_unit_id != -1 and tile.occupying_unit_id != requesting_unit.unit_id:
		# Explicitly reject movement into tiles occupied by stationary units
		return {"success": false, "log_msg": ""}

	if tile.reserved_unit_id == -1:
		# Unreserved, simply claim it
		_claim_tile(tile, requesting_unit, micro_tick)
		return {"success": true, "log_msg": ""}

	# Tile is currently reserved by someone
	var current_reserver_id: int = tile.reserved_unit_id
	var reservation_start: int = tile.reservation_micro_tick
	var reservation_end: int = reservation_start + tile.reservation_duration_ticks

	if micro_tick >= reservation_end:
		# Past reservation is expired. Clear it and claim it.
		_clear_reservation(tile)
		_claim_tile(tile, requesting_unit, micro_tick)
		return {"success": true, "log_msg": ""}

	# Overlapping windows (collision)
	if current_reserver_id in units_map:
		var reserver: UnitDataResource = units_map[current_reserver_id]
		var res_initiative: float = float(reserver.base_initiative) - reserver.encumbrance_penalty + (float(reserver.unit_id) * 0.001)

		if req_initiative > res_initiative:
			# Requesting unit out-prioritizes the current reserver
			reserver.recalculation_cooldown_ticks = 5
			reserver.is_path_blocked = true

			_claim_tile(tile, requesting_unit, micro_tick)
			return {"success": true, "log_msg": "Collision at tile " + str(tile.grid_position) + ": Unit " + str(requesting_unit.unit_id) + " (Init: " + str(req_initiative) + ") won over Unit " + str(reserver.unit_id) + " (Init: " + str(res_initiative) + "). Loser penalized +5 Ticks."}
		else:
			# Requesting unit loses the tie-breaker
			return {"success": false, "log_msg": "Collision at tile " + str(tile.grid_position) + ": Unit " + str(reserver.unit_id) + " (Init: " + str(res_initiative) + ") won over Unit " + str(requesting_unit.unit_id) + " (Init: " + str(req_initiative) + "). Loser penalized +5 Ticks."}
	else:
		# Edge case: reserver unit is not found in the units map. Clear and claim.
		_clear_reservation(tile)
		_claim_tile(tile, requesting_unit, micro_tick)
		return {"success": true, "log_msg": ""}


func _claim_tile(tile: TileSpatialNodeResource, requesting_unit: UnitDataResource, micro_tick: int) -> void:
	tile.reserved_unit_id = requesting_unit.unit_id
	tile.reservation_micro_tick = micro_tick
	tile.reservation_duration_ticks = requesting_unit.movement_speed_ticks_per_tile

func _clear_reservation(tile: TileSpatialNodeResource) -> void:
	tile.reserved_unit_id = -1
	tile.reservation_micro_tick = -1
	tile.reservation_duration_ticks = 0
