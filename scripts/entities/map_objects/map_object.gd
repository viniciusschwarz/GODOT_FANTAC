class_name MapObject
extends Node2D

@export var data: MapObjectData

# Visual representation
@onready var color_rect: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var label: Label = $Label if has_node("Label") else null

func _ready() -> void:
	if not data:
		# Create a default data instance if none is assigned
		data = MapObjectData.new()

	if color_rect:
		# Give a slight offset based on intended height/cover
		if data.los_block_height > 0:
			color_rect.position.y -= data.los_block_height * 32.0 # Visual indicator for height

	if label:
		label.text = data.object_name
