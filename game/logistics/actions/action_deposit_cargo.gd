class_name ActionDepositCargo
extends GoapAction

func _init():
	action_name = &"DepositCargo"
	preconditions.append(GoapSymbolicRule.new(&"pawn_at_target", true))
	preconditions.append(GoapSymbolicRule.new(&"has_depot_claim", true))

	effects.append(GoapNumericEffect.new(&"cargo_balance", GoapTypes.NumericEffectOp.ASSIGN, 0.0))
	effects.append(GoapSymbolicEffect.new(&"cargo_delivered", GoapTypes.SymbolicEffectOp.ASSIGN, true))

func on_step(tick: int, binding: GoapActionBinding, context: Dictionary, cmd_bus: Object = null) -> int:
	var depot_id = binding.get_param(&"depot_id")
	if depot_id == null:
		var target_depot = context.get("target_depot", {})
		depot_id = target_depot.get("id", 0)

	var resource_type = binding.get_param(&"resource_type")
	if resource_type == null:
		var target_depot = context.get("target_depot", {})
		resource_type = target_depot.get("resource_type", &"wood")

	var amount = binding.get_param(&"amount")
	if amount == null:
		amount = 10
	var pawn_id = context.get("pawn_id", 0)
	var pawn_container_id = context.get("pawn_container_id", 0)

	if cmd_bus != null:
		cmd_bus.submit({
			"command_type": &"RESOURCE_TRANSFER",
			"issuer_entity_id": pawn_id,
			"tick_timestamp": tick,
			"command_payload": {
				"source_id": pawn_container_id,
				"destination_id": depot_id,
				"resource_type": resource_type,
				"amount": amount
			}
		})

	return GoapTypes.ActionStatus.COMPLETED
