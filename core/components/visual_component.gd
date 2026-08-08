# File: res://core/components/visual_component.gd
class_name VisualComponent extends Node

## TRANSLATES DATA TO VISUALS (UPDATED PHASE 15)
## Updates sprite frames and handles kinetic tweening across the 2.5D grid.

@export var sprite: Sprite2D 
@export var tile_size: float = 64.0
@export var elevation_offset: float = 64.0 ## Matches the BattlefieldRenderer Z-offset
@export var movement_speed: float = 0.3 ## Seconds it takes to cross one tile

var _unit: Node
var _active_tween: Tween

func initialize(atlas_coord: Vector2i, unit: Node) -> void:
	if not sprite:
		push_error("VisualComponent: Missing Sprite2D reference!")
		return
		
	_unit = unit
	
	# Calculate the absolute frame index for a 4x4 grid
	var columns: int = sprite.hframes
	var calculated_frame: int = (atlas_coord.y * columns) + atlas_coord.x
	sprite.frame = calculated_frame
	
	# Snap to the initial logical position instantly
	var move_comp: MovementComponent = _unit.get("movement_component")
	if move_comp:
		_snap_to_grid_position(move_comp.current_coord)
		
	# EXTERNAL ACCESS NOTE: Subscribe to the global event bus to listen for THIS unit's movement
	EventBus.unit_moved.connect(_on_unit_moved)

## Calculates the actual screen pixel coordinate based on the flat 2D grid math
func _calculate_screen_position(coord: Vector3i) -> Vector2:
	var screen_x: float = float(coord.x) * tile_size
	# Removed the elevation_offset calculation completely.
	var screen_y: float = float(coord.y) * tile_size 
	
	return Vector2(screen_x + (tile_size / 2.0), screen_y + (tile_size / 2.0))

func _snap_to_grid_position(coord: Vector3i) -> void:
	var target_pos: Vector2 = _calculate_screen_position(coord)
	# The Sprite2D is a child of the Unit (Node2D). Moving the Unit root moves everything.
	_unit.position = target_pos

func _on_unit_moved(unit_reference: Node, _old_coord: Vector3i, new_coord: Vector3i) -> void:
	# Only react if this event was meant for THIS unit
	if unit_reference != _unit:
		return
		
	var target_pos: Vector2 = _calculate_screen_position(new_coord)
	
	# Kill any existing tween so we don't get glitchy competing animations
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	# Create a smooth translation interpolation
	_active_tween = create_tween()
	
	# Flip the sprite to face the direction of movement
	if target_pos.x < _unit.position.x:
		sprite.flip_h = true
	elif target_pos.x > _unit.position.x:
		sprite.flip_h = false
		
	# EXTERNAL ACCESS NOTE: Tweening the parent Unit Node2D position
	_active_tween.tween_property(_unit, "position", target_pos, movement_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
