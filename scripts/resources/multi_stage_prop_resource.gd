class_name MultiStagePropResource extends Resource

enum DegradationState { INTACT, RUBBLE }

@export var prop_id: int = -1
@export var grid_position: Vector3i = Vector3i.ZERO
@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var material_hardness_threshold: float = 0.0

@export var current_degradation_state: DegradationState = DegradationState.INTACT
@export var attached_elevated_tile_coords: Array[Vector3i] = []
