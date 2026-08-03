extends Node

# ==========================================
# 1. ENUMS (Game States)
# ==========================================
enum GameState {
	SETUP,
	BATTLE,
	RESOLUTION
}

var current_state = GameState.SETUP

# ==========================================
# 2. SIGNALS (The Event Bus)
# ==========================================
signal state_changed(new_state)
signal turn_started(unit_id)
signal unit_moved_path(unit_id, path_array) 
signal unit_took_damage(unit_id, amount)
signal unit_died(unit_id)
signal turn_ended(unit_id)
signal unit_selected(unit_id) 
signal game_over(winning_team_name) 

# ==========================================
# 3. GLOBAL DATA (The Brain)
# ==========================================
var active_units = {}
var grid_positions = {}
var terrain_cells = {} 
var board_size: Vector2 = Vector2.ZERO

# ==========================================
# 4. INITIALIZATION
# ==========================================
func _ready():
	unit_died.connect(_on_unit_died)

# ==========================================
# 5. FUNCTIONS (Tools for other scripts)
# ==========================================
func change_game_state(new_state):
	current_state = new_state
	state_changed.emit(current_state)
	print("Game State changed to: ", current_state)

func register_unit(unit_node):
	# FIXED: Sanitize the position to a perfect integer before saving!
	var safe_pos = unit_node.grid_position.round()
	unit_node.grid_position = safe_pos # Fix the unit's internal memory too
	
	active_units[unit_node.unit_id] = unit_node
	grid_positions[safe_pos] = unit_node.unit_id
	print("Registered unit ", unit_node.unit_id, " at mathematically safe position ", safe_pos)
	
func register_terrain_cell(cell_position: Vector2, terrain_key: String):
	# FIXED: Sanitize terrain positions
	terrain_cells[cell_position.round()] = terrain_key

func is_cell_empty(cell_position: Vector2) -> bool:
	# FIXED: Sanitize the check so decimals don't return false positives
	return not grid_positions.has(cell_position.round())

func is_cell_walkable(cell_position: Vector2) -> bool:
	var safe_pos = cell_position.round()
	
	if terrain_cells.has(safe_pos):
		var terrain_key = terrain_cells[safe_pos]
		var terrain_stats = TerrainDatabase.get_terrain_stats(terrain_key)
		if not terrain_stats.get("walkable", true):
			return false 
		
	if grid_positions.has(safe_pos):
		return false 
		
	return true 

func move_unit_path(unit_id, old_position: Vector2, path_array: Array):
	if path_array.size() > 0:
		# FIXED: Sanitize the movement erase and set commands
		var final_destination = path_array[-1].round()
		var safe_old_pos = old_position.round()
		
		grid_positions.erase(safe_old_pos)
		grid_positions[final_destination] = unit_id
		
		unit_moved_path.emit(unit_id, path_array)

func register_board_size(size: Vector2):
	board_size = size
	Pathfinder.setup_grid(size)		

# ==========================================
# 6. WIN DETECTION LOGIC
# ==========================================
func _on_unit_died(unit_id: String):
	if active_units.has(unit_id):
		var dead_unit = active_units[unit_id]
		# FIXED: Ensure we erase using the rounded position
		grid_positions.erase(dead_unit.grid_position.round())
		active_units.erase(unit_id)
		print("Hub: Removed " + unit_id + " from active data.")
		check_win_condition()

func check_win_condition():
	var player_alive = false
	var enemy_alive = false
	
	for id in active_units:
		var unit = active_units[id]
		if unit.team == 0:
			player_alive = true
		elif unit.team == 1:
			enemy_alive = true
			
	if player_alive and not enemy_alive:
		change_game_state(GameState.RESOLUTION)
		game_over.emit("PLAYER")
	elif enemy_alive and not player_alive:
		change_game_state(GameState.RESOLUTION)
		game_over.emit("ENEMY")
	elif not player_alive and not enemy_alive:
		change_game_state(GameState.RESOLUTION)
		game_over.emit("DRAW") 

# ==========================================
# 7. AI HELPER
# ==========================================
func get_closest_enemy(requesting_unit) -> Node2D:
	var closest_enemy = null
	var shortest_distance = 9999 
	
	for unit_id in active_units:
		var other_unit = active_units[unit_id]
		if other_unit.team != requesting_unit.team:
			var dist_x = abs(requesting_unit.grid_position.x - other_unit.grid_position.x)
			var dist_y = abs(requesting_unit.grid_position.y - other_unit.grid_position.y)
			var distance = max(dist_x, dist_y)
			
			if distance < shortest_distance:
				shortest_distance = distance
				closest_enemy = other_unit
				
	return closest_enemy

func get_enemies_in_radius(center_grid_pos: Vector2, radius: int, enemy_team_id: int) -> Array:
	var enemies = []

	for unit_id in active_units:
		var other_unit = active_units[unit_id]
		if other_unit.team == enemy_team_id:
			var dist_x = abs(center_grid_pos.x - other_unit.grid_position.x)
			var dist_y = abs(center_grid_pos.y - other_unit.grid_position.y)
			var distance = max(dist_x, dist_y)

			if distance <= radius:
				enemies.append(other_unit)

	return enemies

func get_weakest_enemy(my_team_id: int) -> Node2D:
	var weakest_enemy = null
	var lowest_hp = 999999

	for unit_id in active_units:
		var other_unit = active_units[unit_id]
		if other_unit.team != my_team_id:
			if other_unit.current_hp < lowest_hp:
				lowest_hp = other_unit.current_hp
				weakest_enemy = other_unit

	return weakest_enemy