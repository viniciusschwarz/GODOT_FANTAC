extends Control

@onready var mission_list_container = $HBoxContainerMain/MissionListPanel/VBoxContainer/ScrollContainer/MissionList
@onready var mission_name_label = $HBoxContainerMain/MissionDetailsPanel/VBoxContainer/MissionNameLabel
@onready var mission_desc_label = $HBoxContainerMain/MissionDetailsPanel/VBoxContainer/MissionDescLabel
@onready var difficulty_label = $HBoxContainerMain/MissionDetailsPanel/VBoxContainer/DifficultyLabel
@onready var environment_label = $HBoxContainerMain/MissionDetailsPanel/VBoxContainer/EnvironmentLabel
@onready var enemy_comp_label = $HBoxContainerMain/MissionDetailsPanel/VBoxContainer/EnemyCompLabel
@onready var accept_button = $HBoxContainerMain/MissionDetailsPanel/VBoxContainer/AcceptButton

@onready var barracks_button = $HBoxContainerBottom/BarracksButton
@onready var save_exit_button = $HBoxContainerBottom/SaveExitButton

var selected_mission: MissionData = null

func _ready():
	SaveManager.save_game("auto_save", {})

	barracks_button.pressed.connect(_on_barracks)
	save_exit_button.pressed.connect(_on_save_exit)
	accept_button.pressed.connect(_on_accept)

	_populate_mission_list()

func _populate_mission_list():
	# Clear existing items
	for child in mission_list_container.get_children():
		child.queue_free()

	var missions = DataManager.get_all_missions()

	if missions.is_empty():
		var label = Label.new()
		label.text = "No missions available."
		mission_list_container.add_child(label)
		return

	for mission in missions:
		if mission is MissionData:
			var btn = Button.new()
			btn.text = mission.mission_name
			btn.pressed.connect(func(): _on_mission_selected(mission))
			mission_list_container.add_child(btn)

func _on_mission_selected(mission: MissionData):
	selected_mission = mission
	mission_name_label.text = mission.mission_name
	mission_desc_label.text = mission.description
	difficulty_label.text = "Difficulty: " + str(mission.difficulty_rating)

	var biome_name = "Unknown"
	if mission.biome_preset:
		# Assuming biome_preset is a resource with a resource_name or we just display a placeholder
		biome_name = mission.biome_preset.resource_name if mission.biome_preset.resource_name != "" else "Custom Terrain"
	else:
		biome_name = "Standard Terrain"
	environment_label.text = "Environment: " + biome_name

	var comp_text = "Enemy Composition:\n"
	for enemy in mission.enemy_roster:
		var count = int(enemy.get("count", 0))
		var unit_id = enemy.get("unit_id", "Unknown")
		comp_text += "- " + str(count) + "x " + unit_id + "\n"

	enemy_comp_label.text = comp_text

	accept_button.disabled = false

func _on_barracks():
	SceneManager.goto_scene("res://scenes/ui/screens/barracks_screen.tscn")

func _on_accept():
	if selected_mission:
		GameState.current_mission = selected_mission
		SceneManager.goto_scene("res://scenes/ui/screens/deployment_screen.tscn")

func _on_save_exit():
	SaveManager.save_game("auto_save", {})
	SceneManager.goto_scene("res://scenes/ui/screens/main_menu_screen.tscn")
