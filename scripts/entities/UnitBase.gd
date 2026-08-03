extends Node2D

# ==========================================
# 1. ENUMS & VARIABLES
# ==========================================
enum Team { PLAYER, ENEMY }
enum Focus { ATTACK_NEAREST, DEFEND_POSITION, HUNT_WEAKEST }

var stats: Dictionary = {}

@export var team: Team = Team.PLAYER
@export var current_focus: Focus = Focus.ATTACK_NEAREST

var current_hp: int
var grid_position: Vector2
var unit_id: String

var ProjectileScene = preload("res://scenes/entities/Projectile.tscn")

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

# ==========================================
# 2. INITIALIZATION
# ==========================================
func _ready():
	if stats.is_empty():
		push_error("UnitBase spawned without stats!")
		return
		
	current_hp = int(stats["max_hp"])
	unit_id = str(stats["unit_name"]) + "_" + str(randi() % 10000)
	
	GameHub.turn_started.connect(_on_turn_started)
	
	setup_visuals()
	setup_health_bar()

func setup_visuals():
	var tex_path = str(stats["texture_path"])
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		var scale_factor = 56.0 / sprite.texture.get_width()
		sprite.scale = Vector2(scale_factor, scale_factor)
		
	sprite.modulate = Color(1.0, 0.5, 0.5) if team == Team.ENEMY else Color(1.0, 1.0, 1.0)

func setup_health_bar():
	health_bar.max_value = int(stats["max_hp"])
	health_bar.value = current_hp
	health_bar.show_percentage = false

# ==========================================
# 3. STATS & DISTANCE HELPERS
# ==========================================
func get_dynamic_stat(stat_name: String) -> int:
	var base_val = int(stats.get(stat_name, 0))
	var focus_name = Focus.keys()[current_focus]

	var behavior_stats = AIDatabase.get_behavior_stats(focus_name)
	if behavior_stats.has("stat_modifiers") and behavior_stats["stat_modifiers"].has(stat_name):
		return base_val + int(behavior_stats["stat_modifiers"][stat_name])

	return base_val

func get_grid_distance(pos1: Vector2, pos2: Vector2) -> int:
	var dist_x = abs(pos1.x - pos2.x)
	var dist_y = abs(pos1.y - pos2.y)
	return int(max(dist_x, dist_y))

func is_in_attack_range(target: Node2D) -> bool:
	var distance = get_grid_distance(grid_position, target.grid_position)
	var my_range = get_dynamic_stat("attack_range")

	# THE DEBUGGER: This will expose exactly what the AI thinks is happening!
	print("--- RANGE CHECK FOR " + str(stats["unit_name"]) + " ---")
	print("My logical position: ", grid_position)
	print("Target logical position: ", target.grid_position)
	print("Calculated Distance: ", distance)
	print("My Active Attack Range: ", my_range)
	print("---------------------------------")
	
	return distance <= my_range

# ==========================================
# 4. TURN LOGIC & STATE FLOW
# ==========================================
func _on_turn_started(active_unit_id: String):
	if active_unit_id == unit_id:
		print(str(stats["unit_name"]) + " is starting its turn!")
		execute_turn()

func execute_turn():
	await get_tree().create_timer(0.5).timeout
	var target: Node2D = null
	
	# 1. Identify the target based on the unit's focus
	match current_focus:
		Focus.ATTACK_NEAREST, Focus.DEFEND_POSITION:
			target = GameHub.get_closest_enemy(self)
		Focus.HUNT_WEAKEST:
			target = GameHub.get_weakest_enemy(team)
			
	# 2. Process actions against the chosen target
	if target != null:
		if current_focus == Focus.DEFEND_POSITION:
			# Defenders only attack if in range, they do not move
			if is_in_attack_range(target):
				perform_attack(target)
		else:
			# Standard behavior: Attack, or Move and Attack
			engage_target(target)
	else:
		print(str(stats["unit_name"]) + " won! No enemies left.")
			
	GameHub.turn_ended.emit(unit_id)

func engage_target(target: Node2D):
	# Flow Phase 1: Can I attack right now?
	if is_in_attack_range(target):
		print(str(stats["unit_name"]) + " is already in range and attacks!")
		perform_attack(target)
		return # Turn complete
		
	# Flow Phase 2: If not in range, move towards the target
	print(str(stats["unit_name"]) + " is not in range. Moving...")
	attempt_movement(target.grid_position)
	
	# Flow Phase 3: Check again after moving. Did we reach them?
	if is_in_attack_range(target):
		print(str(stats["unit_name"]) + " reached the target and attacks!")
		perform_attack(target)
	else:
		print(str(stats["unit_name"]) + " moved, but is still too far to attack.")

# ==========================================
# 5. MOVEMENT EXECUTION (Updated)
# ==========================================
func attempt_movement(target_pos: Vector2):
	var move_range = get_dynamic_stat("movement_range")
	
	# 1. Get the full valid path from our independent Pathfinder
	var path = Pathfinder.get_walkable_path(grid_position, target_pos, move_range)
	
	# 2. If the path has steps, execute the movement!
	if path.size() > 0:
		var final_destination = path[-1] # The last element in the array
		
		# 3. Broadcast the FULL array so Main.gd can animate it step-by-step
		# Note: You will need to update GameHub to accept an Array for this signal!
		GameHub.unit_moved_path.emit(unit_id, path)
		
		# 4. Update the logical data instantly
		grid_position = final_destination

# ==========================================
# 6. COMBAT EXECUTION
# ==========================================
func perform_attack(target: Node2D):
	var attack_dmg = get_dynamic_stat("attack_power")
	var attack_type = stats.get("attack_type", "melee")

	if attack_type == "aoe":
		var proj = ProjectileScene.instantiate()
		proj.global_position = global_position
		proj.setup(target.global_position, 1) 
		get_parent().add_child(proj)
		
		var enemy_team = Team.ENEMY if team == Team.PLAYER else Team.PLAYER
		var enemies_in_range = GameHub.get_enemies_in_radius(target.grid_position, 1, enemy_team)
		for enemy in enemies_in_range:
			enemy.take_damage(attack_dmg)
			
	elif attack_type == "ranged":
		var proj = ProjectileScene.instantiate()
		proj.global_position = global_position
		proj.setup(target.global_position, 0)
		get_parent().add_child(proj)
		target.take_damage(attack_dmg)
		
	else: # Melee
		target.take_damage(attack_dmg)

func take_damage(amount: int):
	var defense = get_dynamic_stat("base_defense")
	var actual_damage = max(0, amount - defense)

	current_hp -= actual_damage
	health_bar.value = current_hp 
	
	GameHub.unit_took_damage.emit(unit_id, actual_damage)
	
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameHub.current_state == GameHub.GameState.SETUP:
			GameHub.unit_selected.emit(unit_id)