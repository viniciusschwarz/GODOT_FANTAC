class_name TickSnapshotData extends Resource

@export var micro_tick_index: int = 0

@export var unit_transform_states: Dictionary = {}
@export var unit_hp_states: Dictionary = {}
@export var unit_stress_states: Dictionary = {}
@export var unit_animation_states: Dictionary = {}
@export var prop_states: Dictionary = {}

@export var active_projectiles: Array[Dictionary] = []
@export var telemetry_events: Array[Dictionary] = []
