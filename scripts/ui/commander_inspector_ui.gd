class_name CommanderInspectorUI extends Control

var unit_card_scene: PackedScene = preload("res://scenes/ui/unit_card_prefab.tscn")
var card_instance: Control = null

var draft_directives: Dictionary = {} # Dictionary[int, StringName]
var ai_templates: Dictionary = {}
var current_phase: int = 0
var current_tick: int = 0
var current_replay_buffer: TurnReplayBufferResource = null
var selected_unit_id: int = -1
var master_units: Dictionary = {}

@onready var container = self

func _ready() -> void:
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.scrubber_tick_changed.connect(_on_scrubber_tick_changed)
	EventBus.turn_simulation_completed.connect(_on_turn_simulation_completed)
	_load_ai_templates()

	# Instantiate the single card
	card_instance = unit_card_scene.instantiate()
	container.add_child(card_instance)
	card_instance.visible = false

	var dropdown = card_instance.get_node("TemplateDropdown") as OptionButton
	dropdown.item_selected.connect(_on_dropdown_item_selected)

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
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access the path.")

func set_master_units(units_dict: Dictionary) -> void:
	master_units = units_dict

func _on_unit_selected(unit_id: int) -> void:
	selected_unit_id = unit_id
	if not master_units.has(unit_id):
		card_instance.visible = false
		return

	var unit = master_units[unit_id] as UnitDataResource
	card_instance.visible = true

	var name_label = card_instance.get_node("NameLabel") as Label
	var hp_bar = card_instance.get_node("HPBar") as ProgressBar
	var stress_bar = card_instance.get_node("StressBar") as ProgressBar
	var dropdown = card_instance.get_node("TemplateDropdown") as OptionButton

	# Explicitly reset visual states
	name_label.text = ""
	hp_bar.value = 0
	hp_bar.max_value = 1
	stress_bar.value = 0
	stress_bar.max_value = 1
	dropdown.clear()
	dropdown.disabled = false
	dropdown.text = ""

	# Populate with initial data from UnitDataResource
	name_label.text = unit.unit_name

	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp

	stress_bar.max_value = unit.bravery_rating * unit.loyalty_rating
	if stress_bar.max_value <= 0:
		stress_bar.max_value = 100
	stress_bar.value = unit.current_stress

	if unit.faction_id == 0:
		dropdown.visible = true
		if unit.is_order_fractured:
			dropdown.disabled = true
			dropdown.text = "FRACTURED"
		else:
			for template_id in ai_templates.keys():
				var tpl = ai_templates[template_id]
				dropdown.add_item(tpl.display_name)
				dropdown.set_item_metadata(dropdown.item_count - 1, template_id)

			var target_template = draft_directives.get(unit_id, unit.active_template_id)
			for i in range(dropdown.item_count):
				if dropdown.get_item_metadata(i) == target_template:
					dropdown.select(i)
					break

			if current_phase != 0:
				dropdown.disabled = true
	else:
		# Enemy unit
		dropdown.visible = false

	# If we are in playback, sync bars to current tick
	if current_phase == 2 and current_replay_buffer != null:
		_sync_playback_state(current_tick)

func _on_dropdown_item_selected(index: int) -> void:
	if selected_unit_id != -1:
		var dropdown = card_instance.get_node("TemplateDropdown") as OptionButton
		var template_id = dropdown.get_item_metadata(index)
		draft_directives[selected_unit_id] = template_id

func _on_phase_changed(phase: int) -> void:
	current_phase = phase
	if phase == 0:
		# Planning
		draft_directives.clear()

		# Refresh UI if we have a selected unit
		if selected_unit_id != -1:
			_on_unit_selected(selected_unit_id)
	else:
		# Lock dropdown
		var dropdown = card_instance.get_node("TemplateDropdown") as OptionButton
		dropdown.disabled = true

func _on_turn_simulation_completed(replay_buffer: TurnReplayBufferResource) -> void:
	current_replay_buffer = replay_buffer

func _on_scrubber_tick_changed(target_tick: int) -> void:
	current_tick = target_tick
	if current_phase == 2 and card_instance.visible and selected_unit_id != -1:
		_sync_playback_state(target_tick)

func _sync_playback_state(tick: int) -> void:
	if not current_replay_buffer or tick < 0 or tick >= current_replay_buffer.tick_snapshots.size():
		return

	var snapshot = current_replay_buffer.tick_snapshots[tick]
	var hp = snapshot.unit_hp_states.get(selected_unit_id, 0.0)
	var stress = snapshot.unit_stress_states.get(selected_unit_id, 0.0)

	var hp_bar = card_instance.get_node("HPBar") as ProgressBar
	var stress_bar = card_instance.get_node("StressBar") as ProgressBar

	hp_bar.value = hp
	stress_bar.value = stress

func get_draft_template(unit_id: int) -> StringName:
	return draft_directives.get(unit_id, &"")
