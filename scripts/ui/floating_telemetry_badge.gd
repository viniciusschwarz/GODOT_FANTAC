class_name FloatingTelemetryBadge extends Control

@onready var label: Label = $Label
@onready var panel: Panel = $Panel

var selected_unit_id: int = -1
var selected_unit_grid_coord: Vector3i = Vector3i.ZERO

func _ready() -> void:
	visible = false

func update_badge(unit_id: int, grid_coord: Vector3i, latest_msg: String) -> void:
	if unit_id == -1:
		visible = false
		return

	selected_unit_id = unit_id
	selected_unit_grid_coord = grid_coord

	if latest_msg == "":
		visible = false
	else:
		label.text = latest_msg
		visible = true

func _process(_delta: float) -> void:
	if selected_unit_id == -1:
		visible = false
		return

	if label.text == "":
		visible = false
		return

	var grid_x = selected_unit_grid_coord.x
	var grid_y = selected_unit_grid_coord.y
	var grid_z = selected_unit_grid_coord.z

	var world_pos = Vector2(grid_x * 64 + 32, grid_y * 64 + 32 + (grid_z * -12))
	var screen_pos = get_viewport().get_canvas_transform() * world_pos

	# Check if screen_pos is within viewport bounds
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(screen_pos):
		visible = false
		return

	visible = true
	# global_position is fine for a Control node. We'll set size of badge properly
	global_position = screen_pos + Vector2(-size.x / 2.0, -48)
