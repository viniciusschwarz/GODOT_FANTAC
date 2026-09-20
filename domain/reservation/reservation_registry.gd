class_name ReservationRegistry
extends RefCounted

var _claims: Dictionary = {} # target_resource_id: int -> { claimant_id: int, claim_type: int, expires_tick: int }

func try_claim(claimant_id: int, target_resource_id: int, claim_type: int, duration_ticks: int, current_tick: int) -> bool:
	if _claims.has(target_resource_id):
		var existing: Dictionary = _claims[target_resource_id]
		# Reject if there is already an exclusive claim
		if existing["claim_type"] == CoreEnums.ReservationClaimType.EXCLUSIVE_WRITE:
			if existing["claimant_id"] != claimant_id:
				return false
		# Reject if we want exclusive claim but there's a shared claim by someone else
		if claim_type == CoreEnums.ReservationClaimType.EXCLUSIVE_WRITE:
			if existing["claimant_id"] != claimant_id:
				return false

	_claims[target_resource_id] = {
		"claimant_id": claimant_id,
		"claim_type": claim_type,
		"expires_tick": current_tick + duration_ticks
	}
	return true

func release_claim(claimant_id: int, target_resource_id: int) -> bool:
	if _claims.has(target_resource_id):
		if _claims[target_resource_id]["claimant_id"] == claimant_id:
			_claims.erase(target_resource_id)
			return true
	return false

func is_reserved(target_resource_id: int) -> bool:
	return _claims.has(target_resource_id)

func tick_prune_expired(current_tick: int) -> void:
	var to_remove: Array = []
	for target_id in _claims:
		if _claims[target_id]["expires_tick"] <= current_tick:
			to_remove.append(target_id)

	for target_id in to_remove:
		_claims.erase(target_id)

func get_save_state() -> Dictionary:
	return {
		"claims": _claims.duplicate(true)
	}

func load_save_state(state: Dictionary) -> bool:
	if state.has("claims"):
		_claims = state["claims"].duplicate(true)
		return true
	return false
