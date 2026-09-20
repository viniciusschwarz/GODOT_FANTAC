# res://core/tests/test_core_envelopes.gd
extends SceneTree

## Automated test suite validating schema integrity, type correctness,
## and boundary invariants defined in /docs/schemas/core_envelopes.md.
## Runs headlessly via CLI: godot --headless -s res://core/tests/test_core_envelopes.gd

var _total_tests: int = 0
var _passed_tests: int = 0
var _failed_tests: int = 0


func _init() -> void:
	var success = run_all_tests()
	quit(0 if success else 1)


func run_all_tests() -> bool:
	_total_tests = 0
	_passed_tests = 0
	_failed_tests = 0

	print("\n--- Starting Two-Tier Core Envelopes & Payloads Test Suite ---")

	# Envelope Verifications
	_test_command_packet_valid_shape()
	_test_command_packet_rejects_invalid_priority()
	_test_command_packet_rejects_non_primitive()
	_test_command_packet_rejects_invalid_tick()
	_test_execution_result_valid_shape()
	_test_execution_result_success_requires_none_reason()
	_test_execution_result_failure_clears_mutated_entities()
	_test_event_payload_valid_shape()
	_test_event_payload_rejects_invalid_mutation_type()
	_test_state_snapshot_delta_valid_shape()

	# Domain Payload Verifications
	_test_spatial_relocation_manhattan_metric()
	_test_spatial_relocation_chebyshev_metric()
	_test_spatial_relocation_container_transfer_permits_identical_coords()
	_test_attribute_delta_payload_rejects_nan_and_inf()
	_test_attribute_delta_payload_multiplicative_requires_non_negative()
	_test_resource_transfer_payload_positive_quantity()
	_test_resource_transfer_payload_rejects_identical_containers()
	_test_reservation_claim_payload_positive_duration()
	_test_action_trigger_payload_matches_target_type()
	_test_action_trigger_payload_rejects_mismatched_target_type()

	print("--- Test Suite Finished: %d Passed, %d Failed, %d Total ---" % [
		_passed_tests, _failed_tests, _total_tests
	])
	return _failed_tests == 0


func _assert_true(condition: bool, test_name: String) -> void:
	_total_tests += 1
	if condition:
		_passed_tests += 1
		print("[PASS] %s" % test_name)
	else:
		_failed_tests += 1
		printerr("[FAIL] %s" % test_name)


# --- Tier 1 & Tier 2 Enum Value Sets ---

const VALID_EXECUTION_STATUS_CODES = [0, 1, 10, 11, 12, 20, 21, 22, 23, 24, 25, 40, 41, 42, 43, 60]
const VALID_EXECUTION_PRIORITIES = [0, 1, 2, 3, 4]
const VALID_STATE_MUTATION_TYPES = [0, 1, 2, 3]
const VALID_ATTRIBUTE_OPERATION_TYPES = [0, 1, 2, 3, 4]
const VALID_SPATIAL_METRICS = [0, 1, 2, 3]
const VALID_TRAVERSAL_MODES = [0, 1, 2, 3]
const VALID_RESERVATION_CLAIM_TYPES = [0, 1, 2]
const VALID_TARGET_SELECTION_TYPES = [0, 1, 2, 3, 4]


# --- Envelopes Schema Validation Logic ---

func _is_valid_command_packet(data: Dictionary) -> bool:
	var required_keys = ["command_id", "priority", "command_type", "issuer_id", "target_tick", "payload"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["command_id"] is int and data["command_id"] >= 1):
		return false
	if not (data["priority"] is int and data["priority"] in VALID_EXECUTION_PRIORITIES):
		return false
	if not (data["command_type"] is StringName and not (data["command_type"] as StringName).is_empty()):
		return false
	if not (data["issuer_id"] is int and data["issuer_id"] >= 0):
		return false
	if not (data["target_tick"] is int and data["target_tick"] >= 0):
		return false
	if not (data["payload"] is Dictionary):
		return false

	for k in data["payload"].keys():
		var val = data["payload"][k]
		if val is Object:
			return false

	return true


