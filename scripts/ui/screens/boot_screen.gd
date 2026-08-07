extends Control

func _ready() -> void:
	print("BootScreen: Initializing...")

	SignalBus.boot_completed.emit()

	# Simulate a tiny delay for the logo fade (MVP)
	await get_tree().create_timer(1.0).timeout
	SignalBus.change_scene_requested.emit("main_menu")
