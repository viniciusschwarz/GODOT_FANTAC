# File: res://core/systems/unit_factory.gd
class_name UnitFactory extends Node

## PROCEDURAL ACTOR GENERATOR
## Reads UnitClassData, rolls unique stats, and instantiates the physical scene.

@export var unit_prefab: PackedScene

## Spawns a unit into the scene tree and initializes its components.
## @param class_data: The archetype blueprint (e.g., Recruit).
## @param ai_tree: The logical behavior tree.
## @param coord: The starting simulation coordinate.
## @param map_manager: Reference required for movement initialization.
## @param parent_node: Where to attach the unit in the scene tree.
## @return Node2D: The fully initialized Unit node.
func deploy_unit(class_data: UnitClassData, ai_tree: AITreeData, coord: Vector3i, map_manager: MapManager, parent_node: Node) -> Node2D:
	if not unit_prefab:
		push_error("UnitFactory: Unit Prefab is missing!")
		return null
		
	# 1. Roll unique stats based on variance
	# EXTERNAL ACCESS NOTE: Calling Resource method
	var unique_stats: UnitStats = class_data.generate_unique_stats()
	
	# 2. Instantiate and attach
	var new_unit: Node2D = unit_prefab.instantiate() as Node2D
	parent_node.add_child(new_unit)
	
	# 3. Inject Dependencies
	new_unit.initialize(class_data, unique_stats, ai_tree, coord, map_manager)
	
	return new_unit
