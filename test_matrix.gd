extends SceneTree

func _init():
    var matrix = load("res://scripts/core/battlefield_matrix.gd").new()
    matrix.initialize_grid(12, 12, 2)
    var prop_data = load("res://scripts/resources/multi_stage_prop_resource.gd").new()
    prop_data.prop_id = 100
    prop_data.grid_position = Vector3i(2, 2, 0)
    prop_data.max_hp = 50.0
    prop_data.current_hp = 50.0
    prop_data.material_hardness_threshold = 5.0
    prop_data.current_degradation_state = 0
    prop_data.attached_elevated_tile_coords = [Vector3i(2, 2, 1)]

    matrix.register_prop(prop_data)

    # Try doing small damage
    var hit1 = matrix.apply_prop_damage(100, 20.0, 4.0) # Deflected
    if not hit1 and prop_data.current_hp == 50.0:
        print("Deflection OK")
    else:
        print("Deflection FAIL")

    var hit2 = matrix.apply_prop_damage(100, 20.0, 6.0) # Hit
    if hit2 and prop_data.current_hp == 30.0:
        print("Hit OK")
    else:
        print("Hit FAIL")

    var hit3 = matrix.apply_prop_damage(100, 40.0, 6.0) # Destroy
    if hit3 and prop_data.current_hp <= 0 and prop_data.current_degradation_state == 1:
        print("Destroy OK")
    else:
        print("Destroy FAIL")

    # Check attached tiles
    var attached_tile = matrix.get_tile(Vector3i(2, 2, 1))
    if attached_tile.base_traversal_cost == INF:
        print("Attached Tile Destroyed OK")
    else:
        print("Attached Tile Destroyed FAIL")

    print("Test finished.")
    quit()
