class_name ActionReleaseDepot
extends GoapAction

func _init():
	action_name = &"ReleaseDepot"
	preconditions.append(GoapSymbolicRule.new(&"has_depot_claim", true))
	effects.append(GoapSymbolicEffect.new(&"has_depot_claim", GoapTypes.SymbolicEffectOp.ASSIGN, false))

func on_step(tick: int, binding: GoapActionBinding, context: Dictionary, cmd_bus: Object = null) -> int:
	var depot_id = binding.get_param(&"depot_id")
	if depot_id == null:
		var target_depot = context.get("target_depot", {})
		depot_id = target_depot.get("id", 0)
	var pawn_id = context.get("pawn_id", 0)

	if cmd_bus != null:
		cmd_bus.submit({
			"command_id": 1,
			"priority": CoreEnums.ExecutionPriority.INPUT_DIRECT,
			"command_type": &"RESERVATION_RELEASE",
			"issuer_id": pawn_id,
			"target_tick": tick,
			"payload": {
				"claimant_id": pawn_id,
				"target_id": depot_id
			}
		})

	return GoapTypes.ActionStatus.COMPLETED
