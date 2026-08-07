extends Node
## Central campaign & session data store.

var current_mission: MissionData = null
var active_deployment_list: Array = []
var last_battle_results: Dictionary = {}
var player_roster: Array = []

func _ready() -> void:
	SignalBus.new_campaign_requested.connect(_on_new_campaign)
	SignalBus.continue_campaign_requested.connect(_on_continue_campaign)
	SignalBus.mission_accepted.connect(_on_mission_accepted)

func clear_state() -> void:
	current_mission = null
	active_deployment_list.clear()
	last_battle_results.clear()
	player_roster.clear()

func serialize_state() -> Dictionary:
	return {
		"campaign": {
			"current_mission": current_mission.resource_path if current_mission else ""
		},
		"player_roster": player_roster
	}

func deserialize_state(data: Dictionary) -> void:
	clear_state()
	if data.has("campaign"):
		var mission_path = data["campaign"].get("current_mission", "")
		if mission_path != "" and ResourceLoader.exists(mission_path):
			current_mission = load(mission_path)
	if data.has("player_roster"):
		player_roster = data["player_roster"].duplicate(true)

func _on_new_campaign() -> void:
	clear_state()
	# Save the fresh state immediately
	SaveManager.save_game("auto_save", serialize_state())
	SignalBus.change_scene_requested.emit("war_desk")

func _on_continue_campaign() -> void:
	if SaveManager.has_save_file():
		var data = SaveManager.load_game("auto_save")
		deserialize_state(data)
	SignalBus.change_scene_requested.emit("war_desk")

func _on_mission_accepted(mission: MissionData) -> void:
	current_mission = mission
	SignalBus.change_scene_requested.emit("deployment")
