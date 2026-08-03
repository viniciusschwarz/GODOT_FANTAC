extends Node

# ==========================================
# 1. INTERNAL VARIABLES
# ==========================================
# An Array is a list of items. We will use this to keep the order of units.
var turn_order: Array = []

# This integer (whole number) keeps track of whose turn it is in the list.
# Index 0 is the first unit, Index 1 is the second, etc.
var current_index: int = 0

# ==========================================
# 2. INITIALIZATION
# ==========================================
func _ready():
	# We set up our radio listener. Whenever ANY unit finishes its turn,
	# the GameHub broadcasts 'turn_ended'. This script will hear it and run '_on_turn_ended'.
	GameHub.turn_ended.connect(_on_turn_ended)

# ==========================================
# 3. CORE LOGIC (The Clock)
# ==========================================

# This function is meant to be called by your Main Game or UI when the player clicks "Start Battle"
func start_battle_phase():
	print("Turn Manager: Starting the battle phase!")
	
	# We ask the GameHub for all the unique IDs of the units currently on the board.
	# '.keys()' takes our Dictionary and turns it into a simple List (Array).
	turn_order = GameHub.active_units.keys()
	current_index = 0
	
	# If we have at least one unit, start the first turn!
	if turn_order.size() > 0:
		play_next_turn()
	else:
		print("Turn Manager: Error - No units on the board to start the battle!")

func play_next_turn():
	# 1. Check if we reached the end of the list. If so, a new "Round" begins!
	if current_index >= turn_order.size():
		print("\n--- End of Round. Starting new round! ---")
		current_index = 0
		# Refresh the list. If a unit died during the last round, it won't be in active_units anymore!
		turn_order = GameHub.active_units.keys()
		
		# If the list is empty after refreshing, the battle is over.
		if turn_order.size() == 0:
			print("Turn Manager: All units are dead. Battle Over.")
			return

	# 2. Look at our list and find the ID of the unit whose turn it is right now.
	var current_unit_id = turn_order[current_index]

	# 3. Check if this unit is still alive. 
	# (It might have been in the list at the start of the round, but died before its turn).
	if GameHub.active_units.has(current_unit_id):
		print("Turn Manager: It is now " + str(current_unit_id) + "'s turn.")
		
		# Tell the GameHub to shout to the world: "Hey Unit X, it is your turn!"
		GameHub.turn_started.emit(current_unit_id)
	else:
		# If the unit is dead, we don't wait. We just skip to the next one.
		print("Turn Manager: Unit " + str(current_unit_id) + " is dead. Skipping.")
		_on_turn_ended(current_unit_id)

# ==========================================
# 4. SIGNAL RECEIVERS
# ==========================================

# This runs automatically when a unit calls GameHub.turn_ended.emit()
func _on_turn_ended(unit_id: String):
	# Move our tracker to the next unit in the list
	current_index += 1
	
	# We wait half a second before starting the next turn.
	# This creates a nice visual pacing so the player can process what just happened.
	await get_tree().create_timer(0.5).timeout
	
	# Start the cycle again!
	play_next_turn()
