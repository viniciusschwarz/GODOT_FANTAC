extends Node2D

# We expose the speed and distance so you can easily tweak the animation later
@export var float_speed: float = 0.8
@export var float_distance: float = 40.0

@onready var label = $Label

# We use this single function to set the text AND trigger the animation!
func set_damage_value(amount: int):
	# Make sure the node is fully loaded in the tree
	if not is_node_ready():
		await ready
	
	# 1. Set the text
	label.text = str(amount)
	
	# 2. Create a Tween (Godot's built-in animation engine)
	var tween = create_tween()
	
	# 3. We want the floating and fading to happen at the same time!
	tween.set_parallel(true)
	
	# 4. Animate the Y position moving UP
	# Because this runs AFTER Main.gd sets the position, it starts in the right place!
	var target_position = position.y - float_distance
	tween.tween_property(self, "position:y", target_position, float_speed)
	
	# 5. Animate the transparency fading out
	tween.tween_property(self, "modulate:a", 0.0, float_speed)
	
	# 6. Stop parallel execution and delete the node when finished
	tween.set_parallel(false) 
	tween.tween_callback(queue_free)