func _is_valid_execution_result(data: Dictionary) -> bool:
	var required_keys = ["command_id", "status_code", "reason_code", "mutated_entity_ids"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["command_id"] is int and data["command_id"] >= 1):
		return false
	if not (data["status_code"] is int and data["status_code"] in VALID_EXECUTION_STATUS_CODES):
		return false
	if not (data["reason_code"] is StringName):
		return false
	if not (data["mutated_entity_ids"] is PackedInt32Array):
		return false

	# Invariant: If SUCCESS (0) or SUCCESS_NOOP (1), reason_code MUST be &"NONE"
	if (data["status_code"] == 0 or data["status_code"] == 1) and data["reason_code"] != &"NONE":
		return false

	# Invariant: If rejected or failed, mutated entities must be empty
	if data["status_code"] != 0 and data["status_code"] != 1 and data["mutated_entity_ids"].size() > 0:
		return false

	return true


func _is_valid_event_payload(data: Dictionary) -> bool:
	var required_keys = ["event_type", "mutation_type", "tick_timestamp", "source_entity_id", "target_entity_id", "event_data"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["event_type"] is StringName and not (data["event_type"] as StringName).is_empty()):
		return false
	if not (data["mutation_type"] is int and data["mutation_type"] in VALID_STATE_MUTATION_TYPES):
		return false
	if not (data["tick_timestamp"] is int and data["tick_timestamp"] >= 0):
		return false
	if not (data["source_entity_id"] is int and data["source_entity_id"] >= 0):
		return false
	if not (data["target_entity_id"] is int and data["target_entity_id"] >= 0):
		return false
	if not (data["event_data"] is Dictionary):
		return false

	for k in data["event_data"].keys():
		if data["event_data"][k] is Object:
			return false

	return true


func _is_valid_state_snapshot_delta(data: Dictionary) -> bool:
	var required_keys = ["tick_id", "entity_transforms", "dirty_cells", "visual_cues"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["tick_id"] is int and data["tick_id"] >= 0):
		return false
	if not (data["entity_transforms"] is Array):
		return false
	if not (data["dirty_cells"] is Array):
		return false
	if not (data["visual_cues"] is Array):
		return false

	return true


# --- Domain Payloads Validation Logic ---

func _is_valid_spatial_relocation_payload(data: Dictionary) -> bool:
	var required_keys = ["entity_id", "origin_coord", "destination_coord", "traversal_mode", "metric"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["entity_id"] is int and data["entity_id"] >= 1):
		return false
	if not (data["origin_coord"] is Vector2i):
		return false
	if not (data["destination_coord"] is Vector2i):
		return false
	if not (data["traversal_mode"] is int and data["traversal_mode"] in VALID_TRAVERSAL_MODES):
		return false
	if not (data["metric"] is int and data["metric"] in VALID_SPATIAL_METRICS):
		return false

	# Traversal Mode 0: DISCRETE_STEP requires distance check according to metric
	if data["traversal_mode"] == 0:
		var delta_x = absi(data["destination_coord"].x - data["origin_coord"].x)
		var delta_y = absi(data["destination_coord"].y - data["origin_coord"].y)

		# Manhattan (4-directional): |dx| + |dy| <= 1
		if data["metric"] == 0:
			if (delta_x + delta_y) > 1:
				return false
		# Chebyshev (8-directional with diagonals): max(|dx|, |dy|) <= 1
		elif data["metric"] == 1:
			if delta_x > 1 or delta_y > 1:
				return false

	# Invariant: origin cannot equal destination unless CONTAINER_TRANSFER (3)
	if data["origin_coord"] == data["destination_coord"] and data["traversal_mode"] != 3:
		return false

	return true


