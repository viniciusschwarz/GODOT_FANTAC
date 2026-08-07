extends Control

@onready var unit_list: ItemList = $VBoxContainer/UnitList
@onready var confirm_button: Button = $ConfirmButton

var selected_unit_type: String = ""

func _ready() -> void:
	unit_list.item_selected.connect(_on_unit_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	SignalBus.map_clicked.connect(_on_map_clicked)

func _on_unit_selected(index: int) -> void:
	selected_unit_type = unit_list.get_item_text(index)
	print("Deployment UI: Selected ", selected_unit_type)

func _on_map_clicked(mouse_pos: Vector2) -> void:
	if PhaseManager.current_phase != PhaseManager.Phase.DEPLOYMENT:
		return

	if selected_unit_type == "":
		return

	# Convert viewport mouse position to global using Canvas transform
	var canvas_transform: Transform2D = get_canvas_transform()
	var global_mouse_pos: Vector2 = canvas_transform.affine_inverse() * mouse_pos

	var grid_pos: Vector2i = GridManager.get_grid_position2d(global_mouse_pos)

	SignalBus.spawn_unit_requested.emit(selected_unit_type, grid_pos)

func _on_confirm_pressed() -> void:
	print("Deployment UI: Confirming Deployment")
	SignalBus.player_deployment_finished.emit()
	visible = false
