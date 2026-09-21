class_name TargetDepotResolver
extends RefCounted

func resolve_best_supply(pawn_coord: Vector2i, resource_type: StringName, min_amount: int, depots: Array[Dictionary], reservation_reg: Object, resource_reg: Object, pawn_id: int) -> Dictionary:
	var best_depot: Dictionary = {}
	var best_dist: int = -1

	for depot in depots:
		if depot.get("type", &"") != &"SUPPLY":
			continue

		var depot_id: int = depot.get("id", 0)
		var claimant = reservation_reg.get_claimant(depot_id)

		# Allow if no claimant (0) or if this pawn is already the claimant
		if claimant != 0 and claimant != pawn_id:
			continue

		var balance = resource_reg.get_balance(depot_id, resource_type)
		if balance < min_amount:
			continue

		var depot_coord: Vector2i = depot.get("coord", Vector2i(-1, -1))
		var dx: int = abs(pawn_coord.x - depot_coord.x)
		var dy: int = abs(pawn_coord.y - depot_coord.y)
		var dist: int = dx + dy

		if best_dist == -1 or dist < best_dist:
			best_dist = dist
			best_depot = depot

	return best_depot

func resolve_best_demand(pawn_coord: Vector2i, depots: Array[Dictionary], reservation_reg: Object, pawn_id: int) -> Dictionary:
	var best_depot: Dictionary = {}
	var best_dist: int = -1

	for depot in depots:
		if depot.get("type", &"") != &"DEMAND":
			continue

		var depot_id: int = depot.get("id", 0)
		var claimant = reservation_reg.get_claimant(depot_id)

		if claimant != 0 and claimant != pawn_id:
			continue

		var depot_coord: Vector2i = depot.get("coord", Vector2i(-1, -1))
		var dx: int = abs(pawn_coord.x - depot_coord.x)
		var dy: int = abs(pawn_coord.y - depot_coord.y)
		var dist: int = dx + dy

		if best_dist == -1 or dist < best_dist:
			best_dist = dist
			best_depot = depot

	return best_depot
