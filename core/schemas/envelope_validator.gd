class_name EnvelopeValidator
extends RefCounted

static func is_valid_command(packet: Dictionary) -> bool:
	if not packet.has("command_id") or typeof(packet["command_id"]) != TYPE_INT or packet["command_id"] < 1:
		return false
	if not packet.has("priority") or typeof(packet["priority"]) != TYPE_INT or packet["priority"] < 0 or packet["priority"] > 4:
		return false
	if not packet.has("command_type") or typeof(packet["command_type"]) != TYPE_STRING_NAME or str(packet["command_type"]).is_empty():
		return false
	if not packet.has("issuer_id") or typeof(packet["issuer_id"]) != TYPE_INT or packet["issuer_id"] < 0:
		return false
	if not packet.has("target_tick") or typeof(packet["target_tick"]) != TYPE_INT or packet["target_tick"] < 0:
		return false
	if not packet.has("payload") or typeof(packet["payload"]) != TYPE_DICTIONARY:
		return false

	if _contains_object(packet["payload"]):
		return false

	return true

static func is_valid_event(event: Dictionary) -> bool:
	if not event.has("event_type") or typeof(event["event_type"]) != TYPE_STRING_NAME or str(event["event_type"]).is_empty():
		return false
	if not event.has("tick_timestamp") or typeof(event["tick_timestamp"]) != TYPE_INT or event["tick_timestamp"] < 0:
		return false
	if not event.has("source_entity_id") or typeof(event["source_entity_id"]) != TYPE_INT or event["source_entity_id"] < 0:
		return false
	if not event.has("target_entity_id") or typeof(event["target_entity_id"]) != TYPE_INT or event["target_entity_id"] < 0:
		return false
	if not event.has("event_data") or typeof(event["event_data"]) != TYPE_DICTIONARY:
		return false

	# Zero live objects allowed in event_data
	if _contains_object(event["event_data"]):
		return false

	return true

static func _contains_object(val: Variant) -> bool:
	if typeof(val) == TYPE_OBJECT:
		return true
	elif typeof(val) == TYPE_DICTIONARY:
		for k in val:
			if typeof(k) == TYPE_OBJECT:
				return true
			if _contains_object(val[k]):
				return true
	elif typeof(val) == TYPE_ARRAY:
		for item in val:
			if _contains_object(item):
				return true
	return false
