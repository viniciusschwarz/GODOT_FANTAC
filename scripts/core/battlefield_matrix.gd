## Pure stateless mathematical grid representing the 3D battlefield.
## Holds spatial layouts, navigational masks, and destructible prop instances without executing simulation logic.
class_name BattlefieldMatrix extends RefCounted

## Master mapping of spatial coordinates to TileSpatialNodeResource values.
var _grid: Dictionary = {}

## Map of all destructible prop instances mapped by prop_id.
var _props: Dictionary = {}

var _width: int = 0
var _depth: int = 0
var _height_levels: int = 0

const Z0_HEIGHT_METERS: float = 0.0
const Z1_HEIGHT_METERS: float = 3.0

## Populates an empty volumetric matrix with default spatial tiles.
func initialize_grid(width: int = 12, depth: int = 12, height_levels: int = 2) -> void:
	_width = width
	_depth = depth
	_height_levels = height_levels
	_grid.clear()

	for x in range(width):
		for y in range(depth):
			for z in range(height_levels):
				var coord = Vector3i(x, y, z)
				var tile = TileSpatialNodeResource.new()
				tile.grid_position = coord
				tile.height_offset_meters = Z1_HEIGHT_METERS if z == 1 else Z0_HEIGHT_METERS
				_grid[coord] = tile

## Produces a deep-copy of the internal grid for headless sandbox execution.
## Produces a deep-copy of the internal grid for headless sandbox execution.
func duplicate_grid() -> BattlefieldMatrix:
	var copy = BattlefieldMatrix.new()
	copy._width = _width
	copy._depth = _depth
	copy._height_levels = _height_levels

	for coord in _grid:
		var tile: TileSpatialNodeResource = _grid[coord]
		var tile_copy = TileSpatialNodeResource.new()
		tile_copy.grid_position = tile.grid_position
		tile_copy.height_offset_meters = tile.height_offset_meters
		tile_copy.base_traversal_cost = tile.base_traversal_cost
		tile_copy.vertical_connector_type = tile.vertical_connector_type
		tile_copy.cardinal_traversal_mask = tile.cardinal_traversal_mask
		tile_copy.cover_type = tile.cover_type
		tile_copy.cover_cardinal_vector = tile.cover_cardinal_vector
		tile_copy.damage_reduction_pct = tile.damage_reduction_pct
		tile_copy.occupying_unit_id = tile.occupying_unit_id
		tile_copy.reserved_unit_id = tile.reserved_unit_id
		tile_copy.reservation_micro_tick = tile.reservation_micro_tick
		tile_copy.prop_id = tile.prop_id
		copy._grid[coord] = tile_copy

	for prop_id in _props:
		var prop: MultiStagePropResource = _props[prop_id]
		var prop_copy = MultiStagePropResource.new()
		prop_copy.prop_id = prop.prop_id
		prop_copy.grid_position = prop.grid_position
		prop_copy.max_hp = prop.max_hp
		prop_copy.current_hp = prop.current_hp
		prop_copy.material_hardness_threshold = prop.material_hardness_threshold
		prop_copy.current_degradation_state = prop.current_degradation_state
		prop_copy.attached_elevated_tile_coords = prop.attached_elevated_tile_coords.duplicate()
		copy._props[prop_id] = prop_copy

	return copy

## Injects a prop definition into the master dictionary and links it to its spatial tile.
func register_prop(prop_data: MultiStagePropResource) -> void:
	if prop_data:
		_props[prop_data.prop_id] = prop_data
		var tile = get_tile(prop_data.grid_position)
		if tile:
			tile.prop_id = prop_data.prop_id

## Retrieves a destructible prop instance by its ID.
func get_prop(prop_id: int) -> MultiStagePropResource:
	return _props.get(prop_id, null)

## Retrieves the navigation layout tile at the specified 3D coordinate.
func get_tile(coord: Vector3i) -> TileSpatialNodeResource:
	return _grid.get(coord, null)

## Returns true if lateral masks and vertical stair connectors allow valid mathematical movement.
func is_cardinal_passable(from_coord: Vector3i, to_coord: Vector3i) -> bool:
	var from_tile = get_tile(from_coord)
	var to_tile = get_tile(to_coord)

	if not from_tile or not to_tile:
		return false

	var diff = to_coord - from_coord
	var dx = diff.x
	var dy = diff.y
	var dz = diff.z

	if abs(dx) + abs(dy) != 1:
		return false

	if abs(dz) > 1:
		return false

	var direction_bitmask: int = 0
	if dy == -1: direction_bitmask = 1
	elif dy == 1: direction_bitmask = 2
	elif dx == 1: direction_bitmask = 4
	elif dx == -1: direction_bitmask = 8

	# Validates traversal bitmasks against inverted directions when navigating walls.
	if (from_tile.cardinal_traversal_mask & direction_bitmask) == 0:
		return false

	var opposite_bitmask: int = 0
	if dy == -1: opposite_bitmask = 2
	elif dy == 1: opposite_bitmask = 1
	elif dx == 1: opposite_bitmask = 8
	elif dx == -1: opposite_bitmask = 4

	if (to_tile.cardinal_traversal_mask & opposite_bitmask) == 0:
		return false

	if dz != 0:
		var expected_up_connector: TileSpatialNodeResource.VerticalConnectorType = TileSpatialNodeResource.VerticalConnectorType.NONE
		var expected_down_connector: TileSpatialNodeResource.VerticalConnectorType = TileSpatialNodeResource.VerticalConnectorType.NONE

		if dy == -1:
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
		elif dy == 1:
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
		elif dx == 1:
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
		elif dx == -1:
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W

		# Validates Z-Axis stair transition logic requiring identical lateral coordinates mapping from Z0 base.
		if dz == 1:
			if from_tile.vertical_connector_type != expected_up_connector:
				return false
		elif dz == -1:
			if to_tile.vertical_connector_type != expected_down_connector:
				return false

	return true

