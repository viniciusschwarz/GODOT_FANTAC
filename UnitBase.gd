extends Node2D

# ==========================================
# 1. ENUMS (Categories)
# ==========================================
enum Team { PLAYER, ENEMY }
enum Focus { ATTACK_NEAREST, DEFEND_POSITION, HUNT_WEAKEST }

# ==========================================
# 2. VARIABLES & NODE REFERENCES
# ==========================================
# We will inject the dictionary from the JSON database here
var stats: Dictionary = {}

@export var team: Team = Team.PLAYER
@export var current_focus: Focus = Focus.ATTACK_NEAREST

var current_hp: int
var grid_position: Vector2
var unit_id: String 

# @onready grabs these visual nodes the moment the scene is loaded
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

# ==========================================
# 3. INITIALIZATION
# ==========================================
func _ready():
	# Safety check: Prevent crashes if spawned without data
	if stats.is_empty():
		push_error("UnitBase spawned without stats!")
		return
		
	# Safely cast the JSON numbers into Integers to avoid float errors
	current_hp = int(stats["max_hp"])
	unit_id = str(stats["unit_name"]) + "_" + str(randi() % 10000)
	
	# Connect to the central Event Bus
	GameHub.turn_started.connect(_on_turn_started)
	
	setup_visuals()
	setup_health_bar()

# ==========================================
# 4. VISUAL SETUP
# ==========================================
func setup_visuals():
	# Load the texture using the path provided in our JSON dictionary
	var tex_path = str(stats["texture_path"])
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		
		# Auto-scale the sprite to fit neatly inside our 64x64 grid
		var texture_width = sprite.texture.get_width()
		var target_size = 56.0 
		var scale_factor = target_size / texture_width
		sprite.scale = Vector2(scale_factor, scale_factor)
		
	# Differentiate enemies visually by tinting them red
	if team == Team.ENEMY:
		sprite.modulate = Color(1.0, 0.5, 0.5) 
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0)

func setup_health_bar():
	# Configure the HealthBar node using our integer-casted stats
	health_bar.max_value = int(stats["max_hp"])
	health_bar.value = current_hp
	health_bar.show_percentage = false

# ==========================================
# 5. TURN LOGIC (The AI)
# ==========================================
func _on_turn_started(active_unit_id: String):
	# Only execute if the GameHub is calling THIS specific unit
	if active_unit_id == unit_id:
		print(str(stats["unit_name"]) + " (" + unit_id + ") is starting its turn!")
		execute_turn()

func execute_turn():
	await get_tree().create_timer(0.5).timeout
	
	match current_focus:
		Focus.ATTACK_NEAREST:
			var target = GameHub.get_closest_enemy(self)
			
			if target == null:
				print(str(stats["unit_name"]) + " won! No enemies left.")
			else:
				var dist_x = abs(grid_position.x - target.grid_position.x)
				var dist_y = abs(grid_position.y - target.grid_position.y)
				var distance = dist_x + dist_y
				
				# NEW: Read the attack range from the JSON database!
				var my_range = int(stats["attack_range"])
				
				# If the distance is less than or equal to our range, we attack!
				if distance <= my_range:
					var attack_dmg = int(stats["attack_power"])
					print(str(stats["unit_name"]) + " attacks " + str(target.stats["unit_name"]) + " for " + str(attack_dmg) + " damage!")
					target.take_damage(attack_dmg)
				else:
					move_towards(target.grid_position)
					
		Focus.DEFEND_POSITION:
			pass
		Focus.HUNT_WEAKEST:
			pass
			
	GameHub.turn_ended.emit(unit_id)

func move_towards(target_pos: Vector2):
	# Ask our independent Pathfinder module for the next safe route
	var next_tile = Pathfinder.get_next_step(grid_position, target_pos)
	
	if next_tile != grid_position:
		print(str(stats["unit_name"]) + " found a path and moves to " + str(next_tile))
		GameHub.move_unit(unit_id, grid_position, next_tile)
		grid_position = next_tile
	else:
		print(str(stats["unit_name"]) + " cannot find a path to the target and waits.")

# ==========================================
# 6. COMBAT FUNCTIONS
# ==========================================
func take_damage(amount: int):
	current_hp -= amount
	health_bar.value = current_hp 
	
	print(str(stats["unit_name"]) + " took " + str(amount) + " damage! HP left: " + str(current_hp))
	
	# Broadcast damage so floating text can appear
	GameHub.unit_took_damage.emit(unit_id, amount)
	
	if current_hp <= 0:
		die()

func die():
	print(str(stats["unit_name"]) + " has died!")
	GameHub.unit_died.emit(unit_id)
	queue_free()

# ==========================================
# 7. PLAYER INTERACTION
# ==========================================
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Detect left mouse clicks during the SETUP phase for AI configuration
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameHub.current_state == GameHub.GameState.SETUP:
			print("Player clicked on: " + str(stats["unit_name"]))
			GameHub.unit_selected.emit(unit_id)
