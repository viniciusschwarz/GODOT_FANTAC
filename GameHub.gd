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
signal unit_moved(unit_id, new_position)
signal unit_took_damage(unit_id, amount)
signal unit_died(unit_id)
signal turn_ended(unit_id)
signal unit_selected(unit_id) # Broadcasted when a player clicks a unit

# NEW: Announce that the game is over and who won!
signal game_over(winning_team_name) 

# ==========================================
# 3. GLOBAL DATA (The Brain)
# ==========================================
var active_units = {}
var grid_positions = {}

# ==========================================
# 4. INITIALIZATION
# ==========================================
func _ready():
	# NEW: The Hub listens to its own signal so it can clean up dead units
	unit_died.connect(_on_unit_died)

# ==========================================
# 5. FUNCTIONS (Tools for other scripts)
# ==========================================
func change_game_state(new_state):
	current_state = new_state
	state_changed.emit(current_state)
	print("Game State changed to: ", current_state)

func register_unit(unit_node):
	active_units[unit_node.unit_id] = unit_node
	grid_positions[unit_node.grid_position] = unit_node.unit_id
	print("Registered unit ", unit_node.unit_id, " at position ", unit_node.grid_position)

func is_cell_empty(cell_position: Vector2) -> bool:
	return not grid_positions.has(cell_position)

func move_unit(unit_id, old_position: Vector2, new_position: Vector2):
	if is_cell_empty(new_position):
		grid_positions.erase(old_position)
		grid_positions[new_position] = unit_id
		unit_moved.emit(unit_id, new_position)

# ==========================================
# 6. WIN DETECTION LOGIC
# ==========================================
func _on_unit_died(unit_id: String):
	if active_units.has(unit_id):
		var dead_unit = active_units[unit_id]
		# 1. Clean up our memory: remove the unit from the grid and active roster
		grid_positions.erase(dead_unit.grid_position)
		active_units.erase(unit_id)
		
		print("Hub: Removed " + unit_id + " from active data.")
		
		# 2. Check if the game should end
		check_win_condition()

func check_win_condition():
	var player_alive = false
	var enemy_alive = false
	
	# Loop through all remaining units to see who is still standing
	for id in active_units:
		var unit = active_units[id]
		# In our Enum: 0 is PLAYER, 1 is ENEMY
		if unit.team == 0:
			player_alive = true
		elif unit.team == 1:
			enemy_alive = true
			
	# If one team is wiped out, end the game!
	if player_alive and not enemy_alive:
		change_game_state(GameState.RESOLUTION)
		game_over.emit("PLAYER")
	elif enemy_alive and not player_alive:
		change_game_state(GameState.RESOLUTION)
		game_over.emit("ENEMY")
	elif not player_alive and not enemy_alive:
		change_game_state(GameState.RESOLUTION)
		game_over.emit("DRAW") # Just in case they kill each other at the exact same time!

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
			var distance = dist_x + dist_y
			
			if distance < shortest_distance:
				shortest_distance = distance
				closest_enemy = other_unit
				
	return closest_enemy
