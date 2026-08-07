extends Button

signal mission_selected(mission_data: MissionData)

var current_mission: MissionData = null

func setup(mission: MissionData) -> void:
	current_mission = mission
	if current_mission:
		text = current_mission.mission_name

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if current_mission:
		mission_selected.emit(current_mission)
