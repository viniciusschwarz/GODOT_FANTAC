extends Node2D

## FX MANAGER
## This Autoload listens to the global SignalBus and spawns visual effects without interrupting game logic.

const FLOATING_TEXT_SCENE = preload("res://scenes/visual_effects/floating_text.tscn")

func _ready() -> void:
	if SignalBus:
		SignalBus.unit_health_changed.connect(_on_unit_health_changed)

func _on_unit_health_changed(unit: Node, current_health: int, max_health: int, amount: int) -> void:
	if amount == 0:
		return

	var text_instance = FLOATING_TEXT_SCENE.instantiate()

	if amount < 0:
		text_instance.text = str(abs(amount))
		text_instance.modulate = Color.RED
	else:
		text_instance.text = "+" + str(amount)
		text_instance.modulate = Color.GREEN

	if unit.has_method("get_global_position") or unit is Node2D:
		text_instance.global_position = unit.global_position
	add_child(text_instance)

	var tween = get_tree().create_tween()
	tween.tween_property(text_instance, "global_position", text_instance.global_position - Vector2(0, 50), 1.0)
	tween.parallel().tween_property(text_instance, "modulate:a", 0.0, 1.0)
	tween.tween_callback(text_instance.queue_free)
