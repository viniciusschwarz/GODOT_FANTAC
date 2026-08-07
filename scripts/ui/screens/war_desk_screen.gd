extends Control

@onready var mission_list_container = $HBoxContainer/MainContent/HBoxContainerMain/MissionListPanel/VBoxContainer/ScrollContainer/MissionList
@onready var mission_name_label = $HBoxContainer/MainContent/HBoxContainerMain/MissionDetailsPanel/VBoxContainer/MissionNameLabel
@onready var mission_desc_label = $HBoxContainer/MainContent/HBoxContainerMain/MissionDetailsPanel/VBoxContainer/MissionDescLabel
@onready var difficulty_label = $HBoxContainer/MainContent/HBoxContainerMain/MissionDetailsPanel/VBoxContainer/DifficultyLabel
@onready var environment_label = $HBoxContainer/MainContent/HBoxContainerMain/MissionDetailsPanel/VBoxContainer/EnvironmentLabel
@onready var enemy_comp_label = $HBoxContainer/MainContent/HBoxContainerMain/MissionDetailsPanel/VBoxContainer/EnemyCompLabel
@onready var accept_button = $HBoxContainer/MainContent/HBoxContainerMain/MissionDetailsPanel/VBoxContainer/AcceptButton

var selected_mission: MissionData = null
const MISSION_LIST_ITEM = preload("res://scenes/ui/components/mission_list_item.tscn")

func _ready():
	SaveManager.save_game("auto_save", GameState.serialize_state())
	accept_button.pressed.connect(_on_accept)
	_populate_mission_list()

func _populate_mission_list():
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
			var item = MISSION_LIST_ITEM.instantiate()
			mission_list_container.add_child(item)
			item.setup(mission)
			item.mission_selected.connect(_on_mission_selected)

func _on_mission_selected(mission: MissionData):
	selected_mission = mission
	mission_name_label.text = mission.mission_name
	mission_desc_label.text = mission.description
	difficulty_label.text = "Difficulty: " + str(mission.difficulty_rating)

	var biome_name = "Unknown"
	if mission.biome_preset:
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

func _on_accept():
	if selected_mission:
		SignalBus.mission_accepted.emit(selected_mission)

