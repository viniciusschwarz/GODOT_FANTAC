extends Node
## Central event hub for the game.
## Used to decouple cross-screen logic.

signal boot_completed

# --- System Events ---
signal game_quit_requested

# --- UI Events ---
signal ui_navigation_requested(panel_name: String)

# --- Flow & Scene Transition Events ---
signal change_scene_requested(scene_id: String)
signal new_campaign_requested
signal continue_campaign_requested
signal mission_accepted(mission: MissionData)

# --- Viewport / Camera Events ---
signal camera_z_level_changed(active_z: int)
signal environment_bounds_changed(bounds: Rect2)

# --- Combat / WEGO Phase Engine ---
signal wego_phase_started(phase_name: String)
signal combat_started
signal combat_ended

# --- Unit Entity Events ---
signal unit_health_changed(unit: Node, current_health: int, max_health: int, amount: int)
signal unit_died(unit: Node)
signal unit_action_finished(unit: Node)
signal unit_cover_bonus_changed(unit: Node, cover_bonus: float)

# Enemy deployment
signal enemy_deployment_requested(enemy_roster: Array, deployment_zones: Array[Vector2i])

# --- Input Events ---
signal camera_pan_input(direction: Vector2)
signal camera_zoom_input(zoom_change: float)
signal camera_z_level_input(z_level_change: int)
signal map_clicked(mouse_pos: Vector2)

# --- Deployment Events ---
signal player_deployment_requested(unit_type: String, grid_pos: Vector2i)
signal player_deployment_confirmed
signal spawn_unit_requested(unit_type: String, grid_pos: Vector2i)
signal unit_spawned(unit: Node)

# --- AI Setup Events ---
signal player_behavior_setup_requested(unit: Node, preset: String)
signal player_behavior_setup_completed

# --- Debug/Visualizer Events ---
signal ai_debug_data_broadcasted(active_units: Array)
