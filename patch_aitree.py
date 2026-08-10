import sys

def main():
    with open('scripts/ai/ai_tree_evaluator.gd', 'r') as f:
        content = f.read()

    search = """	var unit_coord = all_unit_coords.get(unit.unit_id, Vector3i.ZERO)
	if not all_unit_coords.has(unit.unit_id):
		# If the unit is not on the board, return NONE
		return result"""

    replace = """	var unit_coord = all_unit_coords.get(unit.unit_id, Vector3i.ZERO)
	if not all_unit_coords.has(unit.unit_id):
		# If the unit is not on the board, return NONE
		return result

	if unit.template_parameters.get("attack_cooldown", 0) > 0:
		return result"""

    if search in content:
        content = content.replace(search, replace)
        with open('scripts/ai/ai_tree_evaluator.gd', 'w') as f:
            f.write(content)
        print("Patched AITreeEvaluator.")
    else:
        print("Could not find search block in AITreeEvaluator.")

if __name__ == "__main__":
    main()
