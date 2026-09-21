class_name ActionClaimDepot
extends GoapAction

func _init():
	action_name = &"ClaimDepot"
	preconditions.append(GoapSymbolicRule.new(&"pawn_at_target", true))
	effects.append(GoapSymbolicEffect.new(&"has_depot_claim", GoapTypes.SymbolicEffectOp.ASSIGN, true))

func on_step(tick: int, binding: GoapActionBinding, context: Dictionary, cmd_bus: Object = null) -> int:
	var depot_id = binding.get_param(&"depot_id")
	var claim_duration = binding.get_param(&"claim_duration", 20)
	var pawn_id = context.get("pawn_id", 0)

	if cmd_bus != null:
		cmd_bus.submit({
			"command_type": &"RESERVATION_CLAIM",
			"issuer_entity_id": pawn_id,
			"tick_timestamp": tick,
			"command_payload": {
				"claimant_id": pawn_id,
				"target_id": depot_id,
				"claim_type": 1,
				"duration": claim_duration
			}
		})

	return GoapTypes.ActionStatus.COMPLETED
