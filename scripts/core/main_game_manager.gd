class_name MainGameManager extends Node

var current_phase: EventBus.Phase = EventBus.Phase.INITIALIZATION
var current_turn: int = 1

var master_matrix: BattlefieldMatrix
var master_units: Dictionary = {}
var current_replay_buffer: TurnReplayBufferResource = null

func _ready() -> void:
	EventBus.plan_submitted.connect(execute_simulation)
	EventBus.playback_completed.connect(_on_playback_completed)

func initialize_match(matrix: BattlefieldMatrix, units: Dictionary) -> void:
	master_matrix = matrix
	master_units = units
	current_turn = 1

	EventBus.match_started.emit(master_matrix, master_units)

	var dummy_buffer = TurnReplayBufferResource.new()
	dummy_buffer.turn_number = 0

	var snapshot = TickSnapshotData.new()
	snapshot.micro_tick_index = 0

	# Populate initial unit states
	for unit_id in master_units.keys():
		var unit = master_units[unit_id]
		snapshot.unit_hp_states[unit_id] = unit.current_hp
		# We need to find the unit's position in the matrix to populate transform_states

	for coord in master_matrix._grid.keys():
		# [EXTERNAL DATA ACCESS] Reading from the matrix
		var tile = master_matrix.get_tile(coord)
		if tile.occupying_unit_id != -1 and master_units.has(tile.occupying_unit_id):
			# [EXTERNAL DATA ACCESS] Populating the snapshot buffer
			snapshot.unit_transform_states[tile.occupying_unit_id] = coord

	# Populate initial prop states
	for prop_id in master_matrix._props.keys():
		var prop = master_matrix.get_prop(prop_id)
		snapshot.prop_states[prop_id] = prop.current_degradation_state

	dummy_buffer.tick_snapshots.append(snapshot)

	EventBus.grid_initialized.emit(master_matrix)
	EventBus.turn_simulation_completed.emit(dummy_buffer)

	enter_planning_phase()

func enter_planning_phase() -> void:
	current_phase = EventBus.Phase.PLANNING
	var plan = TurnPlanResource.new()
	plan.turn_number = current_turn
	EventBus.phase_changed.emit(EventBus.Phase.PLANNING)

func execute_simulation(plan: TurnPlanResource) -> void:
	if current_phase != EventBus.Phase.PLANNING:
		return

	current_phase = EventBus.Phase.SIMULATING
	EventBus.phase_changed.emit(EventBus.Phase.SIMULATING)

	var sim_server = SimulationServer.new()
	var replay_buffer = sim_server.run_turn_simulation(plan, master_matrix, master_units)

	enter_playback_phase(replay_buffer)

func enter_playback_phase(buffer: TurnReplayBufferResource) -> void:
	current_phase = EventBus.Phase.PLAYBACK
	current_replay_buffer = buffer
	EventBus.turn_simulation_completed.emit(buffer)
	EventBus.phase_changed.emit(EventBus.Phase.PLAYBACK)

func _on_playback_completed() -> void:
	if current_phase == EventBus.Phase.PLAYBACK and current_replay_buffer != null:
		advance_to_next_turn(current_replay_buffer)

func debug_print_turn_summary(buffer: TurnReplayBufferResource) -> void:
	print("=== SIMULATION TURN %d COMPLETED ===" % current_turn)

	if buffer.tick_snapshots.is_empty():
		return

	var start_state: TickSnapshotData = buffer.tick_snapshots[0]
	var final_state: TickSnapshotData = buffer.tick_snapshots[buffer.tick_snapshots.size() - 1]

	for unit_id in master_units.keys():
		var unit: UnitDataResource = master_units[unit_id]

		var start_pos = start_state.unit_transform_states.get(unit_id, Vector3i.ZERO)
		var end_pos = final_state.unit_transform_states.get(unit_id, Vector3i.ZERO)

		var start_hp = start_state.unit_hp_states.get(unit_id, unit.current_hp)
		var end_hp = final_state.unit_hp_states.get(unit_id, unit.current_hp)

		var start_stress = start_state.unit_stress_states.get(unit_id, unit.current_stress)
		var end_stress = final_state.unit_stress_states.get(unit_id, unit.current_stress)

		var template_name = str(unit.active_template_id)

		var pos_str = "(%d, %d, %d) -> (%d, %d, %d)" % [start_pos.x, start_pos.y, start_pos.z, end_pos.x, end_pos.y, end_pos.z]

		print("[ID:%d] %s (%s) | Pos: %s | HP: %s -> %s | Stress: %s -> %s" % [
			unit_id,
			unit.unit_name,
			template_name,
			pos_str,
			str(start_hp),
			str(end_hp),
			str(start_stress),
			str(end_stress)
		])

	# Output telemetry events
	print("--- TELEMETRY EVENTS ---")
	for tick_data in buffer.tick_snapshots:
		for event in tick_data.telemetry_events:
			if event.has("msg"):
				print(event.msg)
	print("------------------------")

