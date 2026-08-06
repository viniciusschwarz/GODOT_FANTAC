extends Panel
class_name LeftPanel

@onready var campaign_btn: Button = $MarginContainer/VBoxContainer/CampaignButton
@onready var roster_btn: Button = $MarginContainer/VBoxContainer/RosterButton
@onready var inventory_btn: Button = $MarginContainer/VBoxContainer/InventoryButton
@onready var research_btn: Button = $MarginContainer/VBoxContainer/ResearchButton
@onready var settings_btn: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var saveload_btn: Button = $MarginContainer/VBoxContainer/SaveLoadButton
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	campaign_btn.pressed.connect(func(): SignalBus.ui_navigation_requested.emit("Campaign"))
	roster_btn.pressed.connect(func(): SignalBus.ui_navigation_requested.emit("Roster"))
	inventory_btn.pressed.connect(func(): SignalBus.ui_navigation_requested.emit("Inventory"))
	research_btn.pressed.connect(func(): SignalBus.ui_navigation_requested.emit("Research"))
	settings_btn.pressed.connect(func(): SignalBus.ui_navigation_requested.emit("Settings"))
	saveload_btn.pressed.connect(func(): SignalBus.ui_navigation_requested.emit("SaveLoad"))
	quit_btn.pressed.connect(_on_quit_pressed)

	# Block clicks passing through
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_quit_pressed() -> void:
	# Delegate quitting safely to WindowManager
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
