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
@onready var camera = $Camera2D
@onready var canvas_modulate = $CanvasModulate
@onready var turn_manager = $TurnManager

# GUI Panels
@onready var ui_layer = $UI
@onready var main_menu_panel = $UI/MainMenuPanel
@onready var start_game_button = $UI/MainMenuPanel/StartGameButton

@onready var map_gen_panel = $UI/MapGenPanel
@onready var width_input = $UI/MapGenPanel/VBoxContainer/HBoxContainer/WidthInput
@onready var height_input = $UI/MapGenPanel/VBoxContainer/HBoxContainer/HeightInput
@onready var roll_map_button = $UI/MapGenPanel/VBoxContainer/RollButton
@onready var confirm_map_button = $UI/MapGenPanel/VBoxContainer/ConfirmMapButton
@onready var map_type_dropdown = $UI/MapGenPanel/VBoxContainer/MapTypeDropdown
@onready var day_night_toggle = $UI/MapGenPanel/VBoxContainer/DayNightToggle

@onready var unit_allocation_panel = $UI/UnitAllocationPanel
@onready var team_tabs = $UI/UnitAllocationPanel/TopBar/HBoxContainer/TeamTabs
@onready var points_input = $UI/UnitAllocationPanel/TopBar/HBoxContainer/PointsInput
@onready var mode_tabs = $UI/UnitAllocationPanel/TopBar/HBoxContainer/ModeTabs
@onready var focus_dropdown = $UI/UnitAllocationPanel/TopBar/HBoxContainer/FocusDropdown
@onready var start_battle_button = $UI/UnitAllocationPanel/TopBar/HBoxContainer/StartBattleButton
@onready var unit_button_container = $UI/UnitAllocationPanel/RosterPanel/ScrollContainer/UnitButtonContainer
@onready var unit_name_label = $UI/UnitAllocationPanel/UnitNameLabel # Hidden by default, maybe not used

@onready var game_over_panel = $UI/GameOverPanel
@onready var winner_label = $UI/GameOverPanel/WinnerLabel
@onready var restart_button = $UI/GameOverPanel/RestartButton

# Live Roster Panels
@onready var live_roster_panel = $UI/LiveRosterPanel
# FIX: Added ScrollContainer to the node paths
@onready var team_0_list = $UI/LiveRosterPanel/ScrollContainer/TeamColumns/Team0List
@onready var team_1_list = $UI/LiveRosterPanel/ScrollContainer/TeamColumns/Team1List

# ==========================================
# 3. CAMERA CONTROLS
# ==========================================
const CAMERA_SPEED = 500.0
const ZOOM_MIN = 0.5
const ZOOM_MAX = 2.0
const ZOOM_SPEED = 0.1
var target_zoom = Vector2.ONE

# ==========================================
# 4. GAME STATE & PLACEMENT VARIABLES
# ==========================================
var active_team: int = 0
var team_points: Dictionary = {0: 15, 1: 15}
var selected_unit_to_place: String = ""
var currently_selected_unit_id: String = ""

enum AllocationMode { PLACEMENT, SETUP }
var current_allocation_mode = AllocationMode.PLACEMENT

