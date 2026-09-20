class_name SaveRegistry
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 1
var _providers: Dictionary = {} # domain_key: StringName -> Callable() -> Dictionary
var _consumers: Dictionary = {} # domain_key: StringName -> Callable(state: Dictionary) -> bool

func register_domain(domain_key: StringName, save_cb: Callable, load_cb: Callable) -> void:
	_providers[domain_key] = save_cb
	_consumers[domain_key] = load_cb

func capture_snapshot(current_tick: int) -> Dictionary:
	var domains: Dictionary = {}
	for key in _providers:
		domains[key] = _providers[key].call()

	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"timestamp_utc": Time.get_unix_time_from_system(),
		"current_tick": current_tick,
		"domains": domains
	}

func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.get("schema_version", 0) != CURRENT_SCHEMA_VERSION:
		return false

	var domains: Dictionary = snapshot.get("domains", {})
	for key in domains:
		if _consumers.has(key):
			var success: bool = _consumers[key].call(domains[key])
			if not success:
				return false

	return true
