class_name AnimationComponent
extends Node
## Manages the visual state (sprite animations and shader effects) of a unit.

@export var sprite: Sprite2D
@export var hit_flash_duration: float = 0.1

var is_hit_flashing: bool = false
var hit_flash_timer: float = 0.0

var current_state: String = "Idle"
var unit_owner: Node

func _ready() -> void:
	if SignalBus:
		SignalBus.unit_health_changed.connect(_on_unit_health_changed)
		SignalBus.unit_died.connect(_on_unit_died)

func initialize(unit: Node) -> void:
	unit_owner = unit

func _process(delta: float) -> void:
	_process_hit_flash(delta)

func _process_hit_flash(delta: float) -> void:
	if is_hit_flashing:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0:
			is_hit_flashing = false
			if sprite and sprite.material:
				sprite.material.set_shader_parameter("hit", false)

func play_animation(anim_name: String) -> void:
	current_state = anim_name
	# Placeholder for actual animation player or animated sprite
	# e.g., if animation_player: animation_player.play(anim_name)
	pass

func update_facing(facing_vector: Vector2) -> void:
	if sprite:
		if facing_vector.x < 0:
			sprite.flip_h = true
		elif facing_vector.x > 0:
			sprite.flip_h = false

func _on_unit_health_changed(unit: Node, current_health: int, max_health: int, amount: int) -> void:
	if unit == unit_owner and amount < 0:
		_trigger_hit_flash()
		play_animation("Hurt")

func _on_unit_died(unit: Node) -> void:
	if unit == unit_owner:
		play_animation("Die")

func _trigger_hit_flash() -> void:
	if sprite and sprite.material:
		is_hit_flashing = true
		hit_flash_timer = hit_flash_duration
		sprite.material.set_shader_parameter("hit", true)
