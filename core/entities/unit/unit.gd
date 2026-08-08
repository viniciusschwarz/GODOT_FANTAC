# File: res://core/entities/unit/unit.gd
class_name Unit extends Node2D

## THE ACTOR CONTAINER 
## Routes initialization data to specialized components.

@export var unit_id: StringName = &"unit_unassigned"

@export_category("Components")
@export var health_component: HealthComponent
@export var movement_component: MovementComponent
@export var ai_evaluator: AIConditionEvaluator
@export var visual_component: VisualComponent
@export var modifier_component: ModifierComponent
@export var los_component: LOSComponent

func initialize(class_data: UnitClassData, generated_stats: UnitStats, ai_tree: AITreeData, starting_coord: Vector3i, map_manager: MapManager) -> void:
	if not health_component or not movement_component or not ai_evaluator or not visual_component or not modifier_component or not los_component:
		push_error("Unit %s is missing required components!" % unit_id)
		return
		
	unit_id = StringName(generated_stats.unit_name)
		
	# Route data via Dependency Injection
	health_component.initialize(generated_stats.max_health, unit_id)
	movement_component.initialize(starting_coord, map_manager, generated_stats)
	ai_evaluator.initialize(ai_tree, self)
	visual_component.initialize(class_data.sprite_atlas_coord, self)
	modifier_component.initialize(generated_stats, unit_id)
	los_component.initialize(map_manager, starting_coord)
	
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus
	EventBus.unit_spawned.emit(self)