func commit_simulation_state(start_snapshot: TickSnapshotData, final_snapshot: TickSnapshotData) -> void:
	# 1. Update existing unit states and transforms
	var dead_units: Array = []
	for unit_id in master_units.keys():
		var unit = master_units[unit_id]

		# Update core stats
		if final_snapshot.unit_hp_states.has(unit_id):
			unit.current_hp = final_snapshot.unit_hp_states[unit_id]
		if final_snapshot.unit_stress_states.has(unit_id):
			unit.current_stress = final_snapshot.unit_stress_states[unit_id]

		# Update template parameters
		if final_snapshot.unit_template_states.has(unit_id):
			unit.template_parameters = final_snapshot.unit_template_states[unit_id].duplicate(true)

		# Check for death
		if unit.current_hp <= 0:
			dead_units.append(unit_id)
		else:
			# Update position and matrix occupancy
			if final_snapshot.unit_transform_states.has(unit_id) and start_snapshot.unit_transform_states.has(unit_id):
				var new_coord = final_snapshot.unit_transform_states[unit_id]
				var old_coord = start_snapshot.unit_transform_states[unit_id]

				if old_coord != new_coord:
					var old_tile = master_matrix.get_tile(old_coord)
					if old_tile and old_tile.occupying_unit_id == unit_id:
						old_tile.occupying_unit_id = -1

				var new_tile = master_matrix.get_tile(new_coord)
				if new_tile:
					new_tile.occupying_unit_id = unit_id

	# 2. Cleanup dead units
	for unit_id in dead_units:
		if start_snapshot.unit_transform_states.has(unit_id):
			var start_coord = start_snapshot.unit_transform_states[unit_id]
			var tile = master_matrix.get_tile(start_coord)
			if tile and tile.occupying_unit_id == unit_id:
				tile.occupying_unit_id = -1
		master_units.erase(unit_id)

	# 3. Update prop states
	for prop_id in final_snapshot.prop_states.keys():
		var prop = master_matrix.get_prop(prop_id)
		if prop:
			prop.current_degradation_state = final_snapshot.prop_states[prop_id]

	print("[STATE_COMMIT] master_units and master_matrix have been overwritten with end of Tick 99 state.")

func advance_to_next_turn(buffer: TurnReplayBufferResource) -> void:
	debug_print_turn_summary(buffer)
	var start_state = buffer.tick_snapshots[0]
	var final_state = buffer.tick_snapshots[99]

	commit_simulation_state(start_state, final_state)

	# Win Condition Check at (6, 11, 1)
	var win_tile = master_matrix.get_tile(Vector3i(6, 11, 1))
	if win_tile:
		var occ_id = win_tile.occupying_unit_id
		if occ_id != -1 and master_units.has(occ_id):
			var occ_unit = master_units[occ_id]
			if occ_unit.faction_id == 0 and occ_unit.current_hp > 0:
				current_phase = EventBus.Phase.MATCH_END
				EventBus.match_ended.emit(true)
				return

	current_turn += 1
	if current_turn > 5:
		current_phase = EventBus.Phase.MATCH_END
		EventBus.match_ended.emit(false)
	else:
		enter_planning_phase()
