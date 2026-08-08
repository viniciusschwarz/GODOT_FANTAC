class_name BattlefieldView extends Node2D

const TILE_SIZE: int = 64
const Z1_VISUAL_Y_OFFSET: float = -12.0

@onready var ground_layer_z0 = $GroundLayerZ0
@onready var rampart_layer_z1 = $RampartLayerZ1
@onready var tokens_container = $TokensContainer

var unit_token_scene: PackedScene = preload("res://scenes/view/unit_token_view.tscn")
var unit_tokens: Dictionary = {} # Dictionary[int, UnitTokenView]

var current_replay_buffer: TurnReplayBufferResource = null

func _ready() -> void:
	EventBus.scrubber_tick_changed.connect(_on_scrubber_tick_changed)
	EventBus.turn_simulation_completed.connect(_on_turn_simulation_completed)

func _on_turn_simulation_completed(replay_buffer: TurnReplayBufferResource) -> void:
	current_replay_buffer = replay_buffer
	_initialize_tokens_from_buffer(replay_buffer)

func _initialize_tokens_from_buffer(replay_buffer: TurnReplayBufferResource) -> void:
	# Clear existing tokens
	for token in unit_tokens.values():
		token.queue_free()
	unit_tokens.clear()

	if replay_buffer.tick_snapshots.is_empty():
		return

	# Assume Tick 0 has all units for instantiation (in a real scenario, you'd get the roster details from GameState/BattlefieldManager)
	var initial_snapshot = replay_buffer.tick_snapshots[0]

	for unit_id in initial_snapshot.unit_transform_states.keys():
		var token: UnitTokenView = unit_token_scene.instantiate()
		tokens_container.add_child(token)

		# Here we assume faction=0 and max_hp=100 as fallback. Real implementation should fetch from UnitDataResource roster.
		token.setup(unit_id as int, 0, 100.0)
		unit_tokens[unit_id] = token

	# Apply tick 0 state
	_on_scrubber_tick_changed(0)

func _on_scrubber_tick_changed(target_tick: int) -> void:
	if not current_replay_buffer or target_tick < 0 or target_tick >= current_replay_buffer.tick_snapshots.size():
		return

	var snapshot = current_replay_buffer.tick_snapshots[target_tick]

	for unit_id in unit_tokens.keys():
		var token: UnitTokenView = unit_tokens[unit_id]

		if unit_id in snapshot.unit_transform_states:
			token.visible = true
			var coord: Vector3i = snapshot.unit_transform_states[unit_id]
			var hp: float = snapshot.unit_hp_states.get(unit_id, 0.0)
			token.update_state(coord, hp)
		else:
			token.visible = false
