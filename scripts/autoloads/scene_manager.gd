extends Node
## Asynchronous scene transition controller.

var current_scene: Node = null

func _ready() -> void:
	# Grab the current scene at startup
	current_scene = get_tree().current_scene

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
