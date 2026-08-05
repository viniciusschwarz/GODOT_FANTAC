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
	var current_val = base_val

	var behavior_stats = AIDatabase.get_behavior_stats(focus_name)
	if behavior_stats.has("stat_modifiers") and behavior_stats["stat_modifiers"].has(stat_name):
		current_val += int(behavior_stats["stat_modifiers"][stat_name])

	# Apply night time penalty
	if stat_name == "attack_power" and stats.get("attack_type", "melee") == "ranged":
		if GameHub.is_night:
			current_val -= 1
			current_val = max(1, current_val) # Prevent zero or negative attack

	return current_val

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
	
	var target = _get_best_reachable_target()
			
	# 2. Process actions against the chosen target
	if target != null:
		if current_focus == Focus.DEFEND_POSITION:
			# Defenders only attack if in range, they do not move
			if is_in_attack_range(target):
				print(str(stats["unit_name"]) + " is defending and attacks!")
				await perform_attack(target)
		else:
			# Standard behavior: Attack, or Move and Attack
			await engage_target(target)
	else:
		print(str(stats["unit_name"]) + " couldn't find a target or won! No enemies left.")
			
	GameHub.turn_ended.emit(unit_id)

func _get_best_reachable_target() -> Node2D:
	var potential_target = null
	
	match current_focus:
		Focus.ATTACK_NEAREST, Focus.DEFEND_POSITION:
			potential_target = GameHub.get_closest_enemy(self)
		Focus.HUNT_WEAKEST:
			potential_target = GameHub.get_weakest_enemy(team)
			
	if potential_target and not is_in_attack_range(potential_target):
		var move_range = get_dynamic_stat("movement_range")
		var attack_range = get_dynamic_stat("attack_range")
		# We want a true, unblocked path to the potential target.
		# _get_walkable_path has a fallback to ignore units if fully blocked.
		# If the target is fully blocked, the fallback will give a partial path to get closer,
		# which is exactly what we want instead of switching targets if they are just behind a wall of units.
		# However, if there's no path AT ALL (e.g. walled off by terrain), we should pick a new target.
		var path = Pathfinder.get_walkable_path(grid_position, potential_target.grid_position, move_range, attack_range)
		if path.is_empty():
			# Walled off completely. Find ANY reachable enemy.
			var enemies = []
			for unit_id in GameHub.active_units:
				var unit = GameHub.active_units[unit_id]
				if unit.team != team and unit != potential_target:
					enemies.append(unit)
			
			for enemy in enemies:
				if is_in_attack_range(enemy):
					return enemy
				var alt_path = Pathfinder.get_walkable_path(grid_position, enemy.grid_position, move_range, attack_range)
				if not alt_path.is_empty():
					return enemy
					
	return potential_target

func engage_target(target: Node2D):
	# Flow Phase 1: Can I attack right now?
	if is_in_attack_range(target):
		print(str(stats["unit_name"]) + " is already in range.")
		var attack_range = get_dynamic_stat("attack_range")
		var distance = get_grid_distance(grid_position, target.grid_position)
		
		# Kiting logic: If we are a ranged unit and we're closer than our max attack range, try to step back
		if distance < attack_range:
			print(str(stats["unit_name"]) + " is trying to kite backwards.")
			var kite_path = _get_kiting_path(target.grid_position, attack_range)
			if kite_path.size() > 0:
				await attempt_movement_path(kite_path)
		
		print(str(stats["unit_name"]) + " attacks!")
		await perform_attack(target)
		return # Turn complete
		
	# Flow Phase 2: If not in range, move towards the target
	print(str(stats["unit_name"]) + " is not in range. Moving...")
	await attempt_movement(target.grid_position)
	
	# Flow Phase 3: Check again after moving. Did we reach them?
	if is_in_attack_range(target):
		print(str(stats["unit_name"]) + " reached the target and attacks!")
		await perform_attack(target)
	else:
		print(str(stats["unit_name"]) + " moved, but is still too far to attack.")

