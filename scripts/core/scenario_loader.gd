class_name ScenarioLoader extends Node

@onready var game_manager = $"../MainGameManager"

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
		var tile = master_matrix.get_tile(Vector3i(8, 1, 0))
		if tile:
			tile.occupying_unit_id = vanguard.unit_id

	if skirmisher_preset:
		var skirmisher = skirmisher_preset.duplicate_data()
		skirmisher.unit_id = next_unit_id
		next_unit_id += 1
		master_units[skirmisher.unit_id] = skirmisher
		var tile = master_matrix.get_tile(Vector3i(4, 1, 0))
		if tile:
			tile.occupying_unit_id = skirmisher.unit_id

	if guard_preset:
		var guard = guard_preset.duplicate_data()
		guard.unit_id = next_unit_id
		next_unit_id += 1
		master_units[guard.unit_id] = guard
		var tile = master_matrix.get_tile(Vector3i(6, 5, 0))
		if tile:
			tile.occupying_unit_id = guard.unit_id

	if archer_preset:
		var archer = archer_preset.duplicate_data()
		archer.unit_id = next_unit_id
		next_unit_id += 1
		master_units[archer.unit_id] = archer
		var tile = master_matrix.get_tile(Vector3i(6, 8, 1))
		if tile:
			tile.occupying_unit_id = archer.unit_id

	# Spawn Wooden Gate prop at (6,4,0)
	if wooden_gate_preset:
		var gate = wooden_gate_preset.duplicate(true)
		gate.grid_position = Vector3i(6, 4, 0)
		master_matrix.register_prop(gate)

	game_manager.call_deferred("initialize_match", master_matrix, master_units)
