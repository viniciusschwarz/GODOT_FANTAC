class_name UIManager extends CanvasLayer

@onready var playback_slider: HSlider = $BottomPanel/HBoxContainer/PlaybackSlider
@onready var play_pause_button: Button = $BottomPanel/HBoxContainer/PlayPauseButton
@onready var directive_dropdown: OptionButton = $SidePanel/DirectiveDropdown
@onready var telemetry_badge: FloatingTelemetryBadge = $FloatingTelemetryBadge

var is_playing: bool = false
var playback_speed_multiplier: float = 1.0
var accumulated_playback_time: float = 0.0
var current_tick: int = 0

var selected_unit_id: int = -1
var current_replay_buffer: TurnReplayBufferResource = null
var ai_templates: Dictionary = {} # StringName -> AITemplateResource
var roster: Array[UnitDataResource] = [] # Given we need to mutate unit data in planning phase

func _ready() -> void:
	EventBus.scrubber_tick_changed.connect(_on_scrubber_tick_changed)
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.turn_simulation_completed.connect(_on_turn_simulation_completed)
	EventBus.phase_changed.connect(_on_phase_changed)

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	playback_slider.value_changed.connect(_on_slider_value_changed)
	directive_dropdown.item_selected.connect(_on_directive_selected)

	_load_ai_templates()

func _load_ai_templates() -> void:
	var path = "res://data/ai_templates/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = ResourceLoader.load(path + file_name) as AITemplateResource
				if res:
					ai_templates[res.template_id] = res
					directive_dropdown.add_item(res.display_name)
					directive_dropdown.set_item_metadata(directive_dropdown.item_count - 1, res.template_id)
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access the path.")

func set_roster(units: Array[UnitDataResource]) -> void:
	roster = units

func _on_turn_simulation_completed(replay_buffer: TurnReplayBufferResource) -> void:
	current_replay_buffer = replay_buffer
	_update_telemetry_badge()

func _on_phase_changed(new_phase: int) -> void:
	# 0=Planning, 1=Simulating, 2=Playback
	if new_phase == 0:
		directive_dropdown.disabled = false
	elif new_phase == 2:
		directive_dropdown.disabled = true

func _on_play_pause_pressed() -> void:
	is_playing = !is_playing
	if is_playing:
		play_pause_button.text = "Pause"
		if current_tick >= 99:
			current_tick = 0
			accumulated_playback_time = 0.0
			playback_slider.value = 0
	else:
		play_pause_button.text = "Play"
	EventBus.playback_state_changed.emit(is_playing, playback_speed_multiplier)

func _on_slider_value_changed(value: float) -> void:
	var new_tick = int(value)
	if new_tick != current_tick:
		current_tick = new_tick
		accumulated_playback_time = float(current_tick)
		EventBus.scrubber_tick_changed.emit(current_tick)

func _on_scrubber_tick_changed(target_tick: int) -> void:
	if target_tick != current_tick:
		current_tick = target_tick
		playback_slider.set_value_no_signal(current_tick)
	_update_telemetry_badge()

func _on_unit_selected(unit_id: int) -> void:
	selected_unit_id = unit_id

	if unit_id != -1:
		# Update dropdown to reflect selected unit's template
		var unit = _get_unit(unit_id)
		if unit:
			var template_id = unit.active_template_id
			for i in range(directive_dropdown.item_count):
				if directive_dropdown.get_item_metadata(i) == template_id:
					directive_dropdown.select(i)
					break
	else:
		directive_dropdown.select(-1)

	_update_telemetry_badge()

func _get_unit(unit_id: int) -> UnitDataResource:
	for unit in roster:
		if unit.unit_id == unit_id:
			return unit
	return null

func _on_directive_selected(index: int) -> void:
	if selected_unit_id == -1:
		return

	var unit = _get_unit(selected_unit_id)
	if unit:
		var template_id = directive_dropdown.get_item_metadata(index)
		unit.active_template_id = template_id

func _update_telemetry_badge() -> void:
	if selected_unit_id == -1 or current_replay_buffer == null or current_replay_buffer.tick_snapshots.is_empty():
		telemetry_badge.update_badge(-1, Vector3i.ZERO, "")
		return

	if current_tick < 0 or current_tick >= current_replay_buffer.tick_snapshots.size():
		return

	# Get unit's coordinate at current tick
	var snapshot = current_replay_buffer.tick_snapshots[current_tick]
	var coord = snapshot.unit_transform_states.get(selected_unit_id, Vector3i.ZERO)

	if not snapshot.unit_transform_states.has(selected_unit_id):
		telemetry_badge.update_badge(-1, Vector3i.ZERO, "")
		return

	# Find most recent telemetry msg
	var latest_msg = ""
	for t in range(current_tick, -1, -1):
		var check_snap = current_replay_buffer.tick_snapshots[t]
		for event in check_snap.telemetry_events:
			# telemetry_events are dictionaries with {"tick": int, "msg": String} as implemented in simulation_server.gd.
			# But prompt specifies "unit_id == selected_unit_id and major_event_flag == true" and "telemetry_text"
			# We'll check via .get() which is safe for dictionaries.
			if typeof(event) == TYPE_DICTIONARY:
				if event.get("unit_id", -1) == selected_unit_id and event.get("major_event_flag", false) == true:
					latest_msg = event.get("telemetry_text", "")
					break
			else:
				# If it's an object/resource, we can use standard property access if the properties exist.
				# Using `in` keyword to safely check if property exists before accessing.
				if "unit_id" in event and "major_event_flag" in event and "telemetry_text" in event:
					if event.unit_id == selected_unit_id and event.major_event_flag == true:
						latest_msg = event.telemetry_text
						break
		if latest_msg != "":
			break

	telemetry_badge.update_badge(selected_unit_id, coord, latest_msg)

func _process(delta: float) -> void:
	if is_playing:
		accumulated_playback_time += delta * 20.0 * playback_speed_multiplier
		var target_tick = int(accumulated_playback_time)

		if target_tick >= 100:
			target_tick = 99
			is_playing = false
			play_pause_button.text = "Play"

		if target_tick != current_tick:
			current_tick = target_tick
			playback_slider.set_value_no_signal(current_tick)
			EventBus.scrubber_tick_changed.emit(current_tick)
