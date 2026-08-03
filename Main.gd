extends Node2D

# ==========================================
# 1. EXPORTED VARIABLES
# ==========================================
# This allows us to drag and drop our UnitBase.tscn in the Godot Inspector
# so the Main scene knows exactly what file to copy when creating a unit.
@export var unit_template: PackedScene

# NEW: We need a template for our floating text!
@export var floating_text_template: PackedScene

# ==========================================
# 2. NODE REFERENCES
# ==========================================
# @onready tells Godot to find these nodes as soon as the game starts.
# The "$" is a shortcut for get_node().
@onready var board = $Board
@onready var turn_manager = $TurnManager
@onready var start_button = $UI/Button

# NEW: References to our Game Over UI
@onready var game_over_panel = $UI/GameOverPanel
@onready var winner_label = $UI/GameOverPanel/WinnerLabel
@onready var restart_button = $UI/GameOverPanel/RestartButton

# NEW: References to our Setup UI
@onready var setup_panel = $UI/SetupPanel
@onready var unit_name_label = $UI/SetupPanel/VBoxContainer/UnitNameLabel
@onready var focus_dropdown = $UI/SetupPanel/VBoxContainer/FocusDropdown

# ==========================================
# 3. INITIALIZATION
# ==========================================
# NEW: We need to remember which unit the player is currently editing
var currently_selected_unit_id: String = ""

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	GameHub.change_game_state(GameHub.GameState.SETUP)
	GameHub.unit_moved.connect(_on_unit_moved)
	GameHub.unit_took_damage.connect(_on_unit_took_damage)
	GameHub.game_over.connect(_on_game_over)
	
	# NEW: Listen for when the player clicks a unit
	GameHub.unit_selected.connect(_on_unit_selected)
	
	# NEW: Setup the dropdown options based on our UnitBase.Focus Enum
	setup_dropdown_options()
	
	# Hide the panel until a unit is clicked
	setup_panel.hide()
	
	setup_test_battle()

# ==========================================
# 4. GAME SETUP LOGIC
# ==========================================
func setup_test_battle():
	# Wait! If we didn't assign the unit template in the Inspector, we can't spawn them.
	if unit_template == null:
		print("Error: Please assign UnitBase.tscn to the Unit Template slot in the Inspector!")
		return
		
	print("Main: Setting up test units...")
	
	# Create Unit 1 (Player Knight)
	spawn_unit(Vector2(2, 4), "Knight", 0) # 0 is Team.PLAYER in our Enum
	
	# Create Unit 2 (Enemy Goblin)
	spawn_unit(Vector2(5, 4), "Goblin", 1) # 1 is Team.ENEMY in our Enum

func spawn_unit(grid_pos: Vector2, unit_name: String, team_id: int):
	# 1. Create a copy (instance) of our UnitBase scene
	var new_unit = unit_template.instantiate()
	
	# 2. Add it to the game world as a child of the Main scene
	add_child(new_unit)
	
	# 3. Customize the stats (Overriding the defaults in the base script)
	new_unit.unit_name = unit_name
	new_unit.team = team_id
	new_unit.grid_position = grid_pos
	
	# 4. Ask the Board for the exact pixel location for this grid coordinate
	new_unit.position = board.grid_to_pixel(grid_pos)
	
	# 5. Tell the Central Hub that this unit exists! We now pass the entire 'new_unit' object to the Hub!
	GameHub.register_unit(new_unit)

# ==========================================
# 5. UI INTERACTIONS
# ==========================================
func _on_start_button_pressed():
	start_button.hide()
	
	# NEW: Hide the setup panel so the player can't change tactics during battle
	setup_panel.hide()
	currently_selected_unit_id = "" # Clear the selection memory
	
	print("\n--- BATTLE STARTING ---")
	GameHub.change_game_state(GameHub.GameState.BATTLE)
	turn_manager.start_battle_phase()
	
# NEW: The Visual Animation Director
func _on_unit_moved(unit_id: String, new_grid_pos: Vector2):
	# Grab the unit from the Hub
	var unit = GameHub.active_units[unit_id]
	# Ask the board exactly where this new grid coordinate is on the screen
	var new_pixel_pos = board.grid_to_pixel(new_grid_pos)
	
	# Tween is Godot's built-in animation tool. It smoothly transitions values.
	var tween = create_tween()
	# We tell it to animate the unit's "position" to the 'new_pixel_pos' over 0.3 seconds.
	tween.tween_property(unit, "position", new_pixel_pos, 0.3)
	
# ==========================================
# NEW: VISUAL DAMAGE FEEDBACK
# ==========================================
func _on_unit_took_damage(unit_id: String, amount: int):
	# Safety check: Did we assign the floating text scene in the Inspector?
	if floating_text_template == null:
		print("Error: Please assign FloatingText.tscn to the Main scene!")
		return
		
	# 1. Get the unit that was hit from the Hub
	var unit = GameHub.active_units[unit_id]
	
	# 2. Create a copy of the floating text
	var damage_text = floating_text_template.instantiate()
	
	# 3. Add it to the Main scene (NOT the unit!)
	add_child(damage_text)
	
	# 4. Set the position of the text to match where the unit currently is
	# We subtract a little bit from Y so it spawns above their head, not on their feet
	damage_text.global_position = unit.global_position + Vector2(100, 0)
	
	# 5. Tell the script how much damage to display
	damage_text.set_damage_value(amount)
	
# ==========================================
# NEW: GAME OVER LOGIC
# ==========================================
func _on_game_over(winning_team: String):
	print("Main: Battle finished. " + winning_team + " wins!")
	
	# 1. Update the text to announce the winner
	winner_label.text = winning_team + " WINS!"
	
	# 2. Show the Game Over panel
	game_over_panel.show()

func _on_restart_button_pressed():
	print("Restarting the game...")
	
	# Clean up the Hub's memory before restarting
	GameHub.active_units.clear()
	GameHub.grid_positions.clear()
	
	# Godot's built-in way to reload the current scene perfectly!
	get_tree().reload_current_scene()	
	
# ==========================================
# NEW: SETUP UI LOGIC
# ==========================================
func setup_dropdown_options():
	# Clear any default items
	focus_dropdown.clear()
	# Add the options in the exact same order as the UnitBase.Focus enum!
	focus_dropdown.add_item("Attack Nearest Enemy") # Index 0
	focus_dropdown.add_item("Defend Position")      # Index 1
	focus_dropdown.add_item("Hunt Weakest")         # Index 2

func _on_unit_selected(unit_id: String):
	# 1. Remember this unit
	currently_selected_unit_id = unit_id
	
	# 2. Get the unit's data from the Hub
	var unit = GameHub.active_units[unit_id]
	
	# 3. Update the UI text to show who we are editing
	unit_name_label.text = "Configuring: " + unit.unit_name
	
	# 4. Set the dropdown to match the unit's current focus
	focus_dropdown.select(unit.current_focus)
	
	# 5. Show the panel!
	setup_panel.show()

# This function runs automatically when the player chooses a new option in the dropdown
func _on_focus_dropdown_item_selected(index: int):
	# Check if we actually have a unit selected
	if currently_selected_unit_id != "":
		# Get the unit and update its brain!
		var unit = GameHub.active_units[currently_selected_unit_id]
		unit.current_focus = index
		print(unit.unit_name + " focus changed to: " + str(index))
