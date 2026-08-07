extends Control

func _ready() -> void:
	$VBoxContainer/NewCampaignButton.pressed.connect(_on_new_campaign)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)

	$VBoxContainer/ContinueButton.disabled = not SaveManager.has_save_file()

func _on_new_campaign() -> void:
	SignalBus.new_campaign_requested.emit()

func _on_continue() -> void:
	SignalBus.continue_campaign_requested.emit()

func _on_settings() -> void:
	SignalBus.ui_navigation_requested.emit("Settings")

func _on_quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
