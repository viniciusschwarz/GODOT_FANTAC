extends Control

func _ready():
	print("BootScreen: Initializing...")
	SettingsManager.load_and_apply_settings()
	SignalBus.boot_completed.emit()

	# Simulate a tiny delay for the logo fade (MVP)
	await get_tree().create_timer(1.0).timeout
	SceneManager.goto_scene("res://scenes/ui/screens/main_menu_screen.tscn")
