import re

with open('./scripts/ui/ui_manager.gd', 'r') as f:
    content = f.read()

# Add active_directives dict
content = re.sub(
    r'var active_waypoints: Dictionary = {} # unit_id -> Vector3i',
    r'var active_waypoints: Dictionary = {} # unit_id -> Vector3i\nvar active_directives: Dictionary = {} # unit_id -> Dictionary',
    content
)

# Clear active_directives in _on_phase_changed
content = re.sub(
    r'active_waypoints\.clear\(\)',
    r'active_waypoints.clear()\n\t\tactive_directives.clear()',
    content
)

# Populate plan.unit_directives in _on_simulate_pressed
content = re.sub(
    r'plan\.unit_objectives = active_waypoints\.duplicate\(\)',
    r'plan.unit_objectives = active_waypoints.duplicate()\n\tplan.unit_directives = active_directives.duplicate()',
    content
)

# Wait, UIManager needs to check master_matrix. But UIManager doesn't have a direct reference to it.
# Wait, MainGameManager receives master_matrix in initialize_match.
# We can just check `master_units` since it has all the units. Actually, do we need master_matrix to find the unit on that tile, or can we just iterate `master_units` and check if their position matches?
# But wait, UIManager doesn't track current positions of units except through `current_replay_buffer`. Wait, in planning phase, `current_replay_buffer` might not be updated for the new turn yet? No, `commit_simulation_state` updates `master_units` directly, but it doesn't update positions inside `master_units`, it updates `unit.template_parameters["last_coord_x"]` etc. Wait, let's check `commit_simulation_state`.
