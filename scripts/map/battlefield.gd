extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

func _ready() -> void:
	if tilemap:
		EnvironmentManager.generate_map(tilemap)
	PhaseManager.start_combat()