func _is_valid_attribute_delta_payload(data: Dictionary) -> bool:
	var required_keys = ["target_entity_id", "attribute_id", "delta_value", "operation_type", "source_cause_id"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["target_entity_id"] is int and data["target_entity_id"] >= 1):
		return false
	if not (data["attribute_id"] is StringName and not (data["attribute_id"] as StringName).is_empty()):
		return false
	if not (data["delta_value"] is float):
		return false
	if is_nan(data["delta_value"]) or is_inf(data["delta_value"]):
		return false
	if not (data["operation_type"] is int and data["operation_type"] in VALID_ATTRIBUTE_OPERATION_TYPES):
		return false
	if not (data["source_cause_id"] is StringName and not (data["source_cause_id"] as StringName).is_empty()):
		return false

	# Invariant: PERCENTAGE_MULTIPLICATIVE (2) requires delta_value >= 0.0
	if data["operation_type"] == 2 and data["delta_value"] < 0.0:
		return false

	return true


func _is_valid_resource_transfer_payload(data: Dictionary) -> bool:
	var required_keys = ["source_container_id", "target_container_id", "resource_type_id", "quantity"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["source_container_id"] is int and data["source_container_id"] >= 1):
		return false
	if not (data["target_container_id"] is int and data["target_container_id"] >= 1):
		return false
	if data["source_container_id"] == data["target_container_id"]:
		return false
	if not (data["resource_type_id"] is StringName and not (data["resource_type_id"] as StringName).is_empty()):
		return false
	if not (data["quantity"] is int and data["quantity"] > 0):
		return false

	return true


func _is_valid_reservation_claim_payload(data: Dictionary) -> bool:
	var required_keys = ["claimant_id", "target_resource_id", "claim_type", "expected_duration_ticks"]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["claimant_id"] is int and data["claimant_id"] >= 1):
		return false
	if not (data["target_resource_id"] is int and data["target_resource_id"] >= 1):
		return false
	if not (data["claim_type"] is int and data["claim_type"] in VALID_RESERVATION_CLAIM_TYPES):
		return false
	if not (data["expected_duration_ticks"] is int and data["expected_duration_ticks"] > 0):
		return false

	return true


func _is_valid_action_trigger_payload(data: Dictionary) -> bool:
	var required_keys = [
		"actor_id", "action_definition_id", "target_type",
		"target_entity_id", "target_coord", "target_volume", "target_container_id"
	]
	for k in required_keys:
		if not data.has(k):
			return false

	if not (data["actor_id"] is int and data["actor_id"] >= 1):
		return false
	if not (data["action_definition_id"] is StringName and not (data["action_definition_id"] as StringName).is_empty()):
		return false
	if not (data["target_type"] is int and data["target_type"] in VALID_TARGET_SELECTION_TYPES):
		return false
	if not (data["target_entity_id"] is int):
		return false
	if not (data["target_coord"] is Vector2i):
		return false
	if not (data["target_volume"] is Rect2i):
		return false
	if not (data["target_container_id"] is int):
		return false

	# Strict validation aligning with TargetSelectionType:
	# 0 = NONE, 1 = ENTITY, 2 = COORDINATE, 3 = VOLUME, 4 = CONTAINER
	match data["target_type"]:
		0: # NONE
			return data["target_entity_id"] == 0 and data["target_coord"] == Vector2i(-1, -1) and data["target_volume"].size == Vector2i(0, 0) and data["target_container_id"] == 0
		1: # ENTITY
			return data["target_entity_id"] > 0
		2: # COORDINATE
			return data["target_coord"] != Vector2i(-1, -1)
		3: # VOLUME
			return data["target_volume"].size.x > 0 and data["target_volume"].size.y > 0
		4: # CONTAINER
			return data["target_container_id"] > 0

	return false


# --- Unit Test Assertions ---

func _test_command_packet_valid_shape() -> void:
	var packet = {
		"command_id": 1,
		"priority": 2, # INPUT_DIRECT
		"command_type": &"MOVE_ENTITY",
		"issuer_id": 10,
		"target_tick": 120,
		"payload": {"step": 1}
	}
	_assert_true(_is_valid_command_packet(packet), "CommandPacket accepts valid shape with priority")


func _test_command_packet_rejects_invalid_priority() -> void:
	var packet = {
		"command_id": 1,
		"priority": 99, # Invalid priority
		"command_type": &"MOVE_ENTITY",
		"issuer_id": 10,
		"target_tick": 120,
		"payload": {}
	}
	_assert_true(not _is_valid_command_packet(packet), "CommandPacket rejects out-of-range priority enum")


