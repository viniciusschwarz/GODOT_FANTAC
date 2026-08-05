extends Node

# ==========================================
# 1. ENUMS (Game States)
# ==========================================
enum GameState {
	MAIN_MENU,
	MAP_GENERATION,
	UNIT_ALLOCATION,
	BATTLE,
	RESOLUTION
}

var current_state = GameState.MAIN_MENU

# ==========================================
# 2. SIGNALS (The Event Bus)
# ==========================================
signal state_changed(new_state)
signal turn_started(unit_id)
signal night_mode_changed(is_night)
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
var is_night: bool = false

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


func clear_board_state():
	active_units.clear()
	grid_positions.clear()
	terrain_cells.clear()
	board_size = Vector2.ZERO

# We use this to cleanly remove a unit during Setup/Placement 
# without triggering battle events or death animations.
func unregister_unit(unit_id: String):
	if active_units.has(unit_id):
		var unit = active_units[unit_id]
		# Remove from our central data tracking
		grid_positions.erase(unit.grid_position.round())
		active_units.erase(unit_id)
		
		# Safely delete the node from the game world
		unit.queue_free() 
		print("Hub: Unregistered and removed unit ", unit_id)

# ==========================================
# 6. WIN DETECTION LOGIC
# ==========================================
func _on_unit_died(unit_id: String):
	if active_units.has(unit_id):
		var dead_unit = active_units[unit_id]
		grid_positions.erase(dead_unit.grid_position.round())
		active_units.erase(unit_id)
		print("Hub: Removed " + unit_id + " from active data due to death.")
		
		# FIX: Only check for a winner if the game is currently in the BATTLE state!
		if current_state == GameState.BATTLE:
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
func set_night_mode(night: bool):
	is_night = night
	night_mode_changed.emit(night)
