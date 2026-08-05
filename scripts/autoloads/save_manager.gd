extends Node
## Manages saving and loading game data

func save_game():
	print("SaveManager: Saving game...")
	# TODO: Implement writing to user://saves/

func has_save_file() -> bool:
	# Mocked for MVP
	return false