func _test_command_packet_rejects_non_primitive() -> void:
	var packet = {
		"command_id": 1,
		"priority": 2,
		"command_type": &"MOVE_ENTITY",
		"issuer_id": 10,
		"target_tick": 120,
		"payload": {"illegal_node_ref": RefCounted.new()}
	}
	_assert_true(not _is_valid_command_packet(packet), "CommandPacket rejects live object instances in payload")


func _test_command_packet_rejects_invalid_tick() -> void:
	var packet = {
		"command_id": 1,
		"priority": 2,
		"command_type": &"MOVE_ENTITY",
		"issuer_id": 10,
		"target_tick": -5,
		"payload": {}
	}
	_assert_true(not _is_valid_command_packet(packet), "CommandPacket rejects negative target_tick")


func _test_execution_result_valid_shape() -> void:
	var res = {
		"command_id": 1,
		"status_code": 0, # SUCCESS
		"reason_code": &"NONE",
		"mutated_entity_ids": PackedInt32Array([10, 12])
	}
	_assert_true(_is_valid_execution_result(res), "ExecutionResult accepts valid shape")


func _test_execution_result_success_requires_none_reason() -> void:
	var res = {
		"command_id": 1,
		"status_code": 0, # SUCCESS
		"reason_code": &"SOMETHING_ELSE",
		"mutated_entity_ids": PackedInt32Array([10])
	}
	_assert_true(not _is_valid_execution_result(res), "ExecutionResult rejects SUCCESS status with non-NONE reason_code")


func _test_execution_result_failure_clears_mutated_entities() -> void:
	var res = {
		"command_id": 1,
		"status_code": 24, # REJECTED_INSUFFICIENT_FUNDS
		"reason_code": &"FUNDS_EMPTY",
		"mutated_entity_ids": PackedInt32Array([10]) # Mutation is forbidden on rejection
	}
	_assert_true(not _is_valid_execution_result(res), "ExecutionResult rejects non-empty mutated_entity_ids on failure")


func _test_event_payload_valid_shape() -> void:
	var event = {
		"event_type": &"ENTITY_DAMAGED",
		"mutation_type": 3, # PATCH
		"tick_timestamp": 500,
		"source_entity_id": 2,
		"target_entity_id": 12,
		"event_data": {"amount": 15.0}
	}
	_assert_true(_is_valid_event_payload(event), "EventPayload accepts valid shape with mutation_type")


func _test_event_payload_rejects_invalid_mutation_type() -> void:
	var event = {
		"event_type": &"ENTITY_DAMAGED",
		"mutation_type": 100, # Invalid enum
		"tick_timestamp": 500,
		"source_entity_id": 2,
		"target_entity_id": 12,
		"event_data": {"amount": 15.0}
	}
	_assert_true(not _is_valid_event_payload(event), "EventPayload rejects out-of-range mutation_type")


func _test_state_snapshot_delta_valid_shape() -> void:
	var snapshot = {
		"tick_id": 500,
		"entity_transforms": [{"id": 1, "pos": Vector2i(2, 4)}],
		"dirty_cells": [{"coord": Vector2i(10, 10)}],
		"visual_cues": []
	}
	_assert_true(_is_valid_state_snapshot_delta(snapshot), "StateSnapshotDelta accepts valid shape")


func _test_spatial_relocation_manhattan_metric() -> void:
	var diagonal_step = {
		"entity_id": 1,
		"origin_coord": Vector2i(0, 0),
		"destination_coord": Vector2i(1, 1), # Manhattan distance = 2 -> illegal for discrete step
		"traversal_mode": 0, # DISCRETE_STEP
		"metric": 0 # MANHATTAN
	}
	_assert_true(not _is_valid_spatial_relocation_payload(diagonal_step), "SpatialRelocation rejects diagonal step under Manhattan metric")


