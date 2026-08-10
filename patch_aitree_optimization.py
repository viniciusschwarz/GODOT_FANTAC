import sys

def main():
    with open('scripts/ai/ai_tree_evaluator.gd', 'r') as f:
        content = f.read()

    search = """	var all_alive_enemies: Array[Dictionary] = []

	for enemy_id in all_units:
		var enemy: UnitDataResource = all_units[enemy_id] # [EXTERNAL DATA ACCESS]
		if enemy.faction_id != unit.faction_id and enemy.current_hp > 0:
			if not all_unit_coords.has(enemy.unit_id):
				continue

			var enemy_coord = all_unit_coords[enemy.unit_id]

			# Melee Check
			var pf = PathfindingEngine.new()
			if pf._is_cardinal_adjacent(unit_coord, enemy_coord, matrix):
				melee_targets.append({ "unit": enemy, "coord": enemy_coord })"""

    replace = """	var all_alive_enemies: Array[Dictionary] = []
	var pf = PathfindingEngine.new()

	for enemy_id in all_units:
		var enemy: UnitDataResource = all_units[enemy_id] # [EXTERNAL DATA ACCESS]
		if enemy.faction_id != unit.faction_id and enemy.current_hp > 0:
			if not all_unit_coords.has(enemy.unit_id):
				continue

			var enemy_coord = all_unit_coords[enemy.unit_id]

			# Melee Check
			if pf._is_cardinal_adjacent(unit_coord, enemy_coord, matrix):
				melee_targets.append({ "unit": enemy, "coord": enemy_coord })"""

    if search in content:
        content = content.replace(search, replace)
        with open('scripts/ai/ai_tree_evaluator.gd', 'w') as f:
            f.write(content)
        print("Patched AITreeEvaluator for optimization.")
    else:
        print("Could not find block for AITreeEvaluator optimization.")

if __name__ == "__main__":
    main()
