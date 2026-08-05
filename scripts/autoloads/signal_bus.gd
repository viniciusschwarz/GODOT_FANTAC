extends Node
## Central event hub for the game.
## Used to decouple cross-screen logic.

signal boot_completed

# --- Combat / WEGO Phase Engine ---
signal wego_phase_started(phase_name: String)
signal combat_started
signal combat_ended

# --- Unit Entity Events ---
signal unit_health_changed(unit: Node, current_health: int, max_health: int)
signal unit_died(unit: Node)
signal unit_action_finished(unit: Node)
