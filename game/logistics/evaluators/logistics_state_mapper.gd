class_name LogisticsStateMapper
extends RefCounted

static func build_snapshot(pawn_id: int, pawn_coord: Vector2i, pawn_container_id: int, resource_reg: Object, reservation_reg: Object, target_depot_info: Dictionary) -> GoapStateSnapshot:
	var snapshot = GoapStateSnapshot.new()

	# Set numbers
	var balance: int = resource_reg.get_balance(pawn_container_id, &"wood")
	snapshot.set_number(&"cargo_balance", float(balance))

	# Ensure target_depot_info matches the active phase (Supply when cargo == 0, Demand when cargo > 0)
	var expected_type = &"SUPPLY" if balance == 0 else &"DEMAND"
	var depot_type = target_depot_info.get("type", &"")

	# Set symbols
	var depot_coord: Vector2i = target_depot_info.get("coord", Vector2i(-1, -1))
	var pawn_at_target: bool = false
	if not target_depot_info.is_empty() and pawn_coord == depot_coord and depot_type == expected_type:
		pawn_at_target = true
	snapshot.set_symbol(&"pawn_at_target", pawn_at_target)

	var depot_id: int = target_depot_info.get("id", 0)
	var has_claim: bool = false
	if depot_id != 0 and reservation_reg.get_claimant(depot_id) == pawn_id:
		has_claim = true
	snapshot.set_symbol(&"has_depot_claim", has_claim)

	return snapshot
