class_name SimulationServer extends RefCounted

var telemetry_logger: TurnTelemetryLogger = TurnTelemetryLogger.new()

var combat_engine: CombatEngine = CombatEngine.new()
var reservation_server: InitiativeReservationServer = InitiativeReservationServer.new()
var pathfinding: PathfindingEngine = PathfindingEngine.new()
var ai_evaluator: AITreeEvaluator = AITreeEvaluator.new()

var next_proj_id: int = 1

func run_turn_simulation(plan: TurnPlanResource, initial_matrix: BattlefieldMatrix, initial_units: Dictionary) -> TurnReplayBufferResource:
	var replay_buffer = TurnReplayBufferResource.new()
	if plan:
		replay_buffer.turn_number = plan.turn_number
	else:
		replay_buffer.turn_number = 1
	replay_buffer.tick_snapshots = [] as Array[TickSnapshotData]

	var working_matrix = initial_matrix.duplicate_grid()
	var working_units: Dictionary = {}
	for unit_id in initial_units:
		var unit = initial_units[unit_id]
		var cloned_unit = unit.duplicate_data()
		working_units[cloned_unit.unit_id] = cloned_unit

		# Apply plan templates
		if plan and plan.unit_templates.has(cloned_unit.unit_id):
			var template = plan.unit_templates[cloned_unit.unit_id]
			if template != null:
				cloned_unit.active_template_id = template.template_id

		# Objective injection (PROMPT 8.2)
		if plan and plan.unit_objectives.has(cloned_unit.unit_id):
			cloned_unit.template_parameters["objective_coord"] = plan.unit_objectives[cloned_unit.unit_id] # [EXTERNAL DATA ACCESS]

		# Reset path and cooldowns
		cloned_unit.template_parameters["current_path"] = []
		cloned_unit.template_parameters["path_recalculation_cooldown"] = 0
		# Always reset movement cooldown at start of the turn
		cloned_unit.template_parameters["unit_movement_cooldown"] = 0 # [EXTERNAL DATA ACCESS]

	telemetry_logger.reset_turn_cache()
	var active_projectiles: Array[Dictionary] = []
	var unit_intents: Dictionary = {}
	var scheduled_melee_events: Array[Dictionary] = []

	# WeGo 100-Micro-Tick Loop
	for tick in range(100):
		var telemetry_events: Array[Dictionary] = []
		var current_tick = tick

		# STEP A: Process environment and active projectile positions
		var proj_idx = active_projectiles.size() - 1
		while proj_idx >= 0:
			var proj = active_projectiles[proj_idx]
			var result = combat_engine.process_projectile_step(proj, working_matrix, working_units)

			_append_telemetry(telemetry_events, telemetry_logger.log_projectile_result(current_tick, proj.id, proj.current_pos_3d, str(result.status)))

			if result.status == &"HIT_UNIT":
				var target_unit = working_units[result.target_id]
				var dmg = result.damage
				target_unit.current_hp -= dmg
				target_unit.current_stress += (dmg * 0.5)
				check_morale_fracture(target_unit, current_tick, telemetry_events, unit_intents, scheduled_melee_events)
				active_projectiles.remove_at(proj_idx)
			elif result.status == &"INTERCEPTED_TERRAIN":
				active_projectiles.remove_at(proj_idx)
			elif result.status == &"OUT_OF_BOUNDS":
				active_projectiles.remove_at(proj_idx)
			# If FLYING, leave it in the array

			proj_idx -= 1

		# Clean up dead units
		_cleanup_dead_units(working_units, working_matrix, telemetry_events, current_tick, unit_intents, scheduled_melee_events)

		# STEP B: Evaluate unit AI tree conditions and interrupts
		for unit_id in working_units:
			var unit: UnitDataResource = working_units[unit_id]
			if unit.current_hp <= 0:
				continue

			var attack_cooldown = unit.template_parameters.get("attack_cooldown", 0)
			if attack_cooldown > 0:
				unit.template_parameters["attack_cooldown"] = attack_cooldown - 1

			var directive = {}
			if plan and plan.unit_directives.has(unit_id):
				directive = plan.unit_directives[unit_id]

			var eval_result = ai_evaluator.evaluate_unit_behavior(unit, working_matrix, working_units, current_tick, telemetry_logger, directive)
			if eval_result.has("telemetry_entries"):
				for t_entry in eval_result.telemetry_entries:
					_append_telemetry(telemetry_events, t_entry)

			if eval_result.has("action_type"):
				var intent = {
					"action_type": eval_result.action_type,
					"target_id": eval_result.get("target_id", -1),
					"target_coord": eval_result.get("target_coord", Vector3i()),
					"path_array": eval_result.get("path_array", [])
				}
				if not unit_intents.has(unit_id) or unit_intents[unit_id].action_type != intent.action_type:
					var action_name = AITreeEvaluator.ActionType.keys()[AITreeEvaluator.ActionType.values().find(intent.action_type)]
					_append_telemetry(telemetry_events, telemetry_logger.log_ai_decision(current_tick, unit_id, action_name, intent.target_id, intent.target_coord))

				# If it's a ranged attack, we spawn a projectile when the tick offsets match
				if intent.action_type == AITreeEvaluator.ActionType.RANGED_ATTACK:
					var intent_start_tick = current_tick # Wait, if it just decided to attack, it starts now.
					# But wait, AITreeEvaluator evaluates every tick. We only want to start an attack once and not repeatedly every tick.
					# In standard WeGo, we would store the intent_start_tick in unit parameters.
					# For the scope of this simulation loop as requested:
					# "Check if current_tick == (intent_start_tick + unit.damage_application_tick_offset)."

					# Let's say intent_start_tick is stored in unit_intents if it doesn't have one yet.
					if not unit_intents.has(unit_id) or unit_intents[unit_id].action_type != AITreeEvaluator.ActionType.RANGED_ATTACK:
						intent["intent_start_tick"] = current_tick
						unit_intents[unit_id] = intent
					else:
						intent["intent_start_tick"] = unit_intents[unit_id].intent_start_tick
						unit_intents[unit_id] = intent

					if current_tick == (intent.intent_start_tick + unit.damage_application_tick_offset):
						unit.template_parameters["attack_cooldown"] = 20
						# Fire projectile
						var tile_size = 1.0
						var height_per_level = 3.0

						var ux = unit.template_parameters.get("last_coord_x", 0)
						var uy = unit.template_parameters.get("last_coord_y", 0)
						var uz = unit.template_parameters.get("last_coord_z", 0)

						var unit_3d_pos = Vector3(ux * tile_size, uy * tile_size, (uz * height_per_level) + 1.2)
						var target_3d_pos = Vector3.ZERO
						if intent.has("target_id") and working_units.has(intent.target_id):
							var target_unit = working_units[intent.target_id]
							# Fetch current active floating-point 3D transform via current micro-tick coordinates
							var tx = target_unit.template_parameters.get("last_coord_x", intent.target_coord.x)
							var ty = target_unit.template_parameters.get("last_coord_y", intent.target_coord.y)
							var tz = target_unit.template_parameters.get("last_coord_z", intent.target_coord.z)
							target_3d_pos = Vector3(tx * tile_size, ty * tile_size, (tz * height_per_level) + 1.2)
						else:
							var target = intent.target_coord
							target_3d_pos = Vector3(target.x * tile_size, target.y * tile_size, (target.z * height_per_level) + 1.2)

						var direction: Vector3 = (target_3d_pos - unit_3d_pos).normalized()
						var speed = 0.5 # assumed projectile speed

						# Apply 1-voxel offset to avoid hitting own tile's cover/boundary
						unit_3d_pos += direction * 1.0

						active_projectiles.append({
							"id": next_proj_id,
							"source_id": unit.unit_id,
							"current_pos_3d": unit_3d_pos,
							"velocity": direction * speed,
							"damage": unit.weapon_damage,
							"hardness": unit.weapon_hardness_rating
						})
						var los_result = working_matrix.calculate_3d_line_of_sight(Vector3i(unit.template_parameters.get("last_coord_x", 0), unit.template_parameters.get("last_coord_y", 0), unit.template_parameters.get("last_coord_z", 0)), intent.target_coord)
						_append_telemetry(telemetry_events, telemetry_logger.log_ranged_fire(current_tick, unit.unit_id, intent.target_id, los_result.get("has_los", false)))
						next_proj_id += 1
				else:
					unit_intents[unit_id] = intent

		# STEP C & D: Movement Execution & Reservation Check
		for unit_id in unit_intents:
			var intent = unit_intents[unit_id]
			if intent.action_type == AITreeEvaluator.ActionType.ADVANCE_TO_OBJECTIVE or intent.action_type == AITreeEvaluator.ActionType.FALLBACK_TO_COVER:
				var unit = working_units[unit_id]

				# Check and decrement unit_movement_cooldown
				var move_cooldown = unit.template_parameters.get("unit_movement_cooldown", 0)
				if move_cooldown > 0:
					unit.template_parameters["unit_movement_cooldown"] = move_cooldown - 1
					continue # Skip movement this tick

				var path_array = unit.template_parameters.get("current_path", [])
				if path_array.size() > 0:
					var next_coord = path_array[0]
					var tile = working_matrix.get_tile(next_coord)
					if tile:
						# Note: signature in initiative_reservation_server.gd is:
						# resolve_tile_reservation(tile, requesting_unit, units_map, micro_tick) -> int
						var granted = reservation_server.resolve_tile_reservation(tile, unit, working_units, current_tick) == 1

						if granted:
							# GRANTED
							# Pop path
							path_array.pop_front()
							unit.template_parameters["current_path"] = path_array

							var old_coord_x = unit.template_parameters.get("last_coord_x", -1)
							var old_coord_y = unit.template_parameters.get("last_coord_y", -1)
							var old_coord_z = unit.template_parameters.get("last_coord_z", -1)

							if old_coord_x != -1:
								var old_tile = working_matrix.get_tile(Vector3i(old_coord_x, old_coord_y, old_coord_z))
								if old_tile and old_tile.occupying_unit_id == unit_id:
									old_tile.occupying_unit_id = -1

							tile.occupying_unit_id = unit_id
							unit.template_parameters["last_coord_x"] = next_coord.x
							unit.template_parameters["last_coord_y"] = next_coord.y
							unit.template_parameters["last_coord_z"] = next_coord.z

							# Reset cooldown
							unit.template_parameters["unit_movement_cooldown"] = unit.movement_speed_ticks_per_tile

							# Guardrail: If path is now empty, explicitly clear the array to prevent stale path loops
							if path_array.is_empty():
								unit.template_parameters["current_path"].clear()

							_append_telemetry(telemetry_events, telemetry_logger.log_movement(current_tick, unit_id, next_coord, unit.movement_speed_ticks_per_tile, unit.movement_speed_ticks_per_tile))
						else:
							# DENIED (blocked)
							var occupant = tile.occupying_unit_id if tile.occupying_unit_id != -1 else tile.reserved_unit_id
							_append_telemetry(telemetry_events, telemetry_logger.log_rejection(current_tick, unit_id, next_coord, occupant))
							unit.template_parameters["current_path"] = []
							unit.template_parameters["path_recalculation_cooldown"] = 5
							# Also set move cooldown so it doesn't spam reservations
							unit.template_parameters["unit_movement_cooldown"] = 1


		# STEP E: Resolve combat hits, damage application, and morale/order fracture checks
		for unit_id in unit_intents:
			var intent = unit_intents[unit_id]
			if intent.action_type == AITreeEvaluator.ActionType.MELEE_ATTACK:
				var attacker = working_units[unit_id]
				var defender_id = intent.target_id
				if working_units.has(defender_id):
					var defender = working_units[defender_id]
					var attacker_coord = Vector3i(attacker.template_parameters.get("last_coord_x", 0), attacker.template_parameters.get("last_coord_y", 0), attacker.template_parameters.get("last_coord_z", 0))
					var defender_coord = Vector3i(defender.template_parameters.get("last_coord_x", 0), defender.template_parameters.get("last_coord_y", 0), defender.template_parameters.get("last_coord_z", 0))

					var melee_result = combat_engine.resolve_melee_attack(attacker, defender, attacker_coord, defender_coord, current_tick)
					if melee_result.status == &"MELEE_SCHEDULED":
						attacker.template_parameters["attack_cooldown"] = 20
						scheduled_melee_events.append(melee_result)
						# Consume the intent so it doesn't trigger multiple times
						intent.action_type = AITreeEvaluator.ActionType.NONE

		# Process scheduled melee damages that occur this tick
		var melee_idx = scheduled_melee_events.size() - 1
		while melee_idx >= 0:
			var event = scheduled_melee_events[melee_idx]
			if current_tick >= event.application_tick:
				if working_units.has(event.defender_id):
					var defender = working_units[event.defender_id]
					var dmg = event.damage
					defender.current_hp -= dmg
					defender.current_stress += (dmg * 0.5)
					_append_telemetry(telemetry_events, telemetry_logger.log_combat(event.attacker_id, event.defender_id, current_tick, dmg, defender.current_hp, true))
					check_morale_fracture(defender, current_tick, telemetry_events, unit_intents, scheduled_melee_events)
				scheduled_melee_events.remove_at(melee_idx)
			melee_idx -= 1

		_cleanup_dead_units(working_units, working_matrix, telemetry_events, current_tick, unit_intents, scheduled_melee_events)

		# STEP F: Capture tick snapshot
		var snapshot = TickSnapshotData.new()
		snapshot.micro_tick_index = current_tick

		for unit_id in working_units:
			var unit = working_units[unit_id]
			var cx = unit.template_parameters.get("last_coord_x", 0)
			var cy = unit.template_parameters.get("last_coord_y", 0)
			var cz = unit.template_parameters.get("last_coord_z", 0)
			snapshot.unit_transform_states[unit_id] = Vector3i(cx, cy, cz)
			snapshot.unit_hp_states[unit_id] = unit.current_hp
			snapshot.unit_stress_states[unit_id] = unit.current_stress
			snapshot.unit_template_states[unit_id] = unit.template_parameters.duplicate(true)
			# Animation state could be derived, setting default 0 for now
			snapshot.unit_animation_states[unit_id] = 0

		for prop_id in working_matrix._props:
			snapshot.prop_states[prop_id] = working_matrix.get_prop(prop_id).current_degradation_state

		snapshot.active_projectiles = active_projectiles.duplicate(true)
		snapshot.telemetry_events = telemetry_events.duplicate(true)

		replay_buffer.tick_snapshots.append(snapshot)

	# Emit the result
	EventBus.turn_simulation_completed.emit(replay_buffer)
	return replay_buffer

