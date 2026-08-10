class_name BattlefieldMatrix extends RefCounted

# The matrix stores tiles in a nested dictionary: {x: {y: {z: TileSpatialNodeResource}}}
# Using a 1D or 3D dictionary approach. Let's use a flat dictionary indexed by Vector3i for easier lookup.
var _grid: Dictionary = {}

var _props: Dictionary = {} # Maps prop_id (int) to MultiStagePropResource

var _width: int = 0
var _depth: int = 0
var _height_levels: int = 0

const Z0_HEIGHT_METERS: float = 0.0
const Z1_HEIGHT_METERS: float = 3.0

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

func register_prop(prop_data: MultiStagePropResource) -> void:
	if prop_data:
		_props[prop_data.prop_id] = prop_data
		var tile = get_tile(prop_data.grid_position)
		if tile:
			tile.prop_id = prop_data.prop_id

func get_prop(prop_id: int) -> MultiStagePropResource:
	return _props.get(prop_id, null)

func get_tile(coord: Vector3i) -> TileSpatialNodeResource:
	return _grid.get(coord, null)

func is_cardinal_passable(from_coord: Vector3i, to_coord: Vector3i) -> bool:
	var from_tile = get_tile(from_coord)
	var to_tile = get_tile(to_coord)

	if not from_tile or not to_tile:
		return false

	var diff = to_coord - from_coord
	var dx = diff.x
	var dy = diff.y
	var dz = diff.z

	# Must be exactly 1 step away laterally and potentially 1 step vertically
	if abs(dx) + abs(dy) != 1:
		return false

	if abs(dz) > 1:
		return false

	var direction_bitmask: int = 0
	if dy == -1: direction_bitmask = 1 # N
	elif dy == 1: direction_bitmask = 2 # S
	elif dx == 1: direction_bitmask = 4 # E
	elif dx == -1: direction_bitmask = 8 # W

	# Check if the traversal mask permits passage from the origin tile
	# Always check standard cardinal traversal masks, even during Z-level transitions
	if (from_tile.cardinal_traversal_mask & direction_bitmask) == 0:
		return false

	var opposite_bitmask: int = 0
	if dy == -1: opposite_bitmask = 2 # S
	elif dy == 1: opposite_bitmask = 1 # N
	elif dx == 1: opposite_bitmask = 8 # W
	elif dx == -1: opposite_bitmask = 4 # E

	if (to_tile.cardinal_traversal_mask & opposite_bitmask) == 0:
		return false

	# Z-level transition logic
	if dz != 0:
		var expected_up_connector: TileSpatialNodeResource.VerticalConnectorType = TileSpatialNodeResource.VerticalConnectorType.NONE
		var expected_down_connector: TileSpatialNodeResource.VerticalConnectorType = TileSpatialNodeResource.VerticalConnectorType.NONE

		if dy == -1: # Moving North
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
		elif dy == 1: # Moving South
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
		elif dx == 1: # Moving East
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
		elif dx == -1: # Moving West
			expected_up_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
			expected_down_connector = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W

		if dz == 1: # Moving UP
			# The stair flag must strictly be on the Z=0 (from_tile)
			if from_tile.vertical_connector_type != expected_up_connector:
				return false
		elif dz == -1: # Moving DOWN
			# The stair flag must strictly be on the Z=0 (to_tile)
			if to_tile.vertical_connector_type != expected_down_connector:
				return false

	elif from_tile.vertical_connector_type != TileSpatialNodeResource.VerticalConnectorType.NONE or to_tile.vertical_connector_type != TileSpatialNodeResource.VerticalConnectorType.NONE:
		# Can we move laterally on a stairs tile without changing Z?
		# It's usually allowed, but we don't need to explicitly block it unless specified.
		pass

	return true

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
		# Move to next voxel
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

		# Out of bounds check
		if voxel.x < 0 or voxel.x >= _width or voxel.y < 0 or voxel.y >= _depth or voxel.z < 0 or voxel.z >= _height_levels:
			result["has_los"] = false
			return result

		var current_tile = get_tile(voxel)
		if current_tile:
			if current_tile.prop_id != -1:
				result["has_los"] = false
				result["intercepting_prop_id"] = current_tile.prop_id
				return result

			# Z1 Parapet Cover Check for intermediate tiles?
			# Usually, only the target tile's cover provides cover, or full solid props block.
			# If an intermediate tile is solid, it blocks LOS. (e.g. Z1 solid block while ray is on Z1)
			# But discrete tile occlusion wasn't strictly asked for besides props and target parapet cover.
			# Let's assume height differences naturally block.
			# Actually, if we are tracing through (x, y, 1) and the tile has height_offset 3.0, it's air.
			# Wait, how do we block LOS if we trace through a Z1 tile that is solid ground?
			# In a 12x12x2 grid, Z1 tiles that aren't air should probably block LOS if the ray goes through them.
			# A missing Z1 tile (null) or a Z1 tile with a specific property?
			pass

	# We reached the target. Now evaluate cover on the target tile.
	var target_tile = get_tile(target)
	if target_tile and target_tile.cover_type != TileSpatialNodeResource.CoverType.NONE:
		var incoming_vector = Vector2i(
			1 if origin.x > target.x else (-1 if origin.x < target.x else 0),
			1 if origin.y > target.y else (-1 if origin.y < target.y else 0)
		)

		# For point-blank range we bypassed earlier, so this is > 1 step away.
		# A parapet only protects if the incoming vector matches the cover's cardinal vector.
		# A dot product > 0 means the vectors are pointing in roughly the same direction.
		# Wait, if attacker is North of target (y < target.y), incoming_vector is (0, -1).
		# If the cover is on the North side of the tile, its cover_cardinal_vector should be (0, -1) to face North.
		# The incoming vector from attacker to target: Target is (0, 1), Origin is (0, 0).
		# origin.y (0) - target.y (1) = -1. incoming_vector y is -1.
		# So incoming_vector == cover_cardinal_vector.
		var dot_prod = incoming_vector.x * target_tile.cover_cardinal_vector.x + incoming_vector.y * target_tile.cover_cardinal_vector.y
		if dot_prod > 0:
			result["cover_level"] = target_tile.cover_type
			result["damage_mitigation_pct"] = target_tile.damage_reduction_pct

	return result

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

	# Log deflection if hardness is insufficient (could be a print or signal in the future)
	return false

func collapse_prop(prop_id: int) -> void:
	var prop = get_prop(prop_id)
	if not prop:
		return

	prop.current_degradation_state = MultiStagePropResource.DegradationState.RUBBLE

	var tile = get_tile(prop.grid_position)
	if tile:
		tile.base_traversal_cost = 2.0
		# Clear LOS occlusion by removing the prop reference from the tile blocking vision
		tile.prop_id = -1
		EventBus.navmesh_dirty.emit(prop.grid_position)

	destroy_elevated_tiles(prop.attached_elevated_tile_coords)
	EventBus.prop_state_changed.emit(prop_id, prop.current_degradation_state)

func destroy_elevated_tiles(tile_coords: Array[Vector3i]) -> void:
	for coord in tile_coords:
		var tile = get_tile(coord)
		if tile:
			# Mark as destroyed/impassable
			tile.base_traversal_cost = INF
			tile.cardinal_traversal_mask = 0
			tile.vertical_connector_type = TileSpatialNodeResource.VerticalConnectorType.NONE

			# If a unit was occupying, they would fall to Z0.
			# We leave the logic for unit state change to SimulationServer,
			# but we notify that the navmesh changed.
			EventBus.navmesh_dirty.emit(coord)
