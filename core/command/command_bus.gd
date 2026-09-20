class_name CommandBus
extends RefCounted

var _priority_buffers: Dictionary = { 0: [], 1: [], 2: [], 3: [], 4: [] }
var _validators: Dictionary = {} # command_type: StringName -> Callable(packet) -> Dictionary (ExecutionResult)
var _executors: Dictionary = {}  # command_type: StringName -> Callable(packet) -> Dictionary (ExecutionResult)

func register_command(cmd_type: StringName, validator: Callable, executor: Callable) -> void:
	_validators[cmd_type] = validator
	_executors[cmd_type] = executor

func submit(packet: Dictionary) -> Dictionary:
	if not EnvelopeValidator.is_valid_command(packet):
		return _create_error_result(packet.get("command_id", 0), CoreEnums.ExecutionStatusCode.REJECTED_INVALID_ENVELOPE, &"INVALID_ENVELOPE")

	var priority: int = packet.get("priority", CoreEnums.ExecutionPriority.INPUT_DIRECT)

	_priority_buffers[priority].append(packet)
	return {
		"command_id": packet["command_id"],
		"status_code": CoreEnums.ExecutionStatusCode.SUCCESS,
		"reason_code": &"NONE",
		"mutated_entity_ids": PackedInt32Array()
	}

func flush_tick(target_tick: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for p in range(5):
		var buffer: Array = _priority_buffers[p]
		var remaining: Array = []
		for packet in buffer:
			if packet["target_tick"] <= target_tick:
				var cmd_type: StringName = packet["command_type"]

				if not _validators.has(cmd_type):
					results.append(_create_error_result(packet["command_id"], CoreEnums.ExecutionStatusCode.FAILED_INTERNAL_ERROR, &"MISSING_VALIDATOR"))
					continue

				var val_res: Dictionary = _validators[cmd_type].call(packet)
				if val_res["status_code"] != CoreEnums.ExecutionStatusCode.SUCCESS:
					results.append(val_res)
					continue

				if not _executors.has(cmd_type):
					results.append(_create_error_result(packet["command_id"], CoreEnums.ExecutionStatusCode.FAILED_INTERNAL_ERROR, &"MISSING_EXECUTOR"))
					continue

				var exec_res: Dictionary = _executors[cmd_type].call(packet)
				results.append(exec_res)
			else:
				remaining.append(packet)
		_priority_buffers[p] = remaining

	return results

func _create_error_result(cmd_id: int, status: int, reason: StringName) -> Dictionary:
	return {
		"command_id": cmd_id,
		"status_code": status,
		"reason_code": reason,
		"mutated_entity_ids": PackedInt32Array()
	}
