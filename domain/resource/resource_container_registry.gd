class_name ResourceContainerRegistry
extends RefCounted

var _containers: Dictionary = {} # container_id: int -> { resource_type: StringName -> int }

func create_container(container_id: int) -> void:
	if not _containers.has(container_id):
		_containers[container_id] = {}

func get_balance(container_id: int, resource_type: StringName) -> int:
	if _containers.has(container_id):
		return _containers[container_id].get(resource_type, 0)
	return 0

func deposit(container_id: int, resource_type: StringName, amount: int) -> bool:
	if not _containers.has(container_id):
		return false
	if amount < 0:
		return false

	var current: int = _containers[container_id].get(resource_type, 0)
	_containers[container_id][resource_type] = current + amount
	return true

func withdraw(container_id: int, resource_type: StringName, amount: int) -> bool:
	if not _containers.has(container_id):
		return false
	if amount < 0:
		return false

	var current: int = _containers[container_id].get(resource_type, 0)
	if current < amount:
		return false

	_containers[container_id][resource_type] = current - amount
	return true

func transfer(src_id: int, dst_id: int, resource_type: StringName, amount: int) -> bool:
	if amount < 0:
		return false

	if not withdraw(src_id, resource_type, amount):
		return false

	if not deposit(dst_id, resource_type, amount):
		# Rollback
		deposit(src_id, resource_type, amount)
		return false

	return true

func get_save_state() -> Dictionary:
	return {
		"containers": _containers.duplicate(true)
	}

func load_save_state(state: Dictionary) -> bool:
	if state.has("containers"):
		_containers = state["containers"].duplicate(true)
		return true
	return false
