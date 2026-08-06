extends Node2D

## ENVIRONMENT MANAGER
## Controls lighting, weather, time of day, and orchestrates procedural map generation.

@export var day_night_cycle: bool = true
@export var day_color: Color = Color.WHITE
@export var night_color: Color = Color(0.2, 0.2, 0.4, 1.0)
@export var turn_duration: float = 60.0

var canvas_modulate: CanvasModulate
var weather_particles: GPUParticles2D
var is_night: bool = false

# Procedural Generation variables
var tilemap: TileMapLayer
var grid_size: Vector2i = Vector2i(32, 32)
var noise: FastNoiseLite
var deployable_tiles: Array[Vector2i] = []
var enemy_deployable_tiles: Array[Vector2i] = []
var map_layers: Dictionary = {}

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, grid_size.x * GridManager.TILE_SIZE, grid_size.y * GridManager.TILE_SIZE)

func _ready() -> void:
	SignalBus.camera_z_level_changed.connect(_on_camera_z_level_changed)
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = day_color
	add_child(canvas_modulate)

	weather_particles = GPUParticles2D.new()
	weather_particles.emitting = false
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(1000, 1, 1)
	material.direction = Vector3(0, 1, 0)
	material.spread = 10
	material.initial_velocity_min = 200
	material.initial_velocity_max = 300
	weather_particles.process_material = material
	weather_particles.position = Vector2(500, -100)
	weather_particles.amount = 100
	weather_particles.lifetime = 4.0
	add_child(weather_particles)

	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05

func generate_map(target_tilemap: TileMapLayer, size: Vector2i = Vector2i(32, 32)) -> void:
	tilemap = target_tilemap
	grid_size = size
	deployable_tiles.clear()
	enemy_deployable_tiles.clear()

	GridManager.initialize_grid(grid_size)

	step1_terrain_base()
	step2_roads()

	# Connect grid neighbors after basic terrain so paths can be resolved
	GridManager.finalize_grid()

	step3_structures()
	step4_scatter_and_deploy_zones()

	print("EnvironmentManager: Map Generation Complete.")

func step1_terrain_base() -> void:
	print("Step 1: Terrain Base & Height Map")
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var n = noise.get_noise_2d(x, y)

			var z_height = 0
			var move_penalty = 1.0
			var custom_color = Color.GREEN

			if n < -0.3:
				move_penalty = 1.5
				custom_color = Color(0.4, 0.3, 0.1)
			elif n > 0.3:
				z_height = 1
				custom_color = Color.GRAY

			var cell_pos = Vector2i(x, y)
			_spawn_tile_visual(cell_pos, custom_color, z_height)
			GridManager.set_tile_data(cell_pos, z_height, move_penalty, false)

func step2_roads() -> void:
	print("Step 2: Road & Path Networks")
	var start = Vector2i(0, grid_size.y / 2)
	var end = Vector2i(grid_size.x - 1, grid_size.y / 2)

	# Since AStar isn't finalized yet, just do a simple horizontal road
	for x in range(grid_size.x):
		var p = Vector2i(x, grid_size.y / 2)
		GridManager.set_tile_data(p, 0, 0.8, false)
		_spawn_tile_visual(p, Color(0.3, 0.3, 0.3), 0)

func step3_structures() -> void:
	print("Step 3: Pre-Generated Structures")
	var structure_count = 2
	var structure_scene = load("res://scenes/map/prefabs/house_basic.tscn")
	if not structure_scene: return

	for i in range(structure_count):
		var x = randi_range(5, grid_size.x - 5)
		var y = randi_range(5, grid_size.y - 5)
		var pos = Vector2i(x, y)

		# Flatten
		GridManager.set_tile_data(pos, 0, 1.0, true)

		# Set solid via object data
		var fake_data = MapObjectData.new()
		fake_data.blocks_pathing = true
		fake_data.los_block_height = 2
		GridManager.add_map_object(pos, fake_data)

		var inst = structure_scene.instantiate()
		inst.position = GridManager.get_world_position(pos)

		# Append to TileMap so they render properly above terrain
		if tilemap:
			var layer = _get_or_create_layer(0)
			layer.add_child(inst)

