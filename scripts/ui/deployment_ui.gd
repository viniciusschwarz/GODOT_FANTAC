extends Control

@onready var unit_list: ItemList = $VBoxContainer/UnitList
@onready var confirm_button: Button = $ConfirmButton

var selected_unit_type: String = ""
var dummy_unit_scene = preload("res://scenes/entities/unit/dummy_unit.tscn")

func _ready() -> void:
	unit_list.item_selected.connect(_on_unit_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	set_process_input(true)

func _on_unit_selected(index: int) -> void:
	selected_unit_type = unit_list.get_item_text(index)
	print("Deployment UI: Selected ", selected_unit_type)

func _input(event: InputEvent) -> void:
	if PhaseManager.current_phase != PhaseManager.Phase.DEPLOYMENT:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if selected_unit_type == "":
			return

		# Relying on Battlefield coordinates
		var battlefield = get_tree().root.get_node_or_null("Battlefield")
		if not battlefield:
			return

		var camera = battlefield.get_node_or_null("Camera2D")
		if not camera:
			return

		var mouse_pos = camera.get_global_mouse_position()
		var grid_pos = GridManager.get_grid_position2d(mouse_pos)

		if grid_pos in EnvironmentManager.deployable_tiles:
			_spawn_unit(grid_pos, selected_unit_type)
		else:
			print("Deployment UI: Cannot deploy here. Not a valid deploy zone.")

func _spawn_unit(grid_pos: Vector2i, unit_type: String) -> void:
	print("Deployment UI: Spawning ", unit_type, " at ", grid_pos)
	if not dummy_unit_scene:
		return

	var unit = dummy_unit_scene.instantiate()
	unit.position = GridManager.get_world_position(grid_pos)

	var z = GridManager.get_tile_data(grid_pos)["z_height"]
	unit.position.y -= z * 16.0

	if unit_type == "Swordsman":
		unit.get_node("ColorRect").color = Color.RED
	else:
		unit.get_node("ColorRect").color = Color.YELLOW

	var battlefield = get_tree().root.get_node_or_null("Battlefield")
	if battlefield and battlefield.has_node("Units"):
		battlefield.get_node("Units").add_child(unit)
	else:
		get_tree().root.add_child(unit)

	# Initialize components
	if unit.has_node("MovementComponent"):
		unit.get_node("MovementComponent").initialize(3.0)
	if unit.has_node("HealthComponent"):
		unit.get_node("HealthComponent").initialize(100)

func _on_confirm_pressed() -> void:
	print("Deployment UI: Confirming Deployment")
	PhaseManager.end_deployment_phase()
	visible = false
