extends Node2D

var target_position: Vector2 = Vector2.ZERO
var speed: float = 400.0
var aoe_radius: int = 0
@onready var sprite = $Sprite2D

func setup(destination: Vector2, radius: int = 0):
	target_position = destination
	aoe_radius = radius

func _ready():
	var distance = global_position.distance_to(target_position)
	var travel_time = distance / speed

	var tween = create_tween()
	# Move the visual icon towards the target destination
	tween.tween_property(self, "global_position", target_position, travel_time)
	
	# If it's an AoE spell, expand the sprite's scale while it travels
	if aoe_radius > 0:
		var target_scale = Vector2(1.0, 1.0) * (float(aoe_radius * 2 + 1) * 64.0 / sprite.texture.get_width())
		tween.parallel().tween_property(sprite, "scale", target_scale, travel_time)

	# Once the animation reaches the destination, delete the visual projectile node
	tween.tween_callback(queue_free)
