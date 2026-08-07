extends Node
## Asynchronous scene transition controller.

var current_scene: Node = null

const SCENE_MAP: Dictionary = {
	"boot": "res://scenes/ui/screens/boot_screen.tscn",
	"main_menu": "res://scenes/ui/screens/main_menu_screen.tscn",
	"war_desk": "res://scenes/ui/screens/war_desk_screen.tscn",
	"barracks": "res://scenes/ui/screens/barracks_screen.tscn",
	"deployment": "res://scenes/map/battlefield.tscn",
	"post_battle": "res://scenes/ui/screens/post_battle_screen.tscn",
}

func _ready() -> void:
	# Grab the current scene at startup
	current_scene = get_tree().current_scene
	SignalBus.change_scene_requested.connect(_on_change_scene_requested)

func _on_change_scene_requested(scene_id: String) -> void:
	if SCENE_MAP.has(scene_id):
		goto_scene(SCENE_MAP[scene_id])
	else:
		printerr("SceneManager: Unknown scene_id requested: ", scene_id)

func goto_scene(path: String) -> void:
	print("SceneManager: Transitioning to ", path)

	# In a fully fleshed out implementation, we would use:
	# ResourceLoader.load_threaded_request(path)
	# and show a loading screen.
	# For this MVP phase, we'll use synchronous loading.
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		printerr("Failed to transition to scene: ", path)
	else:
		# Update current scene reference (waits for frame to complete loading)
		call_deferred("_update_current_scene")

func _update_current_scene() -> void:
	current_scene = get_tree().current_scene
