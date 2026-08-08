class_name CombatEngine extends RefCounted

func process_projectile_step(projectile: Dictionary, matrix: BattlefieldMatrix, units_map: Dictionary) -> Dictionary:
	var pos = projectile.current_pos_3d
	var vel = projectile.velocity

	var new_pos = pos + vel
	projectile.current_pos_3d = new_pos

	var grid_x = floor(new_pos.x)
	var grid_y = floor(new_pos.y)
	var grid_z = floor(new_pos.z / 3.0)
	var grid_coord = Vector3i(grid_x, grid_y, grid_z)

	# Check Bounds
	if grid_coord.x < 0 or grid_coord.x >= 12 or grid_coord.y < 0 or grid_coord.y >= 12:
		return { "status": &"OUT_OF_BOUNDS" }

	var tile = matrix.get_tile(grid_coord)
	if tile == null:
		return { "status": &"OUT_OF_BOUNDS" }

	var tile_base_z = grid_coord.z * 3.0

	# Check Terrain/Props
	if tile.prop_id != -1 or tile.cover_type != TileSpatialNodeResource.CoverType.NONE:
		var obstruction_offset = 0.0

		# Prop height takes priority if it exists
		if tile.prop_id != -1:
			var prop = matrix.get_prop(tile.prop_id)
			if prop:
				if prop.current_degradation_state == MultiStagePropResource.DegradationState.INTACT:
					obstruction_offset = 2.5
				else: # RUBBLE
					obstruction_offset = 0.5
		# Otherwise, check cover height
		else:
			if tile.cover_type == TileSpatialNodeResource.CoverType.LOW_RAILING:
				obstruction_offset = 1.0
			elif tile.cover_type == TileSpatialNodeResource.CoverType.WINDOW_FRAME:
				obstruction_offset = 1.5
			elif tile.cover_type == TileSpatialNodeResource.CoverType.SOLID_PARAPET:
				obstruction_offset = 1.8

		var obstruction_height = tile_base_z + obstruction_offset
		if new_pos.z < obstruction_height:
			return { "status": &"INTERCEPTED_TERRAIN" }

	# Check Units
	var target_unit_id = tile.occupying_unit_id
	if target_unit_id != -1 and target_unit_id != projectile.source_id:
		if units_map.has(target_unit_id):
			var unit_base_z = tile.grid_position.z * 3.0
			var proj_z = new_pos.z
			if proj_z >= unit_base_z and proj_z <= (unit_base_z + 1.8):
				return {
					"status": &"HIT_UNIT",
					"target_id": target_unit_id,
					"damage": projectile.damage,
					"hardness": projectile.hardness
				}

	return { "status": &"FLYING", "projectile": projectile }

func resolve_melee_attack(
	attacker: UnitDataResource,
	defender: UnitDataResource,
	attacker_coord: Vector3i,
	defender_coord: Vector3i,
	current_tick: int
) -> Dictionary:

	var dx = abs(attacker_coord.x - defender_coord.x)
	var dy = abs(attacker_coord.y - defender_coord.y)

	if (dx + dy != 1) or (attacker_coord.z != defender_coord.z):
		return { "status": &"MELEE_INVALID_RANGE" }

	return {
		"status": &"MELEE_SCHEDULED",
		"attacker_id": attacker.unit_id,
		"defender_id": defender.unit_id,
		"target_coord": defender_coord,
		"damage": attacker.weapon_damage,
		"hardness": attacker.weapon_hardness_rating,
		"application_tick": current_tick + attacker.damage_application_tick_offset
	}
