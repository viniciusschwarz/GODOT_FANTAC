extends Node2D

# ==========================================
# 1. ENUMS (Categories)
# ==========================================
enum Team { PLAYER, ENEMY }

enum Focus {
	ATTACK_NEAREST,
	DEFEND_POSITION,
	HUNT_WEAKEST
}

# ==========================================
# 2. EXPORTED VARIABLES (Stats you can edit in the Inspector)
# ==========================================
@export var unit_name: String = "Base Unit"
@export var team: Team = Team.PLAYER
@export var current_focus: Focus = Focus.ATTACK_NEAREST

@export var max_hp: int = 10
@export var attack_power: int = 3
@export var movement_range: int = 2

@export var unit_texture: Texture2D

# ==========================================
# 3. INTERNAL VARIABLES & NODE REFERENCES
# ==========================================
var current_hp: int
var grid_position: Vector2
var unit_id: String 

# @onready grabs the nodes right as the scene loads into the game
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar # NEW: Reference to our new UI node

# ==========================================
# 4. INITIALIZATION
# ==========================================
func _ready():
	current_hp = max_hp
	unit_id = "Unit_" + str(randi() % 10000)
	
	GameHub.turn_started.connect(_on_turn_started)
	
	setup_visuals()
	setup_health_bar() # NEW: Setup the bar when the unit spawns

# ==========================================
# 5. VISUAL SETUP
# ==========================================
func setup_visuals():
	if unit_texture != null:
		sprite.texture = unit_texture
		var texture_width = sprite.texture.get_width()
		var target_size = 56.0 
		var scale_factor = target_size / texture_width
		sprite.scale = Vector2(scale_factor, scale_factor)

# NEW: Configure the health bar's starting values
func setup_health_bar():
	# We tell the progress bar what 100% health looks like (e.g., 10)
	health_bar.max_value = max_hp
	# We set the current fill level to full
	health_bar.value = current_hp
	# A visual trick to make sure it looks nice
	health_bar.show_percentage = false

# ==========================================
# 6. TURN LOGIC (The AI)
# ==========================================
func _on_turn_started(active_unit_id: String):
	if active_unit_id == unit_id:
		print(unit_name + " (" + unit_id + ") is starting its turn!")
		execute_turn()

func execute_turn():
	await get_tree().create_timer(0.5).timeout
	
	match current_focus:
		Focus.ATTACK_NEAREST:
			var target = GameHub.get_closest_enemy(self)
			
			if target == null:
				print(unit_name + " won! No enemies left.")
			else:
				var dist_x = abs(grid_position.x - target.grid_position.x)
				var dist_y = abs(grid_position.y - target.grid_position.y)
				var distance = dist_x + dist_y
				
				if distance == 1:
					print(unit_name + " attacks " + target.unit_name + " for " + str(attack_power) + " damage!")
					target.take_damage(attack_power)
				else:
					move_towards(target.grid_position)
					
		Focus.DEFEND_POSITION:
			pass
		Focus.HUNT_WEAKEST:
			pass
			
	GameHub.turn_ended.emit(unit_id)

func move_towards(target_pos: Vector2):
	var step = Vector2.ZERO
	
	if target_pos.x != grid_position.x:
		step.x = sign(target_pos.x - grid_position.x)
	elif target_pos.y != grid_position.y:
		step.y = sign(target_pos.y - grid_position.y)
		
	var next_tile = grid_position + step
	
	if GameHub.is_cell_empty(next_tile):
		print(unit_name + " moves to " + str(next_tile))
		GameHub.move_unit(unit_id, grid_position, next_tile)
		grid_position = next_tile
	else:
		print(unit_name + " is blocked and waits.")

# ==========================================
# 7. COMBAT FUNCTIONS
# ==========================================
func take_damage(amount: int):
	current_hp -= amount
	
	# NEW: Update the visual progress bar immediately when taking damage
	health_bar.value = current_hp 
	
	print(unit_name + " took " + str(amount) + " damage! HP left: " + str(current_hp))
	GameHub.unit_took_damage.emit(unit_id, amount)
	
	if current_hp <= 0:
		die()

func die():
	print(unit_name + " has died!")
	GameHub.unit_died.emit(unit_id)
	queue_free()

# ==========================================
# 8. PLAYER INTERACTION
# ==========================================
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	# 1. Check if the event is a Mouse Button click
	if event is InputEventMouseButton:
		# 2. Check if it was the Left Mouse Button and it was just pressed down
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 3. Only allow selecting if the game is in the SETUP phase!
			if GameHub.current_state == GameHub.GameState.SETUP:
				print("Player clicked on: " + unit_name)
				# 4. Tell the Hub that this specific unit was selected
				GameHub.unit_selected.emit(unit_id)
