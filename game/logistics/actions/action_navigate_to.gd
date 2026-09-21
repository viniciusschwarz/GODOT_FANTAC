class_name ActionNavigateTo
extends GoapAction

func _init():
	action_name = &"NavigateTo"
	# Effect: pawn is at the target
	effects.append(GoapSymbolicEffect.new(&"pawn_at_target", GoapTypes.SymbolicEffectOp.ASSIGN, true))

func on_enter(binding: GoapActionBinding, context: Dictionary) -> void:
	pass

func on_step(tick: int, binding: GoapActionBinding, context: Dictionary, cmd_bus: Object = null) -> int:
	var target_coord: Vector2i = binding.get_param(&"target_coord", Vector2i(-1, -1))
	if target_coord == Vector2i(-1, -1) and context.has("target_depot"):
		target_coord = context["target_depot"].get("coord", Vector2i(-1, -1))

	var current_coord: Vector2i = context.get("pawn_coord", Vector2i(-1, -1))
	if target_coord == Vector2i(-1, -1) or current_coord == -Vector2i.ONE:
		return GoapTypes.ActionStatus.FAILED

	if current_coord == target_coord:
		return GoapTypes.ActionStatus.COMPLETED

	var dx: int = target_coord.x - current_coord.x
	var dy: int = target_coord.y - current_coord.y
	var next_step: Vector2i = current_coord

	if dx != 0:
		next_step.x += signi(dx)
	elif dy != 0:
		next_step.y += signi(dy)

	if cmd_bus != null:
		cmd_bus.submit({
			"command_id": 1,
			"priority": CoreEnums.ExecutionPriority.INPUT_DIRECT,
			"command_type": &"SPATIAL_RELOCATION",
			"issuer_id": context.get("pawn_id", 0),
			"target_tick": tick,
			"payload": {
				"from_coord": current_coord,
				"to_coord": next_step
			}
		})

	context["pawn_coord"] = next_step

	if next_step == target_coord:
		return GoapTypes.ActionStatus.COMPLETED
	else:
		return GoapTypes.ActionStatus.RUNNING