## Executes a 3D DDA Raycast algorithm to detect solid intercepting props or cover modifiers between coordinates.
func calculate_3d_line_of_sight(origin: Vector3i, target: Vector3i) -> Dictionary:
	var result = {
		"has_los": true,
		"cover_level": TileSpatialNodeResource.CoverType.NONE,
		"intercepting_prop_id": -1,
		"damage_mitigation_pct": 0.0
	}

	if origin == target:
		return result

	# Point-blank range bypass
	var diff = target - origin
	if abs(diff.x) + abs(diff.y) + abs(diff.z) == 1:
		return result

	# 3D DDA Setup
	var start_pos = Vector3(origin.x + 0.5 + 0.0001, origin.y + 0.5 + 0.0001, origin.z + 0.5 + 0.0001)
	var end_pos = Vector3(target.x + 0.5 + 0.0001, target.y + 0.5 + 0.0001, target.z + 0.5 + 0.0001)

	var ray_dir = (end_pos - start_pos).normalized()

	var voxel = origin

	var step_x = sign(ray_dir.x)
	var step_y = sign(ray_dir.y)
	var step_z = sign(ray_dir.z)

	var t_delta_x = abs(1.0 / ray_dir.x) if ray_dir.x != 0 else INF
	var t_delta_y = abs(1.0 / ray_dir.y) if ray_dir.y != 0 else INF
	var t_delta_z = abs(1.0 / ray_dir.z) if ray_dir.z != 0 else INF

	var t_max_x = (floor(start_pos.x) + max(0, step_x) - start_pos.x) / ray_dir.x if ray_dir.x != 0 else INF
	var t_max_y = (floor(start_pos.y) + max(0, step_y) - start_pos.y) / ray_dir.y if ray_dir.y != 0 else INF
	var t_max_z = (floor(start_pos.z) + max(0, step_z) - start_pos.z) / ray_dir.z if ray_dir.z != 0 else INF

	if t_max_x < 0: t_max_x += t_delta_x
	if t_max_y < 0: t_max_y += t_delta_y
	if t_max_z < 0: t_max_z += t_delta_z

	var reached = false
	while not reached:
		if t_max_x < t_max_y and t_max_x < t_max_z:
			voxel.x += step_x
			t_max_x += t_delta_x
		elif t_max_y < t_max_z:
			voxel.y += step_y
			t_max_y += t_delta_y
		else:
			voxel.z += step_z
			t_max_z += t_delta_z

		if voxel == target:
			reached = true
			break

		if voxel.x < 0 or voxel.x >= _width or voxel.y < 0 or voxel.y >= _depth or voxel.z < 0 or voxel.z >= _height_levels:
			result["has_los"] = false
			return result

		var current_tile = get_tile(voxel)
		if current_tile:
			if current_tile.prop_id != -1:
				result["has_los"] = false
				result["intercepting_prop_id"] = current_tile.prop_id
				return result

	var target_tile = get_tile(target)
	if target_tile and target_tile.cover_type != TileSpatialNodeResource.CoverType.NONE:
		var incoming_vector = Vector2i(
			1 if origin.x > target.x else (-1 if origin.x < target.x else 0),
			1 if origin.y > target.y else (-1 if origin.y < target.y else 0)
		)

		# Parapet cover mitigates damage explicitly when the vector projection validates defensive orientation dot products.
		var dot_prod = incoming_vector.x * target_tile.cover_cardinal_vector.x + incoming_vector.y * target_tile.cover_cardinal_vector.y
		if dot_prod > 0:
			result["cover_level"] = target_tile.cover_type
			result["damage_mitigation_pct"] = target_tile.damage_reduction_pct

	return result

## Processes physical ballistic damage against the prop, evaluating material hardness thresholds before mutating HP.
func apply_prop_damage(prop_id: int, amount: float, hardness: float) -> bool:
	var prop = get_prop(prop_id)
	if not prop:
		return false

	if prop.current_degradation_state == MultiStagePropResource.DegradationState.RUBBLE:
		return false

	if hardness >= prop.material_hardness_threshold:
		prop.current_hp -= amount
		if prop.current_hp <= 0:
			collapse_prop(prop_id)
		return true

	return false

## Triggers structural fragmentation logic altering terrain masks and clearing 3D LOS occlusions.
func collapse_prop(prop_id: int) -> void:
	var prop = get_prop(prop_id)
	if not prop:
		return

	prop.current_degradation_state = MultiStagePropResource.DegradationState.RUBBLE

	var tile = get_tile(prop.grid_position)
	if tile:
		tile.base_traversal_cost = 2.0
		tile.prop_id = -1
		EventBus.navmesh_dirty.emit(prop.grid_position)

	destroy_elevated_tiles(prop.attached_elevated_tile_coords)
	EventBus.prop_state_changed.emit(prop_id, prop.current_degradation_state)

## Strips traversal masks mathematically simulating unsupported upper-floor collapse without enforcing physical gravity.
func destroy_elevated_tiles(tile_coords: Array[Vector3i]) -> void:
	for coord in tile_coords:
		var tile = get_tile(coord)
		if tile:
			tile.base_traversal_cost = INF
			tile.cardinal_traversal_mask = 0
			tile.vertical_connector_type = TileSpatialNodeResource.VerticalConnectorType.NONE

			EventBus.navmesh_dirty.emit(coord)
