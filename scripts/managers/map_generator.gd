extends Node

## MAP GENERATOR
## Orchestrates procedural map generation.

var grid_size: Vector2i = Vector2i(32, 32)
var noise: FastNoiseLite
var deployable_tiles: Array[Vector2i] = []
var enemy_deployable_tiles: Array[Vector2i] = []

@export var structure_scene: PackedScene = preload("res://scenes/map/prefabs/house_basic.tscn")
@export var tree_scene: PackedScene = preload("res://scenes/entities/map_objects/tree.tscn")
@export var rock_scene: PackedScene = preload("res://scenes/entities/map_objects/rock_formation.tscn")
var tilemap: TileMapLayer

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05

func generate_map(target_tilemap: TileMapLayer, size: Vector2i = Vector2i(32, 32)) -> void:
	tilemap = target_tilemap
	grid_size = size
	deployable_tiles.clear()
	EnvironmentManager.clear_map_layers()
	enemy_deployable_tiles.clear()

	GridManager.initialize_grid(grid_size)

	step1_terrain_base()
	step2_roads()

	# Connect grid neighbors after basic terrain so paths can be resolved
	GridManager.finalize_grid()

	step3_structures()
	step4_scatter_and_deploy_zones()

	print("MapGenerator: Map Generation Complete.")

func step1_terrain_base() -> void:
	print("Step 1: Terrain Base & Height Map")
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var n: float = noise.get_noise_2d(x, y)

			var z_height: int = 0
			var move_penalty: float = 1.0
			var custom_color: Color = Color.GREEN

			if n < -0.3:
				move_penalty = 1.5
				custom_color = Color(0.4, 0.3, 0.1)
			elif n > 0.3:
				z_height = 1
				custom_color = Color.GRAY

			var cell_pos: Vector2i = Vector2i(x, y)
			EnvironmentManager.spawn_tile_visual(tilemap, cell_pos, custom_color, z_height)
			GridManager.set_tile_data(cell_pos, z_height, move_penalty, false)

func step2_roads() -> void:
	print("Step 2: Road & Path Networks")
	# Since AStar isn't finalized yet, just do a simple horizontal road
	for x in range(grid_size.x):
		var p: Vector2i = Vector2i(x, grid_size.y / 2)
		GridManager.set_tile_data(p, 0, 0.8, false)
		EnvironmentManager.spawn_tile_visual(tilemap, p, Color(0.3, 0.3, 0.3), 0)

func step3_structures() -> void:
	print("Step 3: Pre-Generated Structures")
	var structure_count: int = 2

	if not structure_scene: return

	for i in range(structure_count):
		var x: int = randi_range(5, grid_size.x - 5)
		var y: int = randi_range(5, grid_size.y - 5)
		var pos: Vector2i = Vector2i(x, y)

		# Flatten
		GridManager.set_tile_data(pos, 0, 1.0, true)

		# Set solid via object data
		var fake_data: MapObjectData = MapObjectData.new()
		fake_data.blocks_pathing = true
		fake_data.los_block_height = 2
		GridManager.add_map_object(pos, fake_data)

		var inst: Node2D = structure_scene.instantiate() as Node2D
		inst.position = GridManager.get_world_position(pos)

		# Append to TileMap so they render properly above terrain
		if tilemap:
			var layer: Node2D = EnvironmentManager.get_or_create_layer(tilemap, 0)
			layer.add_child(inst)

func step4_scatter_and_deploy_zones() -> void:
	print("Step 4: Scatter Objects & Obstacles")
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos: Vector2i = Vector2i(x, y)

			var td: Dictionary = GridManager.get_tile_data(pos)
			if td["solid"]:
				continue

			var n: float = noise.get_noise_2d(x + 100, y + 100)

			if n > 0.4 and tree_scene:
				var tree: Node2D = tree_scene.instantiate() as Node2D
				tree.position = GridManager.get_world_position(pos)
				if tilemap:
					var layer: Node2D = EnvironmentManager.get_or_create_layer(tilemap, td["z_height"])
					layer.add_child(tree)
				GridManager.add_map_object(pos, tree.data)
			elif n < -0.4 and rock_scene:
				var rock: Node2D = rock_scene.instantiate() as Node2D
				rock.position = GridManager.get_world_position(pos)
				if tilemap:
					var layer: Node2D = EnvironmentManager.get_or_create_layer(tilemap, td["z_height"])
					layer.add_child(rock)
				GridManager.add_map_object(pos, rock.data)

			if y >= grid_size.y - 5 and not GridManager.get_tile_data(pos)["solid"]:
				deployable_tiles.append(pos)
				EnvironmentManager.highlight_deploy_zone(tilemap, pos)

			if y < 5 and not GridManager.get_tile_data(pos)["solid"]:
				enemy_deployable_tiles.append(pos)
				EnvironmentManager.highlight_enemy_deploy_zone(tilemap, pos)

func get_enemy_deployment_zones() -> Array[Vector2i]:
	return enemy_deployable_tiles

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, grid_size.x * GridManager.TILE_SIZE, grid_size.y * GridManager.TILE_SIZE)
