class_name EventBus
extends RefCounted

var _subscribers: Dictionary = {} # event_type: StringName -> Array[Callable]
var _queue: Array[Dictionary] = []

func subscribe(event_type: StringName, callback: Callable) -> void:
	if not _subscribers.has(event_type):
		_subscribers[event_type] = []
	if not _subscribers[event_type].has(callback):
		_subscribers[event_type].append(callback)

func unsubscribe(event_type: StringName, callback: Callable) -> void:
	if _subscribers.has(event_type):
		_subscribers[event_type].erase(callback)

func emit_now(event: Dictionary) -> void:
	var event_type: StringName = event.get("event_type", &"")
	if _subscribers.has(event_type):
		for callback in _subscribers[event_type]:
			callback.call(event)

func enqueue(event: Dictionary) -> void:
	_queue.append(event)

func flush_queue() -> void:
	var to_process: Array[Dictionary] = _queue.duplicate()
	_queue.clear()
	for event in to_process:
		emit_now(event)