func step4_scatter_and_deploy_zones() -> void:
	print("Step 4: Scatter Objects & Obstacles")
	var tree_scene = load("res://scenes/entities/map_objects/tree.tscn")
	var rock_scene = load("res://scenes/entities/map_objects/rock_formation.tscn")

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)

			var td = GridManager.get_tile_data(pos)
			if td["solid"]:
				continue

			var n = noise.get_noise_2d(x + 100, y + 100)

			if n > 0.4 and tree_scene:
				var tree = tree_scene.instantiate()
				tree.position = GridManager.get_world_position(pos)
				if tilemap:
					var layer = _get_or_create_layer(td["z_height"])
					layer.add_child(tree)
				GridManager.add_map_object(pos, tree.data)
			elif n < -0.4 and rock_scene:
				var rock = rock_scene.instantiate()
				rock.position = GridManager.get_world_position(pos)
				if tilemap:
					var layer = _get_or_create_layer(td["z_height"])
					layer.add_child(rock)
				GridManager.add_map_object(pos, rock.data)

			if y >= grid_size.y - 5 and not GridManager.get_tile_data(pos)["solid"]:
				deployable_tiles.append(pos)
				_highlight_deploy_zone(pos)

			if y < 5 and not GridManager.get_tile_data(pos)["solid"]:
				enemy_deployable_tiles.append(pos)
				_highlight_enemy_deploy_zone(pos)

func get_enemy_deployment_zones() -> Array[Vector2i]:
	return enemy_deployable_tiles

func _get_or_create_layer(z_height: int) -> Node2D:
	if map_layers.has(z_height):
		return map_layers[z_height]

	var layer = Node2D.new()
	layer.name = "ZLayer_" + str(z_height)
	# Use Godot's built-in z_index for sorting
	layer.z_index = z_height
	if tilemap:
		tilemap.add_child(layer)
	map_layers[z_height] = layer
	return layer

func _on_camera_z_level_changed(active_z: int) -> void:
	for z in map_layers.keys():
		var layer = map_layers[z]
		if z == active_z:
			layer.modulate.a = 1.0
			layer.visible = true
		elif z < active_z:
			layer.modulate.a = 0.5
			layer.visible = true
		else:
			layer.visible = false

func _spawn_tile_visual(grid_pos: Vector2i, color: Color, z_height: int) -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(GridManager.TILE_SIZE, GridManager.TILE_SIZE)
	rect.position = GridManager.get_world_position(grid_pos) - Vector2(GridManager.TILE_SIZE/2, GridManager.TILE_SIZE/2)
	rect.position.y -= z_height * 16.0

	var darken = 1.0 - (0.2 * (1 - z_height))
	rect.color = Color(color.r * darken, color.g * darken, color.b * darken, 1.0)

	if tilemap:
		var layer = _get_or_create_layer(z_height)
		layer.add_child(rect)

func _highlight_deploy_zone(grid_pos: Vector2i) -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(GridManager.TILE_SIZE, GridManager.TILE_SIZE)
	rect.position = GridManager.get_world_position(grid_pos) - Vector2(GridManager.TILE_SIZE/2, GridManager.TILE_SIZE/2)
	var z = GridManager.get_tile_data(grid_pos)["z_height"]
	rect.position.y -= z * 16.0
	rect.color = Color(0, 0, 1, 0.2)

	if tilemap:
		tilemap.add_child(rect)

func _highlight_enemy_deploy_zone(grid_pos: Vector2i) -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(GridManager.TILE_SIZE, GridManager.TILE_SIZE)
	rect.position = GridManager.get_world_position(grid_pos) - Vector2(GridManager.TILE_SIZE/2, GridManager.TILE_SIZE/2)
	var z = GridManager.get_tile_data(grid_pos)["z_height"]
	rect.position.y -= z * 16.0
	rect.color = Color(1, 0, 0, 0.2) # Red for enemy

	if tilemap:
		tilemap.add_child(rect)

func transition_to_night(duration: float = 2.0) -> void:
	is_night = true
	var tween = get_tree().create_tween()
	tween.tween_property(canvas_modulate, "color", night_color, duration)

func transition_to_day(duration: float = 2.0) -> void:
	is_night = false
	var tween = get_tree().create_tween()
	tween.tween_property(canvas_modulate, "color", day_color, duration)

func start_rain() -> void:
	weather_particles.emitting = true

func stop_weather() -> void:
	weather_particles.emitting = false
