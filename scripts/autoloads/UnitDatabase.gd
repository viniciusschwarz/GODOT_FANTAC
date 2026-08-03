extends Node

# This dictionary will hold all our data once we load it from the JSON
var data: Dictionary = {}

# ==========================================
# 1. INITIALIZATION
# ==========================================
func _ready():
	load_database()

# ==========================================
# 2. DATA LOADING
# ==========================================
func load_database():
	var file_path = "res://data/json/units_database.json"
	
	# Check if the file actually exists
	if not FileAccess.file_exists(file_path):
		push_error("UnitDatabase: Cannot find " + file_path)
		return
		
	# Open the file and read the text inside
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	# Convert the raw text into a Godot Dictionary
	var parsed_data = JSON.parse_string(json_string)
	
	if parsed_data != null:
		data = parsed_data
		print("UnitDatabase: Successfully loaded " + str(data.size()) + " units.")
	else:
		push_error("UnitDatabase: Failed to parse JSON. Check for syntax errors!")

# ==========================================
# 3. HELPER FUNCTION
# ==========================================
# Other scripts call this to get a specific unit's stats
func get_unit_stats(unit_key: String) -> Dictionary:
	if data.has(unit_key):
		return data[unit_key]
	else:
		push_error("UnitDatabase: Unit '" + unit_key + "' does not exist in database!")
		return {}
