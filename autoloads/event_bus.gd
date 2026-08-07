extends Node

## THE EVENT BUS
## The global communication hub for cross-domain decoupling.
## External systems (UI, Audio, VFX) will subscribe to these signals.
## Simulation components will emit them.

# ==========================================
# COMBAT & SIMULATION SIGNALS
# ==========================================
signal unit_spawned(unit_node: Node)
signal unit_took_damage(unit_id: StringName, amount: int, current_health: int)
signal unit_died(unit_id: StringName)
signal combat_ended(winning_team: StringName)

# ==========================================
# WEGO TURN STATE SIGNALS
# ==========================================
## Phases could be: "planning", "commit", "execution", "halt"
signal turn_phase_changed(new_phase: StringName)
signal execution_tick(delta: float)

# ==========================================
# UI & INPUT SIGNALS
# ==========================================
## Fired when the player drags an AI node in the Tactics Board
signal ui_tactics_node_dropped(payload: Dictionary, target_info: Dictionary)
## Fired when the player selects a unit in the world
signal ui_unit_selected(unit_id: StringName)

# ==========================================
# CAMERA & RENDERING SIGNALS
# ==========================================
## Fired when the camera changes its focal Z-level for 2.5D visual slicing.
signal camera_z_level_changed(new_z_level: int)
