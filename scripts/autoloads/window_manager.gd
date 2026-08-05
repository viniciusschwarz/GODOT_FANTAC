extends Node
## WINDOW MANAGER (Autoload)
## Handles all interactions with the Desktop Operating System.
## Controls screen resolution, window modes, V-Sync, and safe quitting.

func _ready() -> void:
	# 1. Intercept the OS "Quit" request (like clicking the window's X button)
	# We tell Godot: "Don't quit automatically, let me handle it!"
	get_tree().set_auto_accept_quit(false)

	# Load saved settings from SettingsManager to apply preferred resolution on startup.
	# Note: SettingsManager loads its settings in its _ready(), which we assume
	# has run or is accessible. However, SettingsManager also calls _apply_settings()
	# on its own, which we will refactor to use WindowManager.
	var w_mode = SettingsManager.get_setting("Display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	var vsync = SettingsManager.get_setting("Display", "vsync", true)
	var fps_limit = SettingsManager.get_setting("Display", "fps_limit", 0)

	set_fullscreen(w_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or w_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	set_vsync(vsync)
	set_fps_limit(fps_limit)

## 2. This built-in Godot function listens for OS-level events.
func _notification(what: int) -> void:
	# Check if the OS is asking the game to close (Alt+F4 or X button)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_safe_quit()

## 3. Custom function to safely shut down the game.
func _handle_safe_quit() -> void:
	print("Window Manager: Safe quit requested by OS.")

	# Tell the SignalBus that we are quitting.
	# Other systems (like SaveManager) can listen to this and save the game.
	SignalBus.game_quit_requested.emit()

	print("Window Manager: Shutting down safely.")
	# Finally, we tell the engine to actually close the application.
	get_tree().quit()

# ==========================================
# DISPLAY CONTROL API (Used by Settings UI)
# ==========================================

## Sets the game to Fullscreen or Windowed mode.
## @param is_fullscreen: true for Fullscreen, false for Windowed.
func set_fullscreen(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		print("Window Manager: Mode set to Fullscreen.")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Window Manager: Mode set to Windowed.")

## Toggles V-Sync (Vertical Synchronization) to prevent screen tearing.
## @param enabled: true to enable V-Sync, false to disable.
func set_vsync(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		print("Window Manager: V-Sync Enabled.")
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("Window Manager: V-Sync Disabled.")

## Sets a maximum frame rate to prevent the GPU from overworking.
## @param fps_limit: The maximum frames per second (e.g., 60). Use 0 for unlimited.
func set_fps_limit(fps_limit: int) -> void:
	Engine.max_fps = fps_limit
	print("Window Manager: FPS limit set to ", fps_limit)
