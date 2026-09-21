class_name CourierSensorEvaluator
extends RefCounted

static func evaluate_blackboard(
	worker_entity_id: int,
	worker_container_id: int,
	worker_coord: Vector2i,
	depot_records: Array[Dictionary], # [{ "id": int, "container_id": int, "coord": Vector2i, "type": &"SUPPLY"|"DEMAND", "demand_needed": int }]
	spatial_reg: SpatialCellRegistry,
	resource_reg: ResourceContainerRegistry,
	reservation_reg: ReservationRegistry
) -> Dictionary:
	var blackboard: Dictionary = {}

	# 1. Evaluate Worker Inventory
	var carried_wood: int = resource_reg.get_balance(worker_container_id, &"WOOD")
	blackboard["carried_wood"] = carried_wood
	blackboard["is_carrying_wood"] = carried_wood > 0
	blackboard["worker_coord"] = worker_coord

	# 2. Identify nearest valid unreserved supply depot with wood
	var nearest_supply_id: int = -1
	var nearest_supply_dist: int = 999999
	var nearest_supply_coord: Vector2i = Vector2i(-1, -1)

	for depot in depot_records:
		if depot["type"] == &"SUPPLY":
			var is_reserved = reservation_reg.is_reserved(depot["id"])
			# Check if we own the reservation
			var owns_reservation = false
			if is_reserved and reservation_reg.get_claimant(depot["id"]) == worker_entity_id:
				owns_reservation = true

			if not is_reserved or owns_reservation:
				var available_wood: int = resource_reg.get_balance(depot["container_id"], &"WOOD")
				if available_wood > 0:
					var dist: int = spatial_reg.calculate_distance(worker_coord, depot["coord"], CoreEnums.SpatialDistanceMetric.MANHATTAN)
					if dist < nearest_supply_dist:
						nearest_supply_dist = dist
						nearest_supply_id = depot["id"]
						nearest_supply_coord = depot["coord"]

	blackboard["nearest_valid_supply_depot_id"] = nearest_supply_id
	blackboard["nearest_valid_supply_depot_coord"] = nearest_supply_coord

	# 3. Identify nearest valid unreserved demand depot that needs wood
	var nearest_demand_id: int = -1
	var nearest_demand_dist: int = 999999
	var nearest_demand_coord: Vector2i = Vector2i(-1, -1)

	for depot in depot_records:
		if depot["type"] == &"DEMAND":
			var is_reserved = reservation_reg.is_reserved(depot["id"])
			var owns_reservation = false
			if is_reserved and reservation_reg.get_claimant(depot["id"]) == worker_entity_id:
				owns_reservation = true

			if not is_reserved or owns_reservation:
				var current_wood: int = resource_reg.get_balance(depot["container_id"], &"WOOD")
				if current_wood < depot["demand_needed"]:
					var dist: int = spatial_reg.calculate_distance(worker_coord, depot["coord"], CoreEnums.SpatialDistanceMetric.MANHATTAN)
					if dist < nearest_demand_dist:
						nearest_demand_dist = dist
						nearest_demand_id = depot["id"]
						nearest_demand_coord = depot["coord"]

	blackboard["nearest_valid_demand_depot_id"] = nearest_demand_id
	blackboard["nearest_valid_demand_depot_coord"] = nearest_demand_coord

	# Calculate current state predicates for GOAP planner
	blackboard["has_wood"] = carried_wood > 0
	blackboard["wood_delivered"] = false

	if nearest_supply_coord != Vector2i(-1, -1) and worker_coord == nearest_supply_coord:
		blackboard["at_supply"] = true
	else:
		blackboard["at_supply"] = false

	if nearest_demand_coord != Vector2i(-1, -1) and worker_coord == nearest_demand_coord:
		blackboard["at_demand"] = true
	else:
		blackboard["at_demand"] = false

	return blackboard
