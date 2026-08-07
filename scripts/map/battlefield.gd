extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

func _ready() -> void:
	if tilemap:
		MapGenerator.generate_map(tilemap)

		# Broadcast environment bounds to decouple camera setup
		var bounds: Rect2 = MapGenerator.get_map_bounds()
		SignalBus.environment_bounds_changed.emit(bounds)

	PhaseManager.start_combat()
