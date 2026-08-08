extends SceneTree

func _init():
    var matrix = load("res://scripts/core/battlefield_matrix.gd").new()
    matrix.initialize_grid(12, 12, 2)
    var tile = matrix.get_tile(Vector3i(0, 0, 0))
    if tile and tile.height_offset_meters == 0.0:
        print("Tile Z0 height OK")
    else:
        print("Tile Z0 height FAIL")

    var tile_z1 = matrix.get_tile(Vector3i(0, 0, 1))
    if tile_z1 and tile_z1.height_offset_meters == 3.0:
        print("Tile Z1 height OK")
    else:
        print("Tile Z1 height FAIL")

    print("Test finished.")
    quit()
