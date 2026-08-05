extends Node
## DataManager (Autoload)
## Responsible for reading consolidated JSON files and caching them as dictionaries or CustomResources.

const UNITS_PATH = "res://data/units.json"
const WEAPONS_PATH = "res://data/weapons.json"
const RULES_PATH = "res://data/rules.json"

var _units_cache: Dictionary = {}
var _weapons_cache: Dictionary = {}
var _rules_data: Dictionary = {}

func _ready() -> void:
	_load_all_data()

## Loads all required JSON data at startup
func _load_all_data() -> void:
	_load_units()
	_load_weapons()
	_load_rules()
	print("DataManager: All data loaded successfully.")

## Helper to load a JSON file into a Dictionary
func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataManager: Could not find JSON file at " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DataManager: Failed to open file " + path)
		return {}

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("DataManager: Error parsing JSON in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	var result = json.get_data()
	if typeof(result) != TYPE_DICTIONARY:
		push_error("DataManager: Expected dictionary at root of " + path)
		return {}

	return result

## Loads and caches unit data as UnitData resources
func _load_units() -> void:
	var raw_data = _load_json_file(UNITS_PATH)
	for unit_id in raw_data:
		var u_data = UnitData.new()
		u_data.setup_from_dict(unit_id, raw_data[unit_id])
		_units_cache[unit_id] = u_data

## Loads and caches weapon data as WeaponData resources
func _load_weapons() -> void:
	var raw_data = _load_json_file(WEAPONS_PATH)
	for weapon_id in raw_data:
		var w_data = WeaponData.new()
		w_data.setup_from_dict(weapon_id, raw_data[weapon_id])
		_weapons_cache[weapon_id] = w_data

## Loads and caches rule data
func _load_rules() -> void:
	_rules_data = _load_json_file(RULES_PATH)

## Returns a UnitData resource by ID. Returns null if not found.
func get_unit_data(id: String) -> UnitData:
	if _units_cache.has(id):
		return _units_cache[id]
	push_warning("DataManager: Unit data not found for id: " + id)
	return null

## Returns a WeaponData resource by ID. Returns null if not found.
func get_weapon_data(id: String) -> WeaponData:
	if _weapons_cache.has(id):
		return _weapons_cache[id]
	push_warning("DataManager: Weapon data not found for id: " + id)
	return null

## Returns a specific rule category (e.g., "physics", "weather"). Returns empty dictionary if not found.
func get_rules(category: String) -> Dictionary:
	if _rules_data.has(category):
		return _rules_data[category]
	push_warning("DataManager: Rule category not found: " + category)
	return {}
