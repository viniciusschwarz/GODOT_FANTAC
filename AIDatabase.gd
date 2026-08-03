extends Node

var data: Dictionary = {}

func _ready():
	load_database()

func load_database():
	var file_path = "res://ai_behaviors.json"

	if not FileAccess.file_exists(file_path):
		push_error("AIDatabase: Cannot find " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var parsed_data = JSON.parse_string(json_string)

	if parsed_data != null:
		data = parsed_data
		print("AIDatabase: Successfully loaded AI behaviors.")
	else:
		push_error("AIDatabase: Failed to parse JSON.")

func get_behavior_stats(behavior_key: String) -> Dictionary:
	if data.has(behavior_key):
		return data[behavior_key]
	else:
		push_error("AIDatabase: Behavior '" + behavior_key + "' does not exist!")
		return {}
