import sys

def main():
    with open('scripts/core/main_game_manager.gd', 'r') as f:
        content = f.read()

    search = """func commit_simulation_state(start_snapshot: TickSnapshotData, final_snapshot: TickSnapshotData) -> void:
	# 1. Update existing unit states and transforms
	var dead_units: Array = []
	for unit_id in master_units.keys():
		var unit = master_units[unit_id]

		# Update core stats
		if final_snapshot.unit_hp_states.has(unit_id):
			unit.current_hp = final_snapshot.unit_hp_states[unit_id]
		if final_snapshot.unit_stress_states.has(unit_id):
			unit.current_stress = final_snapshot.unit_stress_states[unit_id]

		# Update template parameters
		if final_snapshot.unit_template_states.has(unit_id):
			unit.template_parameters = final_snapshot.unit_template_states[unit_id].duplicate(true)

		# Check for death
		if unit.current_hp <= 0:
			dead_units.append(unit_id)
		else:
			# Update position and matrix occupancy
			if final_snapshot.unit_transform_states.has(unit_id) and start_snapshot.unit_transform_states.has(unit_id):
				var new_coord = final_snapshot.unit_transform_states[unit_id]
				var old_coord = start_snapshot.unit_transform_states[unit_id]

				if old_coord != new_coord:
					var old_tile = master_matrix.get_tile(old_coord)
					if old_tile and old_tile.occupying_unit_id == unit_id:
						old_tile.occupying_unit_id = -1

				var new_tile = master_matrix.get_tile(new_coord)
				if new_tile:
					new_tile.occupying_unit_id = unit_id

	# 2. Cleanup dead units
	for unit_id in dead_units:
		if final_snapshot.unit_transform_states.has(unit_id):
			var end_coord = final_snapshot.unit_transform_states[unit_id]
			var tile = master_matrix.get_tile(end_coord)
			if tile and tile.occupying_unit_id == unit_id:
				tile.occupying_unit_id = -1
		elif start_snapshot.unit_transform_states.has(unit_id):
			var start_coord = start_snapshot.unit_transform_states[unit_id]
			var tile = master_matrix.get_tile(start_coord)
			if tile and tile.occupying_unit_id == unit_id:
				tile.occupying_unit_id = -1
		master_units.erase(unit_id)

	# 3. Update prop states"""

    replace = """func commit_simulation_state(start_snapshot: TickSnapshotData, final_snapshot: TickSnapshotData) -> void:
	# 1. Update existing unit states and transforms
	for unit_id in master_units.keys():
		var unit = master_units[unit_id]

		# Update core stats
		if final_snapshot.unit_hp_states.has(unit_id):
			unit.current_hp = final_snapshot.unit_hp_states[unit_id]
		if final_snapshot.unit_stress_states.has(unit_id):
			unit.current_stress = final_snapshot.unit_stress_states[unit_id]

		# Update template parameters
		if final_snapshot.unit_template_states.has(unit_id):
			unit.template_parameters = final_snapshot.unit_template_states[unit_id].duplicate(true)

		# Check for death
		if unit.current_hp <= 0:
			if final_snapshot.unit_transform_states.has(unit_id):
				var end_coord = final_snapshot.unit_transform_states[unit_id]
				var tile = master_matrix.get_tile(end_coord)
				if tile and tile.occupying_unit_id == unit_id:
					tile.occupying_unit_id = -1
			elif start_snapshot.unit_transform_states.has(unit_id):
				var start_coord = start_snapshot.unit_transform_states[unit_id]
				var tile = master_matrix.get_tile(start_coord)
				if tile and tile.occupying_unit_id == unit_id:
					tile.occupying_unit_id = -1
			master_units.erase(unit_id)
		else:
			# Update position and matrix occupancy
			if final_snapshot.unit_transform_states.has(unit_id) and start_snapshot.unit_transform_states.has(unit_id):
				var new_coord = final_snapshot.unit_transform_states[unit_id]
				var old_coord = start_snapshot.unit_transform_states[unit_id]

				if old_coord != new_coord:
					var old_tile = master_matrix.get_tile(old_coord)
					if old_tile and old_tile.occupying_unit_id == unit_id:
						old_tile.occupying_unit_id = -1

				var new_tile = master_matrix.get_tile(new_coord)
				if new_tile:
					new_tile.occupying_unit_id = unit_id

	# 2. Update prop states"""

    if search in content:
        content = content.replace(search, replace)
        with open('scripts/core/main_game_manager.gd', 'w') as f:
            f.write(content)
        print("Patched MainGameManager.")
    else:
        print("Could not find search block in MainGameManager.")

if __name__ == "__main__":
    main()
