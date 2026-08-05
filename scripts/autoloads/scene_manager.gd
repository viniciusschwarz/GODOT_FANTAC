extends Node
## Asynchronous scene transition controller.

func goto_scene(path: String):
	print("SceneManager: Transitioning to ", path)

	# In a fully fleshed out implementation, we would use:
	# ResourceLoader.load_threaded_request(path)
	# and show a loading screen.
	# For this MVP phase, we'll use synchronous loading.
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		printerr("Failed to transition to scene: ", path)
