extends Node2D

var target_node: Node2D
var damage: int
var speed: float = 400.0

func setup(_target: Node2D, _damage: int):
	target_node = _target
	damage = _damage

func _ready():
	if not target_node:
		queue_free()
		return

	var distance = global_position.distance_to(target_node.global_position)
	var travel_time = distance / speed

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_node.global_position, travel_time)
	tween.tween_callback(self._on_arrival)

func _on_arrival():
	if is_instance_valid(target_node) and target_node.has_method("take_damage"):
		target_node.take_damage(damage)
	queue_free()
