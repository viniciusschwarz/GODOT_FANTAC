import re

with open('./scripts/ui/ui_manager.gd', 'r') as f:
    content = f.read()

# Instead of relying on master_matrix directly, we can iterate over master_units to find if any enemy unit is on the clicked grid_coord.
# Since we update master_units with final_snapshot.unit_template_states (which includes last_coord_x, etc), we can just check those. Wait!
# Actually, the user specifically mentioned:
# "The parent UIManager will listen for this signal, check the master_matrix to see if an enemy is on grid_coord, and compile the attack intent."
# We should give UIManager a reference to master_matrix. Or just use EventBus to ask for it? No, we can add a setter `set_master_matrix` or just pass it in `grid_initialized` signal which is already in EventBus!

# Let's check where UIManager receives EventBus.grid_initialized
# It doesn't right now.
content = re.sub(
    r'EventBus\.tile_right_clicked\.connect\(_on_tile_right_clicked\)',
    r'EventBus.tile_right_clicked.connect(_on_tile_right_clicked)\n\tEventBus.grid_initialized.connect(_on_grid_initialized)',
    content
)

content = re.sub(
    r'var master_units: Dictionary = {}',
    r'var master_units: Dictionary = {}\nvar master_matrix: BattlefieldMatrix = null',
    content
)

func_grid_init = """
func _on_grid_initialized(matrix: BattlefieldMatrix) -> void:
	master_matrix = matrix
"""

content = content + func_grid_init

# Rewrite _on_tile_right_clicked
func_on_tile_right_clicked = """
func _on_tile_right_clicked(unit_id: int, grid_coord: Vector3i) -> void:
	if master_matrix:
		var tile = master_matrix.get_tile(grid_coord)
		if tile and tile.occupying_unit_id != -1:
			var target_id = tile.occupying_unit_id
			if master_units.has(target_id):
				var target_unit = master_units[target_id]
				if target_unit.faction_id != 0: # Assuming 0 is player faction
					# Register ATTACK intent
					active_directives[unit_id] = {
						"type": "ATTACK",
						"target_id": target_id,
						"target_coord": grid_coord
					}
					active_waypoints.erase(unit_id) # Remove any conflicting move waypoint
					return

	# If not clicking an enemy, it's a move waypoint
	active_waypoints[unit_id] = grid_coord
	active_directives.erase(unit_id) # Remove any conflicting attack intent
"""

content = re.sub(
    r'func _on_tile_right_clicked\(unit_id: int, grid_coord: Vector3i\) -> void:\n\tactive_waypoints\[unit_id\] = grid_coord',
    func_on_tile_right_clicked,
    content
)

# And make sure active_directives is declared and handled.
content = re.sub(
    r'var active_waypoints: Dictionary = {} # unit_id -> Vector3i',
    r'var active_waypoints: Dictionary = {} # unit_id -> Vector3i\nvar active_directives: Dictionary = {} # unit_id -> Dictionary',
    content
)

content = re.sub(
    r'active_waypoints\.clear\(\)',
    r'active_waypoints.clear()\n\t\tactive_directives.clear()',
    content
)

content = re.sub(
    r'plan\.unit_objectives = active_waypoints\.duplicate\(\)',
    r'plan.unit_objectives = active_waypoints.duplicate()\n\tplan.unit_directives = active_directives.duplicate()',
    content
)

with open('./scripts/ui/ui_manager.gd', 'w') as f:
    f.write(content)
