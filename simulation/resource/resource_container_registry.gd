class_name ResourceContainerRegistry
extends RefCounted

var _containers: Dictionary = {}

func create_container(id: int) -> void:
	if not _containers.has(id):
		_containers[id] = {}

func get_balance(id: int, type: StringName) -> int:
	if not _containers.has(id):
		return 0
	return _containers[id].get(type, 0)

func deposit(id: int, type: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	if not _containers.has(id):
		create_container(id)

	var current = _containers[id].get(type, 0)
	_containers[id][type] = current + amount
	return true

func withdraw(id: int, type: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	if not _containers.has(id):
		return false

	var current = _containers[id].get(type, 0)
	if current < amount:
		return false

	_containers[id][type] = current - amount
	return true

func transfer(src_id: int, dst_id: int, type: StringName, amount: int) -> bool:
	if amount <= 0:
		return false

	if not withdraw(src_id, type, amount):
		return false

	if not deposit(dst_id, type, amount):
		# Rollback
		deposit(src_id, type, amount)
		return false

	return true

func get_save_state() -> Dictionary:
	return {
		"containers": _containers.duplicate(true)
	}

func load_save_state(state: Dictionary) -> bool:
	if not state.has("containers"):
		return false

	_containers = state["containers"].duplicate(true)
	return true
