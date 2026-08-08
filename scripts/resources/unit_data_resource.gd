class_name UnitDataResource extends Resource

enum Faction { ALLIED, ENEMY }

@export var unit_id: int = -1
@export var faction_id: Faction = Faction.ALLIED
@export var unit_name: String = "Unknown Unit"
@export var unit_class: int = 0

@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var current_stress: float = 0.0
@export var bravery_rating: float = 10.0
@export var loyalty_rating: float = 10.0

@export var base_initiative: int = 10
@export var encumbrance_penalty: float = 0.0
@export var movement_speed_ticks_per_tile: int = 10

@export var weapon_damage: float = 10.0
@export var weapon_hardness_rating: float = 0.0
@export var attack_range_min: int = 1
@export var attack_range_max: int = 1
@export var attack_duration_ticks: int = 20
@export var damage_application_tick_offset: int = 10

@export var can_vault: bool = false
@export var max_jump_gap: int = 0
@export var landing_grade: float = 1.0

@export var is_stunned: bool = false
@export var stun_remaining_ticks: int = 0
@export var is_order_fractured: bool = false
@export var recalculation_cooldown_ticks: int = 0
@export var is_path_blocked: bool = false

@export var active_template_id: StringName = &""
@export var template_parameters: Dictionary = {}

func duplicate_data() -> UnitDataResource:
	var copy = UnitDataResource.new()

	copy.unit_id = unit_id
	copy.faction_id = faction_id
	copy.unit_name = unit_name
	copy.unit_class = unit_class

	copy.max_hp = max_hp
	copy.current_hp = current_hp
	copy.current_stress = current_stress
	copy.bravery_rating = bravery_rating
	copy.loyalty_rating = loyalty_rating

	copy.base_initiative = base_initiative
	copy.encumbrance_penalty = encumbrance_penalty
	copy.movement_speed_ticks_per_tile = movement_speed_ticks_per_tile

	copy.weapon_damage = weapon_damage
	copy.weapon_hardness_rating = weapon_hardness_rating
	copy.attack_range_min = attack_range_min
	copy.attack_range_max = attack_range_max
	copy.attack_duration_ticks = attack_duration_ticks
	copy.damage_application_tick_offset = damage_application_tick_offset

	copy.can_vault = can_vault
	copy.max_jump_gap = max_jump_gap
	copy.landing_grade = landing_grade

	copy.is_stunned = is_stunned
	copy.stun_remaining_ticks = stun_remaining_ticks
	copy.is_order_fractured = is_order_fractured
	copy.recalculation_cooldown_ticks = recalculation_cooldown_ticks
	copy.is_path_blocked = is_path_blocked

	copy.active_template_id = active_template_id
	copy.template_parameters = template_parameters.duplicate(true)

	return copy
