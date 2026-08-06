extends Node
## Central event hub for the game.
## Used to decouple cross-screen logic.

signal boot_completed

# --- System Events ---
signal game_quit_requested

# --- Viewport / Camera Events ---
signal camera_z_level_changed(active_z: int)

# --- Combat / WEGO Phase Engine ---
signal wego_phase_started(phase_name: String)
signal combat_started
signal combat_ended

# --- Unit Entity Events ---
signal unit_health_changed(unit: Node, current_health: int, max_health: int, amount: int)
signal unit_died(unit: Node)
signal unit_action_finished(unit: Node)

# Enemy deployment
signal enemy_deployment_requested(enemy_roster: Array, deployment_zones: Array[Vector2i])