func check_morale_fracture(unit: UnitDataResource, current_tick: int, telemetry_events: Array, unit_intents: Dictionary, scheduled_melee_events: Array):
	var max_allowed_stress = unit.bravery_rating * unit.loyalty_rating
	if unit.current_stress >= max_allowed_stress and not unit.is_order_fractured:
		unit.is_order_fractured = true
		unit.active_template_id = &"UNCONTROLLED_FALLBACK"

		# Purge active path reservations (intent)
		unit_intents.erase(unit.unit_id)

		# Purge scheduled attacks
		var melee_idx = scheduled_melee_events.size() - 1
		while melee_idx >= 0:
			if scheduled_melee_events[melee_idx].attacker_id == unit.unit_id:
				scheduled_melee_events.remove_at(melee_idx)
			melee_idx -= 1

		_append_telemetry(telemetry_events, {"tick": current_tick, "msg": "[Tick " + str(current_tick) + "] Order Fractured! Falling back in panic."})

func _cleanup_dead_units(working_units: Dictionary, working_matrix: BattlefieldMatrix, telemetry_events: Array, current_tick: int, unit_intents: Dictionary, scheduled_melee_events: Array):
	var dead_units: Array = []
	for unit_id in working_units:
		if working_units[unit_id].current_hp <= 0:
			dead_units.append(unit_id)

	for dead_id in dead_units:
		var dead_unit = working_units[dead_id]

		# Only process death logic once on the tick the unit dies
		if not dead_unit.template_parameters.get("is_dead", false):
			# Find units within 3 tiles and add stress
			var dead_x = dead_unit.template_parameters.get("last_coord_x", 0)
			var dead_y = dead_unit.template_parameters.get("last_coord_y", 0)

			for other_id in working_units:
				if other_id != dead_id:
					var other = working_units[other_id]
					if other.faction_id == dead_unit.faction_id:
						var ox = other.template_parameters.get("last_coord_x", 0)
						var oy = other.template_parameters.get("last_coord_y", 0)
						if abs(dead_x - ox) + abs(dead_y - oy) <= 3: # 3 cardinal tiles
							other.current_stress += 15.0
							check_morale_fracture(other, current_tick, telemetry_events, unit_intents, scheduled_melee_events)

			# Clear occupation
			var cz = dead_unit.template_parameters.get("last_coord_z", 0)
			var tile = working_matrix.get_tile(Vector3i(dead_x, dead_y, cz))
			if tile and tile.occupying_unit_id == dead_id:
				tile.occupying_unit_id = -1

			# Mark dead without erasing, ensuring snapshot retention across ticks
			_append_telemetry(telemetry_events, {"tick": current_tick, "msg": "Unit " + str(dead_id) + " died."})
			dead_unit.template_parameters["is_dead"] = true

		unit_intents.erase(dead_id)

func _append_telemetry(events: Array, event: Dictionary) -> void:
	if not event.is_empty():
		events.append(event)
