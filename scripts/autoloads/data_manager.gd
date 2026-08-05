extends Node
## DataManager (Autoload)
## Responsible for reading Godot custom resources (.tres) and caching them.

const UNITS_DIR = "res://resources/units/"
const WEAPONS_DIR = "res://resources/weapons/"
const RULES_DIR = "res://resources/rules/"

var _units_cache: Dictionary = {}
var _weapons_cache: Dictionary = {}
var _rules_data: Dictionary = {}

func _ready() -> void:
	_load_all_data()

## Loads all required resources at startup
func _load_all_data() -> void:
	_load_units()
	_load_weapons()
	_load_rules()
	print("DataManager: All data loaded successfully.")

func _load_directory_resources(dir_path: String) -> Array:
	var resources = []
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
					var actual_file_name = file_name.trim_suffix(".remap")
					var res = load(dir_path + actual_file_name)
					if res:
						resources.append({ "id": actual_file_name.trim_suffix(".tres"), "res": res })
				file_name = dir.get_next()
	return resources

## Loads and caches unit data resources
func _load_units() -> void:
	var resources = _load_directory_resources(UNITS_DIR)
	for item in resources:
		if item.res is UnitData:
			_units_cache[item.id] = item.res

## Loads and caches weapon data resources
func _load_weapons() -> void:
	var resources = _load_directory_resources(WEAPONS_DIR)
	for item in resources:
		if item.res is WeaponData:
			_weapons_cache[item.id] = item.res

## Loads and caches rule data
func _load_rules() -> void:
	var resources = _load_directory_resources(RULES_DIR)
	for item in resources:
		_rules_data[item.id] = item.res

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

## Returns a specific rule category (e.g., "physics", "weather"). Returns null if not found.
func get_rules(category: String):
	if _rules_data.has(category):
		# We return the resource directly or we can convert metadata to a dict
		var res = _rules_data[category]
		var dict = {}
		for prop in res.get_meta_list():
			dict[prop] = res.get_meta(prop)
		if dict.size() > 0:
			return dict
		return res
	push_warning("DataManager: Rule category not found: " + category)
	return null
