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
var map_layers: Dictionary = {}

func _ready() -> void:
	SignalBus.camera_z_level_changed.connect(_on_camera_z_level_changed)
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = day_color
	add_child(canvas_modulate)

	weather_particles = GPUParticles2D.new()
	weather_particles.emitting = false
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
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

func get_or_create_layer(tilemap: TileMapLayer, z_height: int) -> Node2D:
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
		var layer: Node2D = map_layers[z]
		if z == active_z:
			layer.modulate.a = 1.0
			layer.visible = true
		elif z < active_z:
			layer.modulate.a = 0.5
			layer.visible = true
		else:
			layer.visible = false

func spawn_tile_visual(tilemap: TileMapLayer, grid_pos: Vector2i, color: Color, z_height: int) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(GridManager.TILE_SIZE, GridManager.TILE_SIZE)
	rect.position = GridManager.get_world_position(grid_pos) - Vector2(GridManager.TILE_SIZE/2, GridManager.TILE_SIZE/2)
	rect.position.y -= z_height * 16.0

	var darken: float = 1.0 - (0.2 * (1 - z_height))
	rect.color = Color(color.r * darken, color.g * darken, color.b * darken, 1.0)

	if tilemap:
		var layer = get_or_create_layer(tilemap, z_height)
		layer.add_child(rect)

func highlight_deploy_zone(tilemap: TileMapLayer, grid_pos: Vector2i) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(GridManager.TILE_SIZE, GridManager.TILE_SIZE)
	rect.position = GridManager.get_world_position(grid_pos) - Vector2(GridManager.TILE_SIZE/2, GridManager.TILE_SIZE/2)
	var z: int = GridManager.get_tile_data(grid_pos)["z_height"]
	rect.position.y -= z * 16.0
	rect.color = Color(0, 0, 1, 0.2)

	if tilemap:
		tilemap.add_child(rect)

func highlight_enemy_deploy_zone(tilemap: TileMapLayer, grid_pos: Vector2i) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(GridManager.TILE_SIZE, GridManager.TILE_SIZE)
	rect.position = GridManager.get_world_position(grid_pos) - Vector2(GridManager.TILE_SIZE/2, GridManager.TILE_SIZE/2)
	var z: int = GridManager.get_tile_data(grid_pos)["z_height"]
	rect.position.y -= z * 16.0
	rect.color = Color(1, 0, 0, 0.2) # Red for enemy

	if tilemap:
		tilemap.add_child(rect)

func transition_to_night(duration: float = 2.0) -> void:
	is_night = true
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(canvas_modulate, "color", night_color, duration)

func transition_to_day(duration: float = 2.0) -> void:
	is_night = false
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(canvas_modulate, "color", day_color, duration)

func start_rain() -> void:
	weather_particles.emitting = true

func stop_weather() -> void:
	weather_particles.emitting = false
func clear_map_layers() -> void:
	for z in map_layers.keys():
		var layer: Node2D = map_layers[z]
		if is_instance_valid(layer):
			layer.queue_free()
	map_layers.clear()
