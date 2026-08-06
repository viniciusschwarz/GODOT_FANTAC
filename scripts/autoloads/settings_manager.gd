extends Node
## SettingsManager (Autoload)
## Manages user preferences (Display, Audio, Controls) using ConfigFile.

const SETTINGS_FILE: String = "user://settings.cfg"
var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	_load_settings()
	_apply_settings()

## Loads settings from disk. Creates defaults if file doesn't exist.
func _load_settings() -> void:
	var err: Error = _config.load(SETTINGS_FILE)
	if err != OK:
		print("SettingsManager: No settings file found. Creating defaults.")
		_create_default_settings()
		save_settings()

## Populates the ConfigFile with default values
func _create_default_settings() -> void:
	# Display
	_config.set_value("Display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	_config.set_value("Display", "resolution_w", 1920)
	_config.set_value("Display", "resolution_h", 1080)
	_config.set_value("Display", "vsync", true)
	_config.set_value("Display", "fps_limit", 0)

	# Audio (Volumes in Db, 0.0 is default/max)
	_config.set_value("Audio", "master_volume", 0.0)
	_config.set_value("Audio", "music_volume", 0.0)
	_config.set_value("Audio", "sfx_volume", 0.0)
	_config.set_value("Audio", "ambient_volume", 0.0)

	# Controls (Placeholder for bindings)
	_config.set_value("Controls", "confirm", "ui_accept")
	_config.set_value("Controls", "cancel", "ui_cancel")

## Applies current settings to the engine (e.g. changing window mode)
func _apply_settings() -> void:
	# Apply Display Settings via WindowManager
	# Note: If WindowManager isn't ready yet, it will apply these in its own _ready() anyway,
	# but we do it here for when settings are changed dynamically.
	if get_tree().root.has_node("WindowManager"):
		var w_mode: int = _config.get_value("Display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
		WindowManager.set_fullscreen(w_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or w_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

		# VSync
		var vsync: bool = _config.get_value("Display", "vsync", true)
		WindowManager.set_vsync(vsync)

		# FPS Limit
		var fps_limit: int = _config.get_value("Display", "fps_limit", 0)
		WindowManager.set_fps_limit(fps_limit)

	# Note: Applying audio requires converting DB and routing to AudioServer buses.
	# Input map rebinding logic would also go here.
	pass

## Saves current configuration back to disk.
func save_settings() -> void:
	var err: Error = _config.save(SETTINGS_FILE)
	if err != OK:
		push_error("SettingsManager: Failed to save settings to " + SETTINGS_FILE)

## Helper to get a setting
func get_setting(section: String, key: String, default_val = null) -> Variant:
	return _config.get_value(section, key, default_val)

## Helper to set a setting and optionally apply/save it immediately
func set_setting(section: String, key: String, value: Variant, auto_save: bool = true) -> void:
	_config.set_value(section, key, value)
	if auto_save:
		save_settings()
