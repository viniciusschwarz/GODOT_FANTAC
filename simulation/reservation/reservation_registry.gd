class_name ReservationRegistry
extends RefCounted

var _claims: Dictionary = {}

func try_claim(claimant_id: int, target_id: int, claim_type: int, duration: int, current_tick: int) -> bool:
	if is_reserved(target_id):
		var existing = _claims[target_id]
		# Optionally handle renewals or same claimant logic if needed
		if existing["claimant_id"] != claimant_id:
			return false

	_claims[target_id] = {
		"claimant_id": claimant_id,
		"claim_type": claim_type,
		"expires_tick": current_tick + duration
	}
	return true

func release_claim(claimant_id: int, target_id: int) -> bool:
	if not _claims.has(target_id):
		return false

	var existing = _claims[target_id]
	if existing["claimant_id"] != claimant_id:
		return false

	_claims.erase(target_id)
	return true

func is_reserved(target_id: int) -> bool:
	return _claims.has(target_id)

func tick_prune_expired(current_tick: int) -> void:
	var keys = _claims.keys()
	for target_id in keys:
		if _claims[target_id]["expires_tick"] <= current_tick:
			_claims.erase(target_id)

func get_claimant(target_resource_id: int) -> int:
	if not _claims.has(target_resource_id):
		return -1
	return _claims[target_resource_id]["claimant_id"]

func get_save_state() -> Dictionary:
	return {
		"claims": _claims
	}

func load_save_state(state: Dictionary) -> bool:
	if not state.has("claims"):
		return false

	_claims = state["claims"]
	return true