func _test_spatial_relocation_chebyshev_metric() -> void:
	var diagonal_step = {
		"entity_id": 1,
		"origin_coord": Vector2i(0, 0),
		"destination_coord": Vector2i(1, 1), # Chebyshev distance = 1 -> legal
		"traversal_mode": 0, # DISCRETE_STEP
		"metric": 1 # CHEBYSHEV
	}
	_assert_true(_is_valid_spatial_relocation_payload(diagonal_step), "SpatialRelocation accepts diagonal step under Chebyshev metric")


func _test_spatial_relocation_container_transfer_permits_identical_coords() -> void:
	var transfer = {
		"entity_id": 1,
		"origin_coord": Vector2i(0, 0),
		"destination_coord": Vector2i(0, 0),
		"traversal_mode": 3, # CONTAINER_TRANSFER
		"metric": 0
	}
	_assert_true(_is_valid_spatial_relocation_payload(transfer), "SpatialRelocation permits identical coords when mode is CONTAINER_TRANSFER")


func _test_attribute_delta_payload_rejects_nan_and_inf() -> void:
	var nan_payload = {
		"target_entity_id": 12,
		"attribute_id": &"HEALTH",
		"delta_value": NAN,
		"operation_type": 0,
		"source_cause_id": &"POISON"
	}
	_assert_true(not _is_valid_attribute_delta_payload(nan_payload), "AttributeDeltaPayload rejects NaN delta_value")


func _test_attribute_delta_payload_multiplicative_requires_non_negative() -> void:
	var negative_mult = {
		"target_entity_id": 12,
		"attribute_id": &"ATTACK_SPEED",
		"delta_value": -0.5, # Negative multiplicative factor is invalid
		"operation_type": 2, # PERCENTAGE_MULTIPLICATIVE
		"source_cause_id": &"SLOW_DEBUFF"
	}
	_assert_true(not _is_valid_attribute_delta_payload(negative_mult), "AttributeDeltaPayload rejects negative factor for PERCENTAGE_MULTIPLICATIVE")


func _test_resource_transfer_payload_positive_quantity() -> void:
	var zero_quantity_payload = {
		"source_container_id": 1,
		"target_container_id": 2,
		"resource_type_id": &"WOOD",
		"quantity": 0
	}
	_assert_true(not _is_valid_resource_transfer_payload(zero_quantity_payload), "ResourceTransferPayload rejects quantity <= 0")


func _test_resource_transfer_payload_rejects_identical_containers() -> void:
	var self_transfer = {
		"source_container_id": 4,
		"target_container_id": 4,
		"resource_type_id": &"WOOD",
		"quantity": 10
	}
	_assert_true(not _is_valid_resource_transfer_payload(self_transfer), "ResourceTransferPayload rejects transfers between identical containers")


func _test_reservation_claim_payload_positive_duration() -> void:
	var zero_duration = {
		"claimant_id": 1,
		"target_resource_id": 10,
		"claim_type": 0,
		"expected_duration_ticks": 0
	}
	_assert_true(not _is_valid_reservation_claim_payload(zero_duration), "ReservationClaimPayload rejects duration <= 0")


func _test_action_trigger_payload_matches_target_type() -> void:
	var entity_action = {
		"actor_id": 1,
		"action_definition_id": &"STRIKE",
		"target_type": 1, # ENTITY
		"target_entity_id": 5,
		"target_coord": Vector2i(-1, -1),
		"target_volume": Rect2i(0, 0, 0, 0),
		"target_container_id": 0
	}
	_assert_true(_is_valid_action_trigger_payload(entity_action), "ActionTriggerPayload validates clean ENTITY target structure")


func _test_action_trigger_payload_rejects_mismatched_target_type() -> void:
	var broken_action = {
		"actor_id": 1,
		"action_definition_id": &"STRIKE",
		"target_type": 2, # Declared COORDINATE, but supplied target_coord is unset
		"target_entity_id": 5,
		"target_coord": Vector2i(-1, -1),
		"target_volume": Rect2i(0, 0, 0, 0),
		"target_container_id": 0
	}
	_assert_true(not _is_valid_action_trigger_payload(broken_action), "ActionTriggerPayload rejects target data that conflicts with target_type enum")