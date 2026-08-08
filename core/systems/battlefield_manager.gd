# File: res://core/systems/battlefield_manager.gd
class_name BattlefieldManager extends Node

## THE ORCHESTRATOR 
## Initializes the board, spawns characters via Factory, and triggers WeGo combat.[cite: 5]

@export_category("Level Data")
@export var level_map_data: MapData

@export_category("Required Sub-Systems")
@export var map_manager: MapManager
@export var renderer: BattlefieldRenderer
@export var combat_manager: CombatManager
@export var turn_manager: TurnManager

@export_category("Test Spawning")
@export var unit_factory: UnitFactory ## INJECTED FACTORY REFERENCE[cite: 5]
@export var recruit_class: UnitClassData 
@export var starmoon_class: UnitClassData 
@export var test_ai_tree: AITreeData

var _active_units: Array[Node] = []

func _ready() -> void:
	print("BattlefieldManager: Commencing tactical initialization...")
	_initialize_board()
	_spawn_combatants()
	_start_simulation()

func _initialize_board() -> void:
	if not level_map_data:
		print("BattlefieldManager: Generating procedural town...")
		var templates: Dictionary = {
			"grass": TacticalTileData.new(),
			"wall": TacticalTileData.new(),
			"floor": TacticalTileData.new(),
			"stairs": TacticalTileData.new(),
			"window": TacticalTileData.new() # Added Window template
		}
		
		templates["grass"].tile_name = "Grass"
		templates["wall"].tile_name = "Wall"
		templates["floor"].tile_name = "Floor"
		templates["stairs"].tile_name = "Stairs"
		templates["window"].tile_name = "Window"
		
		templates["grass"].is_walkable = true
		
		templates["wall"].is_walkable = false
		templates["wall"].blocks_vision = true
		
		# Windows block physical bodies, but not line of sight
		templates["window"].is_walkable = false
		templates["window"].blocks_vision = false
		
		templates["floor"].is_walkable = true
		
		templates["stairs"].is_walkable = true
		templates["stairs"].is_stairs = true
		
		var gen: MapGenerator = MapGenerator.new(templates)
		level_map_data = MapData.new()
		level_map_data.max_z_levels = 2

		gen.fill_ground(level_map_data, 15, 15)

		var house_blueprint: BuildingBlueprintData = load("res://data/resources/map/blueprints/house_5x5.tres")
		if house_blueprint:
			gen.apply_blueprint(level_map_data, house_blueprint, Vector3i(2, 2, 0))
			gen.apply_blueprint(level_map_data, house_blueprint, Vector3i(8, 8, 0))
		
	# EXTERNAL ACCESS: Calling MapManager and Renderer APIs
	map_manager.initialize_map(level_map_data)
	renderer.initialize_visuals(level_map_data)

func _spawn_combatants() -> void:
	if not unit_factory or not recruit_class or not starmoon_class:
		push_error("BattlefieldManager: Missing Factory or Class Data for combatants!")
		return
		
	# Spawn clear of the 5x5 structures located at (2,2) and (8,8)
	var starmoon: Node2D = unit_factory.deploy_unit(starmoon_class, test_ai_tree, Vector3i(1, 1, 0), map_manager, self)
	if starmoon:
		_active_units.append(starmoon)
		starmoon.name = "Starmoon Lightyear"
	
	var recruit: Node2D = unit_factory.deploy_unit(recruit_class, test_ai_tree, Vector3i(14, 14, 0), map_manager, self)
	if recruit:
		_active_units.append(recruit)
		recruit.name = "Guild Recruit"

func _start_simulation() -> void:
	# EXTERNAL ACCESS: Calling CombatManager API[cite: 5]
	combat_manager.initialize(_active_units)
	
	print("BattlefieldManager: Bypassing Planning Phase for automated test.")
	turn_manager.advance_phase()
	turn_manager.advance_phase()
