# File: res://core/components/modifier_component.gd
class_name ModifierComponent extends Node

## THE STAT FILTER
## Tracks active buffs/debuffs and calculates effective battle stats.

var _active_modifiers: Array[ModifierData] = []
var _base_stats: UnitStats
var _unit_id: StringName

## Injected by the Unit container upon initialization.
func initialize(stats: UnitStats, unit_id: StringName) -> void:
	_base_stats = stats
	_unit_id = unit_id

func add_modifier(mod: ModifierData) -> void:
	if not mod in _active_modifiers:
		_active_modifiers.append(mod)
		# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
		EventBus.unit_modifier_added.emit(_unit_id, mod)

func remove_modifier(mod: ModifierData) -> void:
	if mod in _active_modifiers:
		_active_modifiers.erase(mod)
		# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
		EventBus.unit_modifier_removed.emit(_unit_id, mod)

## Passes the base stat through the active modifier pipeline.
func get_effective_stat(stat: ModifierData.StatType) -> float:
	var base_val: float = _get_base_stat_value(stat)
	var final_val: float = base_val
	
	# 1. Apply Flat Additions First
	for mod: ModifierData in _active_modifiers:
		if mod.target_stat == stat and mod.mod_type == ModifierData.ModifierType.FLAT_ADD:
			final_val += mod.value
			
	# 2. Apply Multipliers Second (Stacking additively)
	var total_multiplier: float = 1.0
	for mod: ModifierData in _active_modifiers:
		if mod.target_stat == stat and mod.mod_type == ModifierData.ModifierType.MULTIPLY:
			total_multiplier += (mod.value - 1.0) 
			
	final_val *= maxf(total_multiplier, 0.0) # Prevent negative multipliers from inverting stats
	
	# 3. Apply Overrides Last
	var has_override: bool = false
	var override_val: float = 0.0
	for mod: ModifierData in _active_modifiers:
		if mod.target_stat == stat and mod.mod_type == ModifierData.ModifierType.OVERRIDE:
			has_override = true
			if mod.value > override_val:
				override_val = mod.value
				
	if has_override:
		return override_val
		
	return final_val

func _get_base_stat_value(stat: ModifierData.StatType) -> float:
	if not _base_stats: 
		push_error("ModifierComponent: Base stats not initialized!")
		return 0.0
		
	match stat:
		ModifierData.StatType.PHYSICAL_ATTACK: return float(_base_stats.physical_attack)
		ModifierData.StatType.PHYSICAL_DEFENSE: return float(_base_stats.physical_defense)
		ModifierData.StatType.MAX_HEALTH: return float(_base_stats.max_health)
		ModifierData.StatType.MAX_MANA: return float(_base_stats.max_mana)
		ModifierData.StatType.MOVEMENT_SPEED: return float(_base_stats.base_movement_speed)
		ModifierData.StatType.ACTION_POINTS: return float(_base_stats.max_ap)
		ModifierData.StatType.RANGE: return 1.0 # Range inherently defaults to 1 (melee) unless defined by a weapon
		
	return 0.0