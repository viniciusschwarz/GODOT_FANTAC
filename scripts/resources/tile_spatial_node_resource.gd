class_name TileSpatialNodeResource extends Resource

enum VerticalConnectorType { NONE, STAIRS_N, STAIRS_S, STAIRS_E, STAIRS_W }
enum CoverType { NONE, LOW_RAILING, WINDOW_FRAME, SOLID_PARAPET }

@export var grid_position: Vector3i = Vector3i.ZERO
@export var height_offset_meters: float = 0.0
@export var base_traversal_cost: float = 1.0

@export var vertical_connector_type: VerticalConnectorType = VerticalConnectorType.NONE
@export var cardinal_traversal_mask: int = 15 # e.g. Bitmask 1111 (N, S, E, W)

@export var cover_type: CoverType = CoverType.NONE
@export var cover_cardinal_vector: Vector2i = Vector2i.ZERO
@export var damage_reduction_pct: float = 0.0

@export var occupying_unit_id: int = -1
@export var reserved_unit_id: int = -1
@export var reservation_micro_tick: int = -1
