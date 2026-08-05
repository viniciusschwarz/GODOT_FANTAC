extends CanvasLayer
## Tactical Visualizer
## A standalone UI overlay toggled via a debug key (F3).
## Visualizes AI intent lines and states during combat.

var is_visible: bool = false
var lines: Array[Line2D] = []
var labels: Array[Label] = []

@export var debug_key: Key = KEY_F3

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == debug_key:
		toggle_visualizer()

func toggle_visualizer() -> void:
	is_visible = !is_visible
	visible = is_visible
	if is_visible:
		set_process(true)
	else:
		set_process(false)
		clear_visuals()

func _process(_delta: float) -> void:
	if not is_visible:
		return

	clear_visuals()

	# Fetch all AI units to draw their state and paths
	# This requires AIManager to have a list of units or we get all units in the scene
	var ai_manager = get_node_or_null("/root/AIManager")
	if ai_manager and ai_manager.active_units:
		for unit in ai_manager.active_units:
			if not is_instance_valid(unit) or not unit.ai_component:
				continue

			# Draw State Label
			var state_text = "Idle"
			if unit.ai_component.queued_action:
				state_text = unit.ai_component.queued_action.name

			var label = Label.new()
			label.text = state_text
			label.position = unit.global_position + Vector2(-20, 20)
			label.add_theme_color_override("font_color", Color.YELLOW)
			add_child(label)
			labels.append(label)

			# Draw Intent Line (Example: line to target if moving/attacking)
			# Assuming a basic intent vector or target in ai_component (to be expanded)
			# For now, just a placeholder line extending from unit if they have an action
			if unit.ai_component.queued_action:
				var line = Line2D.new()
				line.add_point(unit.global_position)
				line.add_point(unit.global_position + unit.facing_vector * 50) # Placeholder intent point
				line.width = 2.0
				line.default_color = Color.CYAN
				add_child(line)
				lines.append(line)

func clear_visuals() -> void:
	for line in lines:
		if is_instance_valid(line):
			line.queue_free()
	lines.clear()

	for label in labels:
		if is_instance_valid(label):
			label.queue_free()
	labels.clear()
