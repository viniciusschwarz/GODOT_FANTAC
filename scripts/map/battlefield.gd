extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var camera: TacticalCamera2D = $TacticalCamera2D

func _ready() -> void:
	if tilemap:
		EnvironmentManager.generate_map(tilemap)

		# Set camera bounds based on generated map
		if camera:
			var bounds = EnvironmentManager.get_map_bounds()
			camera.limit_left = int(bounds.position.x)
			camera.limit_top = int(bounds.position.y)
			camera.limit_right = int(bounds.position.x + bounds.size.x)
			camera.limit_bottom = int(bounds.position.y + bounds.size.y)

	PhaseManager.start_combat()
