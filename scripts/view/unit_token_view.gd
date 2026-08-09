class_name UnitTokenView extends Node2D

var unit_id: int = -1
var max_hp: float = 100.0

@onready var team_badge = $TeamBadge
@onready var token_sprite = $TokenSprite
@onready var hp_bar = $HPBar

func setup_visuals(id: int, faction: int, starting_max_hp: float, is_prop: bool) -> void:
	unit_id = id
	max_hp = starting_max_hp

	hp_bar.max_value = max_hp
	hp_bar.value = max_hp

	if is_prop:
		team_badge.color = Color.SADDLE_BROWN
	else:
		if faction == 0:
			team_badge.color = Color.BLUE
		else:
			team_badge.color = Color.RED

func update_state(grid_coord: Vector3i, current_hp: float) -> void:
	# Update HP
	hp_bar.value = current_hp

	# Update Position and Elevation
	var screen_x = grid_coord.x * 64.0 + 32.0 # center token in tile
	var screen_y = grid_coord.y * 64.0 + 32.0 # center token in tile
	var elevation_offset = grid_coord.z * -12.0

	position = Vector2(screen_x, screen_y + elevation_offset)

	# Update Z-Index
	if grid_coord.z == 0:
		z_index = 5
	else:
		z_index = 15
