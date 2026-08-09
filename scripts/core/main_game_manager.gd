class_name MainGameManager extends Node

enum Phase { INITIALIZATION, PLANNING, SIMULATING, PLAYBACK, MATCH_END }

var current_phase: Phase = Phase.INITIALIZATION
var current_turn: int = 1

var master_matrix: BattlefieldMatrix
var master_units: Dictionary = {}

func start_match() -> void:
	current_turn = 1
	enter_planning_phase()

func enter_planning_phase() -> void:
	current_phase = Phase.PLANNING
	var plan = TurnPlanResource.new()
	plan.turn_number = current_turn
	EventBus.phase_changed.emit(Phase.PLANNING)

func execute_simulation(plan: TurnPlanResource) -> void:
	if current_phase != Phase.PLANNING:
		return

	current_phase = Phase.SIMULATING
	EventBus.phase_changed.emit(Phase.SIMULATING)

	var sim_server = SimulationServer.new()
	var replay_buffer = sim_server.run_turn_simulation(plan, master_matrix, master_units)

	enter_playback_phase(replay_buffer)

func enter_playback_phase(buffer: TurnReplayBufferResource) -> void:
	current_phase = Phase.PLAYBACK
	EventBus.turn_simulation_completed.emit(buffer)
	EventBus.phase_changed.emit(Phase.PLAYBACK)

func advance_to_next_turn(buffer: TurnReplayBufferResource) -> void:
	var final_state = buffer.tick_snapshots[99]

	var dead_units: Array = []
	for unit_id in master_units:
		if final_state.unit_hp_states.has(unit_id):
			master_units[unit_id].current_hp = final_state.unit_hp_states[unit_id]
		if final_state.unit_stress_states.has(unit_id):
			master_units[unit_id].current_stress = final_state.unit_stress_states[unit_id]

		if master_units[unit_id].current_hp <= 0:
			dead_units.append(unit_id)

	for unit_id in dead_units:
		var dead_unit = master_units[unit_id]
		if final_state.unit_transform_states.has(unit_id):
			var final_coord = final_state.unit_transform_states[unit_id]
			var tile = master_matrix.get_tile(final_coord)
			if tile and tile.occupying_unit_id == unit_id:
				tile.occupying_unit_id = -1
		master_units.erase(unit_id)

	# Win Condition Check at (6, 11, 1)
	var win_tile = master_matrix.get_tile(Vector3i(6, 11, 1))
	if win_tile:
		var occ_id = win_tile.occupying_unit_id
		if occ_id != -1 and master_units.has(occ_id):
			var occ_unit = master_units[occ_id]
			if occ_unit.faction_id == 0 and occ_unit.current_hp > 0:
				current_phase = Phase.MATCH_END
				EventBus.match_ended.emit(true)
				return

	current_turn += 1
	if current_turn > 5:
		current_phase = Phase.MATCH_END
		EventBus.match_ended.emit(false)
	else:
		enter_planning_phase()
