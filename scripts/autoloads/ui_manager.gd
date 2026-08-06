extends Node

var modal_layer: CanvasLayer
var background_blocker: ColorRect

# Store loaded references
const SETTINGS_SCENE = preload("res://scenes/ui/overlays/settings_screen.tscn")
const BARRACKS_SCENE = preload("res://scenes/ui/screens/barracks_screen.tscn")
# Inventory and Research placeholders for now (could be WindowBase)

func _ready() -> void:
	SignalBus.ui_navigation_requested.connect(_on_navigation_requested)

	modal_layer = CanvasLayer.new()
	modal_layer.layer = 100 # High z-index to appear on top
	add_child(modal_layer)

	background_blocker = ColorRect.new()
	background_blocker.color = Color(0, 0, 0, 0.5)
	background_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	background_blocker.visible = false
	modal_layer.add_child(background_blocker)

func _on_navigation_requested(panel_name: String) -> void:
	match panel_name:
		"Settings":
			_open_modal(SETTINGS_SCENE)
		"Roster":
			_open_modal(BARRACKS_SCENE)
		"Campaign":
			# Transition to campaign map/wardesk
			SceneManager.goto_scene("res://scenes/ui/screens/war_desk_screen.tscn")
		"Inventory":
			print("UIManager: Inventory window not implemented yet.")
		"Research":
			print("UIManager: Research window not implemented yet.")
		"SaveLoad":
			SaveManager.save_game("auto_save", {})
			SceneManager.goto_scene("res://scenes/ui/screens/main_menu_screen.tscn")

func _open_modal(scene_pack: PackedScene) -> void:
	if not scene_pack:
		return

	# Close any existing modals before opening a new one
	_close_all_modals()

	var instance: Node = scene_pack.instantiate()
	if instance.has_signal("tree_exited"):
		# If the window closes itself, it will emit tree_exited, which we can use to hide blocker
		instance.tree_exited.connect(func() -> void: _check_modals())
	modal_layer.add_child(instance)

	background_blocker.visible = true
	# Ensure the blocker stays behind the new modal
	background_blocker.move_to_front()

	if instance is Control:
		instance.move_to_front()

func _close_all_modals() -> void:
	for child in modal_layer.get_children():
		if child != background_blocker:
			child.queue_free()
	background_blocker.visible = false

func _check_modals() -> void:
	# Check if any windows are left to determine blocker visibility
	var count: int = 0
	for child in modal_layer.get_children():
		if child != background_blocker and not child.is_queued_for_deletion():
			count += 1

	background_blocker.visible = count > 0
