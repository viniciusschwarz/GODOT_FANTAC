extends Node

# Global Phase Enum
enum Phase { INITIALIZATION, PLANNING, SIMULATING, PLAYBACK, MATCH_END }

# Phase Signals
signal phase_changed(new_phase: Phase)
signal turn_simulation_completed(replay_buffer: TurnReplayBufferResource)

# Selection & Interaction Signals
signal unit_selected(unit_id: int)
signal unit_hovered(unit_id: int)
signal tile_selected(grid_coord: Vector3i)
signal tile_right_clicked(selected_unit_id: int, grid_coord: Vector3i)

# Simulation & Environment Signals
signal navmesh_dirty(tile_coord: Vector3i)
signal prop_state_changed(prop_id: int, new_state: int)

# Playback & UI Signals
signal scrubber_tick_changed(target_tick: int)
signal playback_state_changed(is_playing: bool, speed_multiplier: float)

# Match Signals
signal match_ended(allied_won: bool)
signal match_started(matrix: BattlefieldMatrix, units_cache: Dictionary)

# Turn Flow Signals
signal plan_submitted(plan: TurnPlanResource)
signal playback_completed()
signal grid_initialized(matrix: BattlefieldMatrix)
