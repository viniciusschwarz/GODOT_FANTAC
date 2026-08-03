extends Node2D

# We expose the speed and distance so you can easily tweak the animation later
@export var float_speed: float = 5.0
@export var float_distance: float = 15.0

@onready var label = $Label

# We create a function to set the text value from the outside
func set_damage_value(amount: int):
	# Make sure the nodes are loaded before trying to change the text
	if not is_node_ready():
		await ready
	
	label.text = str(amount)

func _ready():
	# 1. Create a Tween (Godot's built-in animation engine)
	var tween = create_tween()
	
	# 2. We want the floating and fading to happen at the same time!
	# .set_parallel(true) tells the tween to run the next commands simultaneously.
	tween.set_parallel(true)
	
	# 3. Animate the Y position moving UP
	var target_position = position.y - float_distance
	tween.tween_property(self, "position:y", target_position, float_speed)
	
	# 4. Animate the transparency fading out. 
	# 'modulate:a' targets the Alpha channel (opacity). 0.0 means completely invisible.
	tween.tween_property(self, "modulate:a", 0.0, float_speed)
	
	# 5. Tell the tween that when everything is finished, it should run another command
	tween.set_parallel(false) # Stop parallel execution
	tween.tween_callback(queue_free) # Delete this node from the game to save memory
