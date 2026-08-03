extends Node

var data: Dictionary = {}

func _ready():
	load_database()

func load_database():
	var file_path = "res://terrain_database.json"

	if not FileAccess.file_exists(file_path):
		push_error("TerrainDatabase: Cannot find " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var parsed_data = JSON.parse_string(json_string)

	if parsed_data != null:
		data = parsed_data
		print("TerrainDatabase: Successfully loaded terrain types.")
	else:
		push_error("TerrainDatabase: Failed to parse JSON.")

func get_terrain_stats(terrain_key: String) -> Dictionary:
	if data.has(terrain_key):
		return data[terrain_key]
	else:
		push_error("TerrainDatabase: Terrain '" + terrain_key + "' does not exist!")
		return {}
