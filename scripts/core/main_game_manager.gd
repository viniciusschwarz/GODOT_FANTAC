## Oversees global phase transitions and state persistence.
## Triggers simulation headless runs and synchronizes the final snapshot back to the master state.
class_name MainGameManager extends Node

var current_phase: EventBus.Phase = EventBus.Phase.INITIALIZATION
var current_turn: int = 1

## Source of truth for all spatial data.
var master_matrix: BattlefieldMatrix
## Source of truth for all unit attributes mapped by unit_id.
var master_units: Dictionary = {}
var current_replay_buffer: TurnReplayBufferResource = null

func _ready() -> void:
	EventBus.plan_submitted.connect(execute_simulation)
	EventBus.playback_completed.connect(_on_playback_completed)

## Injects master grid and entities into the game loop, generating initial Tick 0 snapshot.
func initialize_match(matrix: BattlefieldMatrix, units: Dictionary) -> void:
	master_matrix = matrix
	master_units = units
	current_turn = 1

	EventBus.match_started.emit(master_matrix, master_units)

	var dummy_buffer = TurnReplayBufferResource.new()
	dummy_buffer.turn_number = 0

	var snapshot = TickSnapshotData.new()
	snapshot.micro_tick_index = 0

	for unit_id in master_units.keys():
		var unit = master_units[unit_id]
		snapshot.unit_hp_states[unit_id] = unit.current_hp

	for coord in master_matrix._grid.keys():
		# [VIEW LAYER SAFETY]: Strictly reading initial spatial positioning without mutation.
		var tile = master_matrix.get_tile(coord)
		if tile.occupying_unit_id != -1 and master_units.has(tile.occupying_unit_id):
			snapshot.unit_transform_states[tile.occupying_unit_id] = coord

	for prop_id in master_matrix._props.keys():
		var prop = master_matrix.get_prop(prop_id)
		snapshot.prop_states[prop_id] = prop.current_degradation_state

	dummy_buffer.tick_snapshots.append(snapshot)

	EventBus.grid_initialized.emit(master_matrix)
	EventBus.turn_simulation_completed.emit(dummy_buffer)

	enter_planning_phase()

## Starts the manual intent planning phase where users assign directives.
func enter_planning_phase() -> void:
	current_phase = EventBus.Phase.PLANNING
	var plan = TurnPlanResource.new()
	plan.turn_number = current_turn
	EventBus.phase_changed.emit(EventBus.Phase.PLANNING)

## Submits player intent for fully headless sandbox resolution.
func execute_simulation(plan: TurnPlanResource) -> void:
	if current_phase != EventBus.Phase.PLANNING:
		return

	current_phase = EventBus.Phase.SIMULATING
	EventBus.phase_changed.emit(EventBus.Phase.SIMULATING)

	var sim_server = SimulationServer.new()
	var replay_buffer = sim_server.run_turn_simulation(plan, master_matrix, master_units)

	enter_playback_phase(replay_buffer)

## Locks view interaction and streams compiled micro-tick snapshots to render logic.
func enter_playback_phase(buffer: TurnReplayBufferResource) -> void:
	current_phase = EventBus.Phase.PLAYBACK
	current_replay_buffer = buffer
	EventBus.turn_simulation_completed.emit(buffer)
	EventBus.phase_changed.emit(EventBus.Phase.PLAYBACK)

## Callback advancing simulation logic once front-end parsing finishes.
func _on_playback_completed() -> void:
	if current_phase == EventBus.Phase.PLAYBACK and current_replay_buffer != null:
		advance_to_next_turn(current_replay_buffer)

## Output telemetry data dump displaying micro-tick logic evaluations.
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

## Applies the final Tick 99 snapshot values back into the master state dictionaries.
func commit_simulation_state(start_snapshot: TickSnapshotData, final_snapshot: TickSnapshotData) -> void:
	# [STATE COMMIT]: Synchronizing core variables and purging stale positional matrix data from dead entities.
	for unit_id in master_units.keys():
		var unit = master_units[unit_id]

		if final_snapshot.unit_hp_states.has(unit_id):
			unit.current_hp = final_snapshot.unit_hp_states[unit_id]
		if final_snapshot.unit_stress_states.has(unit_id):
			unit.current_stress = final_snapshot.unit_stress_states[unit_id]

		if unit.current_hp <= 0:
			var target_coord = final_snapshot.unit_transform_states.get(unit_id, start_snapshot.unit_transform_states.get(unit_id, Vector3i(-1,-1,-1)))
			if target_coord != Vector3i(-1,-1,-1):
				var tile = master_matrix.get_tile(target_coord)
				if tile and tile.occupying_unit_id == unit_id:
					tile.occupying_unit_id = -1

		var old_coord_x = unit.template_parameters.get("last_coord_x", -1)
		var old_coord_y = unit.template_parameters.get("last_coord_y", -1)
		var old_coord_z = unit.template_parameters.get("last_coord_z", -1)
		var old_coord = Vector3i(old_coord_x, old_coord_y, old_coord_z)
		unit.template_parameters["__temp_old_coord"] = old_coord

		if final_snapshot.unit_template_states.has(unit_id):
			unit.template_parameters = final_snapshot.unit_template_states[unit_id].duplicate(true)
			unit.template_parameters["__temp_old_coord"] = old_coord

	var dead_units: Array = []
	for unit_id in master_units.keys():
		if master_units[unit_id].current_hp <= 0:
			dead_units.append(unit_id)

	for unit_id in dead_units:
		master_units.erase(unit_id)

	for unit_id in master_units.keys():
		var unit = master_units[unit_id]
		if unit.current_hp > 0:
			if final_snapshot.unit_transform_states.has(unit_id):
				var new_coord = final_snapshot.unit_transform_states[unit_id]

				var old_coord: Vector3i = unit.template_parameters.get("__temp_old_coord", Vector3i(-1, -1, -1))

				if old_coord.x != -1 and old_coord != new_coord:
					var old_tile = master_matrix.get_tile(old_coord)
					if old_tile and old_tile.occupying_unit_id == unit_id:
						old_tile.occupying_unit_id = -1

				unit.template_parameters.erase("__temp_old_coord")

				unit.template_parameters["last_coord_x"] = new_coord.x
				unit.template_parameters["last_coord_y"] = new_coord.y
				unit.template_parameters["last_coord_z"] = new_coord.z

				var new_tile = master_matrix.get_tile(new_coord)
				if new_tile:
					new_tile.occupying_unit_id = unit_id

	for prop_id in final_snapshot.prop_states.keys():
		var prop = master_matrix.get_prop(prop_id)
		if prop:
			prop.current_degradation_state = final_snapshot.prop_states[prop_id]

	print("[STATE_COMMIT] master_units and master_matrix have been overwritten with end of Tick 99 state.")

## Increments round counter and assesses match end conditions based on final state values.
func advance_to_next_turn(buffer: TurnReplayBufferResource) -> void:
	debug_print_turn_summary(buffer)
	var start_state = buffer.tick_snapshots[0]
	var final_state = buffer.tick_snapshots[99]

	commit_simulation_state(start_state, final_state)

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
