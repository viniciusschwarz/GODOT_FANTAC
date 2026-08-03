extends Node2D

# ==========================================
# 1. EXPORTED TEMPLATES
# ==========================================
@export var unit_template: PackedScene
@export var floating_text_template: PackedScene

# ==========================================
# 2. NODE REFERENCES
# ==========================================
@onready var board = $Board
@onready var turn_manager = $TurnManager
@onready var start_button = $UI/Button

@onready var game_over_panel = $UI/GameOverPanel
@onready var winner_label = $UI/GameOverPanel/WinnerLabel
@onready var restart_button = $UI/GameOverPanel/RestartButton

@onready var setup_panel = $UI/SetupPanel
@onready var unit_name_label = $UI/SetupPanel/VBoxContainer/UnitNameLabel
@onready var focus_dropdown = $UI/SetupPanel/VBoxContainer/FocusDropdown

@onready var placement_panel = $UI/PlacementPanel
@onready var points_label = $UI/PlacementPanel/VBoxContainer/PointsLabel
@onready var unit_button_container = $UI/PlacementPanel/VBoxContainer/ScrollContainer/UnitButtonContainer

# ==========================================
# 3. GAME STATE & PLACEMENT VARIABLES
# ==========================================
var currently_selected_unit_id: String = ""
var available_points: int = 15
var selected_unit_to_place: String = "" 

# ==========================================
# 4. INITIALIZATION
# ==========================================
func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	GameHub.change_game_state(GameHub.GameState.SETUP)
	
	# FIXED: Connect to our new path-based signal instead of the old single-tile one
	GameHub.unit_moved_path.connect(_on_unit_moved_path)
	
	GameHub.unit_took_damage.connect(_on_unit_took_damage)
	GameHub.game_over.connect(_on_game_over)
	GameHub.unit_selected.connect(_on_unit_selected)
	
	setup_dropdown_options()
	setup_panel.hide()
	update_points_ui()
	
	generate_placement_buttons()

# ==========================================
# 5. DYNAMIC UI GENERATION
# ==========================================
func generate_placement_buttons():
	for unit_key in UnitDatabase.data.keys():
		var unit_data = UnitDatabase.get_unit_stats(unit_key)
		var cost = int(unit_data["cost"])
		
		var btn = Button.new()
		btn.text = "Place " + str(unit_data["unit_name"]) + " (" + str(cost) + " pts)"
		btn.pressed.connect(_on_buy_unit_button_pressed.bind(unit_key))
		
		unit_button_container.add_child(btn)

# ==========================================
# 6. PLACEMENT SYSTEM LOGIC
# ==========================================
func update_points_ui():
	points_label.text = "Points: " + str(available_points)
	
	if selected_unit_to_place != "":
		points_label.text += "\nPlacing: " + selected_unit_to_place
	else:
		points_label.text += "\nSelect a unit."

func _on_buy_unit_button_pressed(unit_key: String):
	var cost = int(UnitDatabase.get_unit_stats(unit_key)["cost"])
	
	if available_points >= cost:
		selected_unit_to_place = unit_key
		update_points_ui()
	else:
		print("Not enough points for a " + unit_key + "!")

func _unhandled_input(event):
	if GameHub.current_state != GameHub.GameState.SETUP:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if selected_unit_to_place != "":
			var mouse_pixel_pos = board.get_local_mouse_position()
			var target_grid_pos = board.pixel_to_grid(mouse_pixel_pos)
			
			if board.is_within_bounds(target_grid_pos) and GameHub.is_cell_walkable(target_grid_pos):
				var unit_data = UnitDatabase.get_unit_stats(selected_unit_to_place)
				var cost = int(unit_data["cost"])
				var team = int(unit_data["default_team"])
				
				available_points -= cost
				spawn_unit(target_grid_pos, selected_unit_to_place, team)
				
				selected_unit_to_place = ""
				update_points_ui()
			else:
				print("Invalid placement! Choose an empty grass tile.")

# ==========================================
# 7. UNIT SPAWNING & VISUALS
# ==========================================
func spawn_unit(grid_pos: Vector2, unit_key: String, team_id: int):
	var new_unit = unit_template.instantiate()
	var unit_data = UnitDatabase.get_unit_stats(unit_key)
	
	new_unit.stats = unit_data
	new_unit.team = team_id
	new_unit.grid_position = grid_pos
	
	add_child(new_unit)
	
	var local_pixel_pos = board.grid_to_pixel(grid_pos)
	new_unit.global_position = board.to_global(local_pixel_pos)
	
	GameHub.register_unit(new_unit)

# FIXED: Replaced the old single-step movement function with our new path-based sequence
func _on_unit_moved_path(unit_id: String, path_array: Array):
	var unit = GameHub.active_units[unit_id]
	
	# 1. Create a Tween (Animation Engine)
	var tween = create_tween()
	
	# 2. Loop through every step provided by the Pathfinder via the GameHub
	for step_pos in path_array:
		# 3. Convert the logical grid coordinate (e.g., Vector2(3, 2)) into physical screen pixels
		var local_pixel_pos = board.grid_to_pixel(step_pos)
		var next_global_pixel_pos = board.to_global(local_pixel_pos)
		
		# 4. Add the movement step to the sequence. The unit will take 0.2 seconds per tile!
		tween.tween_property(unit, "global_position", next_global_pixel_pos, 0.2)

func _on_unit_took_damage(unit_id: String, amount: int):
	if floating_text_template == null:
		return
		
	var unit = GameHub.active_units[unit_id]
	var damage_text = floating_text_template.instantiate()
	add_child(damage_text)
	
	damage_text.global_position = unit.global_position + Vector2(0, -30)
	damage_text.set_damage_value(amount)

# ==========================================
# 8. SETUP UI LOGIC
# ==========================================
func setup_dropdown_options():
	focus_dropdown.clear()
	focus_dropdown.add_item("Attack Nearest Enemy")
	focus_dropdown.add_item("Defend Position") 
	focus_dropdown.add_item("Hunt Weakest") 

func _on_unit_selected(unit_id: String):
	currently_selected_unit_id = unit_id
	var unit = GameHub.active_units[unit_id]
	
	unit_name_label.text = "Configuring: " + str(unit.stats["unit_name"])
	focus_dropdown.select(unit.current_focus)
	setup_panel.show()

func _on_focus_dropdown_item_selected(index: int):
	if currently_selected_unit_id != "":
		var unit = GameHub.active_units[currently_selected_unit_id]
		unit.current_focus = index

# ==========================================
# 9. GAME FLOW LOGIC
# ==========================================
func _on_start_button_pressed():
	start_button.hide()
	setup_panel.hide()
	placement_panel.hide()
	
	currently_selected_unit_id = ""
	selected_unit_to_place = ""
	
	GameHub.change_game_state(GameHub.GameState.BATTLE)
	turn_manager.start_battle_phase()

func _on_game_over(winning_team: String):
	winner_label.text = winning_team + " WINS!"
	game_over_panel.show()

func _on_restart_button_pressed():
	GameHub.active_units.clear()
	GameHub.grid_positions.clear()
	get_tree().reload_current_scene()