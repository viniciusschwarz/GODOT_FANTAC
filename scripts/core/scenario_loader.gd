class_name ScenarioLoader extends Node

@onready var game_manager = $"../MainGameManager"
@onready var ui_manager = $"../UIManager"

func _ready() -> void:
	var master_matrix = BattlefieldMatrix.new()
	master_matrix.initialize_grid(12, 12, 2)

	var master_units: Dictionary = {}

	# Load presets
	var vanguard_preset = ResourceLoader.load("res://data/units/vanguard_preset.tres")
	var skirmisher_preset = ResourceLoader.load("res://data/units/skirmisher_preset.tres")
	var guard_preset = ResourceLoader.load("res://data/units/guard_preset.tres")
	var archer_preset = ResourceLoader.load("res://data/units/archer_preset.tres")
	var wooden_gate_preset = ResourceLoader.load("res://data/props/wooden_gate_preset.tres")

	# Spawns Allied Vanguard at (8,1,0), Allied Skirmisher at (4,1,0)
	# Spawns Enemy Guard at (6,5,0), Enemy Archer at (6,8,1)

	var next_unit_id: int = 1

	if vanguard_preset:
		var vanguard = vanguard_preset.duplicate_data()
		vanguard.unit_id = next_unit_id
		next_unit_id += 1
		master_units[vanguard.unit_id] = vanguard
		var coord = Vector3i(8, 1, 0)
		var tile = master_matrix.get_tile(coord)
		if tile:
			tile.occupying_unit_id = vanguard.unit_id
		# [EXTERNAL DATA ACCESS]
		vanguard.template_parameters["last_coord_x"] = coord.x
		vanguard.template_parameters["last_coord_y"] = coord.y
		vanguard.template_parameters["last_coord_z"] = coord.z

	if skirmisher_preset:
		var skirmisher = skirmisher_preset.duplicate_data()
		skirmisher.unit_id = next_unit_id
		next_unit_id += 1
		master_units[skirmisher.unit_id] = skirmisher
		var coord = Vector3i(4, 1, 0)
		var tile = master_matrix.get_tile(coord)
		if tile:
			tile.occupying_unit_id = skirmisher.unit_id
		# [EXTERNAL DATA ACCESS]
		skirmisher.template_parameters["last_coord_x"] = coord.x
		skirmisher.template_parameters["last_coord_y"] = coord.y
		skirmisher.template_parameters["last_coord_z"] = coord.z

	if guard_preset:
		var guard = guard_preset.duplicate_data()
		guard.unit_id = next_unit_id
		next_unit_id += 1
		master_units[guard.unit_id] = guard
		var coord = Vector3i(6, 5, 0)
		var tile = master_matrix.get_tile(coord)
		if tile:
			tile.occupying_unit_id = guard.unit_id
		# [EXTERNAL DATA ACCESS]
		guard.template_parameters["last_coord_x"] = coord.x
		guard.template_parameters["last_coord_y"] = coord.y
		guard.template_parameters["last_coord_z"] = coord.z

	if archer_preset:
		var archer = archer_preset.duplicate_data()
		archer.unit_id = next_unit_id
		next_unit_id += 1
		master_units[archer.unit_id] = archer
		var coord = Vector3i(6, 8, 1)
		var tile = master_matrix.get_tile(coord)
		if tile:
			tile.occupying_unit_id = archer.unit_id
		# [EXTERNAL DATA ACCESS]
		archer.template_parameters["last_coord_x"] = coord.x
		archer.template_parameters["last_coord_y"] = coord.y
		archer.template_parameters["last_coord_z"] = coord.z

	# Spawn Wooden Gate prop at (6,4,0)
	var next_prop_id: int = 1000
	if wooden_gate_preset:
		var gate = wooden_gate_preset.duplicate(true)
		gate.prop_id = next_prop_id
		next_prop_id += 1
		gate.grid_position = Vector3i(6, 4, 0)
		master_matrix.register_prop(gate)

	var roster_array: Array[UnitDataResource] = []
	for unit in master_units.values():
		roster_array.append(unit)
	if ui_manager:
		ui_manager.call_deferred("set_roster", roster_array)

	game_manager.call_deferred("initialize_match", master_matrix, master_units)
