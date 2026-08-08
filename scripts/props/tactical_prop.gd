class_name TacticalProp extends Node2D

@export var prop_data: MultiStagePropResource

func _ready() -> void:
	if not prop_data:
		push_warning("TacticalProp requires a MultiStagePropResource assigned to prop_data.")
		return

	# Register to listen for state changes from the EventBus
	EventBus.prop_state_changed.connect(_on_prop_state_changed)

	# Initial visual update based on current state
	_update_visual_state(prop_data.current_degradation_state)

func _on_prop_state_changed(changed_prop_id: int, new_state: int) -> void:
	if changed_prop_id == prop_data.prop_id:
		_update_visual_state(new_state)

func _update_visual_state(state: int) -> void:
	# Here we would swap sprites, play animations or particle effects
	# For example, changing to a rubble texture if state == RUBBLE
	if state == MultiStagePropResource.DegradationState.RUBBLE:
		# Play collapse animation/effects
		# $Sprite2D.texture = load("res://assets/sprites/rubble.png")
		pass
	elif state == MultiStagePropResource.DegradationState.INTACT:
		# $Sprite2D.texture = load("res://assets/sprites/intact_gate.png")
		pass