# ==========================================
# 5. MOVEMENT EXECUTION (Updated)
# ==========================================
func _get_kiting_path(target_pos: Vector2, target_distance: int) -> Array[Vector2]:
	var move_range = get_dynamic_stat("movement_range")
	var current_dist = get_grid_distance(grid_position, target_pos)
	
	var best_dest = grid_position
	var max_dist_achieved = current_dist
	
	# Evaluate all cells in movement range to find the one that puts us furthest away
	# but still within target_distance (attack range)
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			if abs(x) + abs(y) > move_range and max(abs(x), abs(y)) > move_range:
				continue # skip if out of range bounds
				
			var candidate = grid_position + Vector2(x, y)
			
			if GameHub.is_cell_walkable(candidate) and GameHub.is_cell_empty(candidate):
				var dist_from_target = get_grid_distance(candidate, target_pos)
				
				# We want to increase our distance, but not exceed attack range
				if dist_from_target > max_dist_achieved and dist_from_target <= target_distance and dist_from_target > current_dist:
					# Verify we can actually path there
					var test_path = Pathfinder.get_walkable_path(grid_position, candidate, move_range, 0)
					if not test_path.is_empty() and test_path[-1] == candidate:
						max_dist_achieved = dist_from_target
						best_dest = candidate
						
	if best_dest != grid_position:
		return Pathfinder.get_walkable_path(grid_position, best_dest, move_range, 0)
		
	return []

func attempt_movement(target_pos: Vector2):
	var move_range = get_dynamic_stat("movement_range")
	var attack_range = get_dynamic_stat("attack_range")
	
	# 1. Get the full valid path from our independent Pathfinder
	var path = Pathfinder.get_walkable_path(grid_position, target_pos, move_range, attack_range)
	await attempt_movement_path(path)

func attempt_movement_path(path: Array[Vector2]):
	# 2. If the path has steps, execute the movement!
	if path.size() > 0:
		var final_destination = path[-1] # The last element in the array
		
		var old_pos = grid_position
		
		# 3. Broadcast the FULL array so Main.gd can animate it step-by-step
		# We now use GameHub.move_unit_path to update the global registry properly
		GameHub.move_unit_path(unit_id, old_pos, path)
		
		# 4. Update the logical data instantly
		grid_position = final_destination
		
		# Wait for the animation to finish in Main.gd (0.2s per tile)
		await get_tree().create_timer(path.size() * 0.2).timeout

# ==========================================
# 6. COMBAT EXECUTION
# ==========================================
func perform_attack(target: Node2D):
	var attack_dmg = get_dynamic_stat("attack_power")
	var attack_type = stats.get("attack_type", "melee")
	
	await _play_attack_anim(target.global_position)

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

func _play_attack_anim(target_global_pos: Vector2):
	var original_pos = sprite.position
	var dir = (target_global_pos - global_position).normalized()
	var bump_dist = 10.0
	
	var tween = create_tween()
	# Move forward
	tween.tween_property(sprite, "position", original_pos + dir * bump_dist, 0.1).set_trans(Tween.TRANS_SINE)
	# Move back
	tween.tween_property(sprite, "position", original_pos, 0.1).set_trans(Tween.TRANS_SINE)
	
	await tween.finished

func take_damage(amount: int):
	var defense = get_dynamic_stat("base_defense")
	var actual_damage = max(0, amount - defense)

	current_hp -= actual_damage
	health_bar.value = current_hp 
	
	GameHub.unit_took_damage.emit(unit_id, actual_damage)
	
	_play_take_damage_anim()
	
	if current_hp <= 0:
		die()

func _play_take_damage_anim():
	var original_pos = sprite.position
	var tween = create_tween()
	
	# Small shake
	tween.tween_property(sprite, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos + Vector2(3, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos, 0.05)

func die():
	print(str(stats["unit_name"]) + " has died!")
	GameHub.unit_died.emit(unit_id)
	queue_free()

# ==========================================
# 7. PLAYER INTERACTION
# ==========================================
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	pass # Selection is now handled centrally in Main.gd via grid coordinates