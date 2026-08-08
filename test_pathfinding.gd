extends SceneTree

func _init():
    var matrix = load("res://scripts/core/battlefield_matrix.gd").new()
    matrix.initialize_grid(12, 12, 2)
    var unit_data = load("res://scripts/resources/unit_data_resource.gd").new()
    unit_data.unit_id = 1

    var pathfinder = load("res://scripts/sim/pathfinding_engine.gd").new()
    var start = Vector3i(0, 0, 0)
    var target = Vector3i(2, 2, 0)
    var path = pathfinder.calculate_path(matrix, start, target, unit_data)
    if path.size() > 0:
        print("Path found! Nodes: ", path.size())
    else:
        print("Path NOT found!")

    quit()
