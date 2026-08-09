extends Node

# Phase Signals
signal phase_changed(new_phase: int) # 0=Planning, 1=Simulating, 2=Playback
signal turn_simulation_completed(replay_buffer: TurnReplayBufferResource)

# Selection & Interaction Signals
signal unit_selected(unit_id: int)
signal unit_hovered(unit_id: int)
signal tile_selected(grid_coord: Vector3i)

# Simulation & Environment Signals
signal navmesh_dirty(tile_coord: Vector3i)
signal prop_state_changed(prop_id: int, new_state: int)

# Playback & UI Signals
signal scrubber_tick_changed(target_tick: int)
signal playback_state_changed(is_playing: bool, speed_multiplier: float)

# Match Signals
signal match_ended(allied_won: bool)