# ==========================================
# 5. INITIALIZATION
# ==========================================
func _ready():
	# UI Connections - Main Menu
	GameHub.night_mode_changed.connect(_on_global_night_mode_changed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	
	# UI Connections - Map Gen
	roll_map_button.pressed.connect(_on_roll_map_pressed)
	confirm_map_button.pressed.connect(_on_confirm_map_pressed)
	day_night_toggle.toggled.connect(_on_day_night_toggled)
	
	# UI Connections - Unit Allocation
	team_tabs.tab_changed.connect(_on_team_tab_changed)
	mode_tabs.tab_changed.connect(_on_mode_tab_changed)
	points_input.text_changed.connect(_on_points_input_changed)
	focus_dropdown.item_selected.connect(_on_focus_dropdown_item_selected)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	
	# Game Over
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	# GameHub Connections
	GameHub.unit_moved_path.connect(_on_unit_moved_path)
	GameHub.unit_took_damage.connect(_on_unit_took_damage)
	GameHub.game_over.connect(_on_game_over)
	GameHub.unit_died.connect(_on_unit_died_update_roster)
	
	setup_dropdown_options()
	generate_placement_buttons()
	
	_transition_to_main_menu()

func setup_dropdown_options():
	focus_dropdown.clear()
	focus_dropdown.add_item("Attack Nearest Enemy")
	focus_dropdown.add_item("Defend Position")
	focus_dropdown.add_item("Hunt Weakest")
	focus_dropdown.hide() # Only show in Setup Mode

func generate_placement_buttons():
	for unit_key in UnitDatabase.data.keys():
		var unit_data = UnitDatabase.get_unit_stats(unit_key)
		var cost = int(unit_data["cost"])
		
		var btn = Button.new()
		btn.text = "Place " + str(unit_data["unit_name"]) + " (" + str(cost) + " pts)"
		btn.pressed.connect(_on_buy_unit_button_pressed.bind(unit_key))
		
		unit_button_container.add_child(btn)

# ==========================================
# 6. UI TRANSITIONS
# ==========================================
# ==========================================
# 6. UI TRANSITIONS
# ==========================================
func _transition_to_main_menu():
	GameHub.change_game_state(GameHub.GameState.MAIN_MENU)
	main_menu_panel.show()
	map_gen_panel.hide()
	unit_allocation_panel.hide()
	game_over_panel.hide()
	
	# FIX: Hide the roster on the main menu
	live_roster_panel.hide() 
	
	camera.position = Vector2(576, 324)

func _on_start_game_pressed():
	_transition_to_map_gen()

func _transition_to_map_gen():
	GameHub.change_game_state(GameHub.GameState.MAP_GENERATION)
	main_menu_panel.hide()
	map_gen_panel.show()
	unit_allocation_panel.hide()
	
	# FIX: Hide the roster during map generation
	live_roster_panel.hide() 
	
	# Generate initial map based on default spinbox values
	_on_roll_map_pressed()

func _transition_to_unit_allocation():
	GameHub.change_game_state(GameHub.GameState.UNIT_ALLOCATION)
	map_gen_panel.hide()
	unit_allocation_panel.show()
	
	# FIX: Show the roster once we start allocating units
	live_roster_panel.show() 
	
	_update_allocation_ui()

# ==========================================
# 7. MAP GENERATION LOGIC
# ==========================================
func _on_roll_map_pressed():
	var w = int(width_input.value)
	var h = int(height_input.value)
	var map_type = map_type_dropdown.get_item_text(map_type_dropdown.selected)
	board.generate_new_board(Vector2(w, h), map_type)

func _on_confirm_map_pressed():
	_transition_to_unit_allocation()


func _on_day_night_toggled(is_night: bool):
	GameHub.set_night_mode(is_night)

# ==========================================
# 8. UNIT ALLOCATION LOGIC
# ==========================================
func _on_team_tab_changed(tab_idx: int):
	active_team = tab_idx
	_update_allocation_ui()

func _on_mode_tab_changed(tab_idx: int):
	current_allocation_mode = tab_idx
	_update_allocation_ui()

func _on_points_input_changed(new_text: String):
	if new_text.is_valid_int():
		team_points[active_team] = new_text.to_int()

func _update_allocation_ui():
	# Update Points Field
	points_input.text = str(team_points[active_team])
	
	# Reset selections
	selected_unit_to_place = ""
	currently_selected_unit_id = ""
	
	if current_allocation_mode == AllocationMode.PLACEMENT:
		focus_dropdown.hide()
	else:
		focus_dropdown.show()
		
func _on_buy_unit_button_pressed(unit_key: String):
	if current_allocation_mode != AllocationMode.PLACEMENT:
		print("Must be in Placement Mode to buy units.")
		return
		
	var cost = int(UnitDatabase.get_unit_stats(unit_key)["cost"])
	
	if team_points[active_team] >= cost:
		selected_unit_to_place = unit_key
		print("Selected to place: ", unit_key)
	else:
		print("Not enough points for a " + unit_key + "!")

func _on_focus_dropdown_item_selected(index: int):
	if currently_selected_unit_id != "":
		var unit = GameHub.active_units[currently_selected_unit_id]
		unit.current_focus = index
		print("Set focus for ", unit.stats["unit_name"], " to ", index)

# ==========================================
# 9. CAMERA AND INPUT LOGIC
# ==========================================
func _process(delta):
	if GameHub.current_state == GameHub.GameState.MAIN_MENU:
		return
		
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1
	
	input_dir = input_dir.normalized()
	camera.position += input_dir * CAMERA_SPEED * delta
	
	# Constrain camera
	if GameHub.board_size != Vector2.ZERO:
		var map_pixel_size = GameHub.board_size * board.tile_size
		var margin = 200.0
		
		camera.position.x = clamp(camera.position.x, board.position.x - margin, board.position.x + map_pixel_size.x + margin)
		camera.position.y = clamp(camera.position.y, board.position.y - margin, board.position.y + map_pixel_size.y + margin)
	
	camera.zoom = camera.zoom.lerp(target_zoom, 10.0 * delta)

func _unhandled_input(event):
	# Zoom Logic
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom += Vector2(ZOOM_SPEED, ZOOM_SPEED)
			target_zoom = target_zoom.clamp(Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom -= Vector2(ZOOM_SPEED, ZOOM_SPEED)
			target_zoom = target_zoom.clamp(Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))

	# Click Logic on Board
	if GameHub.current_state != GameHub.GameState.UNIT_ALLOCATION:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pixel_pos = board.get_local_mouse_position()
		var target_grid_pos = board.pixel_to_grid(mouse_pixel_pos)
		
		if board.is_within_bounds(target_grid_pos):
			if current_allocation_mode == AllocationMode.PLACEMENT:
				_handle_placement_click(target_grid_pos)
			elif current_allocation_mode == AllocationMode.SETUP:
				_handle_setup_click(target_grid_pos)

func _handle_placement_click(grid_pos: Vector2):
	# If cell is not empty, check if we own the unit to remove it
	if not GameHub.is_cell_empty(grid_pos):
		var unit_id = GameHub.grid_positions[grid_pos.round()]
		var unit = GameHub.active_units[unit_id]
		
		if unit.team == active_team:
			# Refund the points
			var refund = int(unit.stats["cost"])
			team_points[active_team] += refund
			_update_allocation_ui()
			
			# FIX: Use our new clean removal method instead of unit.die()
			GameHub.unregister_unit(unit_id) 
			_update_roster_ui() # NEW: Update Roster when removing a unit
		return

	# If cell is empty, try to place
	if selected_unit_to_place != "" and GameHub.is_cell_walkable(grid_pos):
		var unit_data = UnitDatabase.get_unit_stats(selected_unit_to_place)
		var cost = int(unit_data["cost"])
		
		# Allow placing for the selected team
		team_points[active_team] -= cost
		spawn_unit(grid_pos, selected_unit_to_place, active_team)
		
		selected_unit_to_place = ""
		_update_allocation_ui()

func _handle_setup_click(grid_pos: Vector2):
	if not GameHub.is_cell_empty(grid_pos):
		var unit_id = GameHub.grid_positions[grid_pos.round()]
		var unit = GameHub.active_units[unit_id]
		
		if unit.team == active_team:
			currently_selected_unit_id = unit_id
			focus_dropdown.select(unit.current_focus)
			print("Selected unit for setup: ", unit.stats["unit_name"])

# ==========================================
# 10. UNIT SPAWNING & VISUALS
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
	
	_update_roster_ui() # NEW: Update Roster when adding a unit

func _on_unit_moved_path(unit_id: String, path_array: Array):
	var unit = GameHub.active_units[unit_id]
	var tween = create_tween()
	
	for step_pos in path_array:
		var local_pixel_pos = board.grid_to_pixel(step_pos)
		var next_global_pixel_pos = board.to_global(local_pixel_pos)
		tween.tween_property(unit, "global_position", next_global_pixel_pos, 0.2)

func _on_unit_took_damage(unit_id: String, amount: int):
	if floating_text_template == null:
		return
		
	var unit = GameHub.active_units[unit_id]
	var damage_text = floating_text_template.instantiate()
	add_child(damage_text)
	
	damage_text.global_position = unit.global_position + Vector2(0, -30)
	damage_text.set_damage_value(amount)
	
	# FIX: Rebuild the roster UI so it fetches the newly reduced HP values
	_update_roster_ui()

# ==========================================
# 11. GAME FLOW LOGIC (Battle / Resolution)
# ==========================================
func _on_start_battle_pressed():
	unit_allocation_panel.hide()
	currently_selected_unit_id = ""
	selected_unit_to_place = ""
	
	GameHub.change_game_state(GameHub.GameState.BATTLE)
	turn_manager.start_battle_phase()

func _on_game_over(winning_team: String):
	winner_label.text = winning_team + " WINS!"
	game_over_panel.show()

func _on_restart_button_pressed():
	GameHub.clear_board_state()
	get_tree().reload_current_scene()

# ==========================================
# 12. LIVE ROSTER UI
# ==========================================
func _on_unit_died_update_roster(unit_id: String):
	_update_roster_ui()
	
func _update_roster_ui():
	# 1. Clear the old lists (we skip the first child, which is our Header Label)
	for i in range(1, team_0_list.get_child_count()):
		team_0_list.get_child(i).queue_free()
		
	for i in range(1, team_1_list.get_child_count()):
		team_1_list.get_child(i).queue_free()

	# 2. Rebuild the lists dynamically from our central GameHub brain
	for unit_id in GameHub.active_units:
		var unit = GameHub.active_units[unit_id]
		var roster_label = Label.new()
		
		# Format the text to show the unit's name and current health
		roster_label.text = str(unit.stats["unit_name"]) + " (HP: " + str(unit.current_hp) + ")"
		
		# 3. Add the label to the correct team's column
		if unit.team == 0:
			team_0_list.add_child(roster_label)
		elif unit.team == 1:
			team_1_list.add_child(roster_label)

func _on_global_night_mode_changed(is_night: bool):
	if is_night:
		canvas_modulate.color = Color(0.2, 0.2, 0.35, 1.0) # Night blueish color
	else:
		canvas_modulate.color = Color(1.0, 1.0, 1.0, 1.0) # Day color
