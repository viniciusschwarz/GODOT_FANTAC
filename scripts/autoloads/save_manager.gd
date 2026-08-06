extends Node
## SaveManager (Autoload)
## Handles serializing and deserializing game state to and from disk.

const SAVE_DIR = "user://saves/"

func _ready() -> void:
	_ensure_save_directory_exists()

func _ensure_save_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("SaveManager: Failed to create save directory.")

## Saves the given state dictionary to the specified slot.
## Automatically adds metadata like version and timestamp.
func save_game(slot_name: String, state_data: Dictionary) -> bool:
	var save_path = SAVE_DIR + slot_name + ".json"

	# Prepare the base schema
	var final_save_data = {
		"save_version": "1.0.0",
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"campaign": state_data.get("campaign", {}),
		"player_roster": state_data.get("player_roster", [])
	}

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open save file for writing: " + save_path)
		return false

	var json_string = JSON.stringify(final_save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("SaveManager: Successfully saved to " + slot_name)
	return true

## Loads game data from the specified slot.
## Returns an empty dictionary if loading fails.
func load_game(slot_name: String) -> Dictionary:
	var save_path = SAVE_DIR + slot_name + ".json"

	if not FileAccess.file_exists(save_path):
		push_error("SaveManager: Save file does not exist: " + save_path)
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open save file for reading: " + save_path)
		return {}

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		push_error("SaveManager: Error parsing save file JSON: " + save_path)
		return {}

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveManager: Invalid save file format in: " + save_path)
		return {}

	print("SaveManager: Successfully loaded save from " + slot_name)
	return data

## Returns an array of available save slot names (without the .json extension).
func get_available_saves() -> Array[String]:
	var saves: Array[String] = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				saves.append(file_name.trim_suffix(".json"))
			file_name = dir.get_next()
	return saves

## Returns true when at least one save file exists.
func has_save_file() -> bool:
	return get_available_saves().size() > 0

## Deletes a specific save file.
func delete_save(slot_name: String) -> bool:
	var save_path = SAVE_DIR + slot_name + ".json"
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err == OK:
			print("SaveManager: Deleted save " + slot_name)
			return true
		else:
			push_error("SaveManager: Failed to delete save " + slot_name)
			return false
	return false
