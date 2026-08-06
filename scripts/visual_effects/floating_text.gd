extends Label
## Basic floating text effect that animates upward, fades out, and frees itself.

@export var float_distance: float = 30.0
@export var duration: float = 1.0

func _ready() -> void:
	var tween: Tween = create_tween().set_parallel(true)

	# Float up
	tween.tween_property(self, "position", position - Vector2(0, float_distance), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_LINEAR)

	# Wait and free
	tween.chain().tween_callback(queue_free)
