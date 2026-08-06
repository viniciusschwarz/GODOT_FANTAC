extends Node
## Global AI evaluation processor that coordinates the Planning Phase.

var active_units: Array[Node] = []

func _ready() -> void:
	SignalBus.wego_phase_started.connect(_on_phase_started)
	SignalBus.enemy_deployment_requested.connect(_on_enemy_deployment_requested)

## Registers a unit to be processed during the Planning Phase.
func register_unit(unit: Node) -> void:
	if not active_units.has(unit):
		active_units.append(unit)

## Removes a unit (e.g., when it dies).
func unregister_unit(unit: Node) -> void:
	if active_units.has(unit):
		active_units.erase(unit)

func _on_enemy_deployment_requested(enemy_roster: Array, deployment_zones: Array[Vector2i]) -> void:
	if deployment_zones.is_empty():
		print("AIManager: No deployment zones available.")
		return

	print("AIManager: Auto-deploying ", enemy_roster.size(), " enemy types.")

	# 1. Expand roster based on count
	var units_to_deploy: Array[UnitData] = []
	for entry in enemy_roster:
		if entry.has("unit_data") and entry.has("count"):
			var unit_data: UnitData = null
			if typeof(entry["unit_data"]) == TYPE_STRING:
				unit_data = load(entry["unit_data"]) as UnitData
			else:
				unit_data = entry["unit_data"] as UnitData

			if unit_data:
				for i in range(entry["count"]):
					units_to_deploy.append(unit_data)

	# 2. Sort by role (Ranged -> Melee -> Support)
	# Assuming Role enum: 0=MELEE, 1=RANGED, 2=SUPPORT
	# We want: 1 (RANGED), then 0 (MELEE), then 2 (SUPPORT)
	units_to_deploy.sort_custom(func(a: UnitData, b: UnitData):
		var order = {
			UnitData.Role.RANGED: 0,
			UnitData.Role.MELEE: 1,
			UnitData.Role.SUPPORT: 2
		}
		var rank_a = order.get(a.role, 1)
		var rank_b = order.get(b.role, 1)
		return rank_a < rank_b
	)

	var unit_scene = load("res://scenes/entities/unit/unit.tscn")
	if not unit_scene:
		print("AIManager: Failed to load unit scene.")
		return

	var entities_node: Node = null
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("Units"):
		entities_node = current_scene.get_node("Units")
	else:
		entities_node = get_node_or_null("/root/Battlefield/Units")

	if not entities_node:
		print("AIManager: Could not find Units node for spawning.")
		entities_node = current_scene

	var available_tiles = deployment_zones.duplicate()

	# 3. Assign & Instantiate
	for unit_data in units_to_deploy:
		if available_tiles.is_empty():
			print("AIManager: Not enough deployment tiles for all enemies.")
			break

		var best_tile_idx = -1
		var best_score = -9999.0

		# Simple scoring based on role
		for i in range(available_tiles.size()):
			var pos = available_tiles[i]
			var tile = GridManager.get_tile_data(pos)
			var score: float = 0.0

			if unit_data.role == UnitData.Role.RANGED:
				if tile["z_height"] > 0:
					score += 50.0
				score += tile["cover_bonus"] * 10.0
				# Prefer rear (lower y in the enemy zone which is y < 5)
				score -= pos.y * 2.0
			elif unit_data.role == UnitData.Role.MELEE:
				# Prefer frontline (higher y in the enemy zone)
				score += pos.y * 5.0
			elif unit_data.role == UnitData.Role.SUPPORT:
				# Prefer safety/rear (lower y)
				score -= pos.y * 5.0

			if score > best_score:
				best_score = score
				best_tile_idx = i

		if best_tile_idx >= 0:
			var chosen_tile = available_tiles[best_tile_idx]
			available_tiles.remove_at(best_tile_idx)

			var unit_inst = unit_scene.instantiate() as Unit
			unit_inst.data = unit_data
			# 4. Set team_id = 1 (Enemy) and position
			unit_inst.team_id = 1
			unit_inst.position = GridManager.get_world_position(chosen_tile)
			# Align with terrain Z
			unit_inst.position.y -= GridManager.get_tile_data(chosen_tile)["z_height"] * 16.0

			entities_node.add_child(unit_inst)

			# It will initialize itself in _ready, and AIManager will pick it up when needed
			# Though register_unit can be called here or in Unit's _ready
			register_unit(unit_inst)

func _process(_delta: float) -> void:
	# Broadcast debug data every frame for visualizers
	if active_units.size() > 0:
		SignalBus.ai_debug_data_broadcasted.emit(active_units)

func _on_phase_started(phase_name: String) -> void:
	if phase_name == "planning":
		process_planning_phase()

## Iterates through all registered units and evaluates their Behavior Trees.
func process_planning_phase() -> void:
	print("AIManager: Processing behavior trees for ", active_units.size(), " units.")

	for unit in active_units:
		if is_instance_valid(unit) and unit.has_node("AIComponent"):
			var ai_comp = unit.get_node("AIComponent")
			ai_comp.evaluate_behavior()

	# Once all units have planned, tell PhaseManager to execute.
	# Assuming PhaseManager is registered as an Autoload named 'PhaseManager'
	if PhaseManager:
		PhaseManager.start_execution_phase(active_units.size())
