import sys

def main():
    with open('scripts/ai/ai_tree_evaluator.gd', 'r') as f:
        content = f.read()

    search = """			# Melee Check
			var dx = enemy_coord.x - unit_coord.x
			var dy = enemy_coord.y - unit_coord.y
			if abs(dx) + abs(dy) == 1 and unit_coord.z == enemy_coord.z:
				melee_targets.append({ "unit": enemy, "coord": enemy_coord })"""

    replace = """			# Melee Check
			var pf = PathfindingEngine.new()
			if pf._is_cardinal_adjacent(unit_coord, enemy_coord, matrix):
				melee_targets.append({ "unit": enemy, "coord": enemy_coord })"""

    if search in content:
        content = content.replace(search, replace)
        with open('scripts/ai/ai_tree_evaluator.gd', 'w') as f:
            f.write(content)
        print("Patched AITreeEvaluator.")
    else:
        print("Could not find search block in AITreeEvaluator.")

if __name__ == "__main__":
    main()
