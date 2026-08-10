import sys

def main():
    with open('scripts/core/battlefield_matrix.gd', 'r') as f:
        content = f.read()

    search = """	if (from_tile.cardinal_traversal_mask & direction_bitmask) == 0:
		return false

	# Check opposite mask on the destination tile? (Usually masks are reciprocal, but strictly, the requirement says "Verifies cardinal_traversal_mask permits passage", usually checking `from_tile` is enough, but checking `to_tile`'s incoming mask could be needed. Let's just check `from_tile` for now based on standard implementations, or both for safety)
	var opposite_bitmask: int = 0
	if dy == -1: opposite_bitmask = 2 # S
	elif dy == 1: opposite_bitmask = 1 # N
	elif dx == 1: opposite_bitmask = 8 # W
	elif dx == -1: opposite_bitmask = 4 # E

	if (to_tile.cardinal_traversal_mask & opposite_bitmask) == 0:
		return false"""

    replace = """	# Only check standard cardinal traversal masks if we are moving on the same Z level.
	# Z-level transitions rely purely on vertical_connector_type validation.
	if dz == 0:
		if (from_tile.cardinal_traversal_mask & direction_bitmask) == 0:
			return false

		var opposite_bitmask: int = 0
		if dy == -1: opposite_bitmask = 2 # S
		elif dy == 1: opposite_bitmask = 1 # N
		elif dx == 1: opposite_bitmask = 8 # W
		elif dx == -1: opposite_bitmask = 4 # E

		if (to_tile.cardinal_traversal_mask & opposite_bitmask) == 0:
			return false"""

    if search in content:
        content = content.replace(search, replace)
        with open('scripts/core/battlefield_matrix.gd', 'w') as f:
            f.write(content)
        print("Patched BattlefieldMatrix traversal mask logic.")
    else:
        print("Could not find traversal mask logic.")

if __name__ == "__main__":
    main()
