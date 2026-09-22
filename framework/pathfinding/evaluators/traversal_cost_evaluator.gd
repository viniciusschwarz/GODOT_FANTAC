class_name TraversalCostEvaluator
extends RefCounted

const NavigationProfileDefinition = preload("res://framework/pathfinding/graph/navigation_profile_definition.gd")
const SpatialNavGraphRegistry = preload("res://framework/pathfinding/graph/spatial_nav_graph_registry.gd")
const GridTopologyAdapter = preload("res://framework/pathfinding/topology/grid_topology_adapter.gd")

static func calculate_step_cost(from_coord: Vector2i, to_coord: Vector2i, graph: SpatialNavGraphRegistry, profile: NavigationProfileDefinition) -> float:
	if not graph.is_cell_traversable(to_coord, profile.required_mask, profile.ignored_mask):
		return INF

	var distance: float = GridTopologyAdapter.calculate_distance(from_coord, to_coord, profile.topology_type)
	var cell_cost: float = graph.get_cell_cost(to_coord)

	if GridTopologyAdapter.is_diagonal_step(from_coord, to_coord):
		return cell_cost * 1.41421356 # sqrt(2)

	return distance * cell_cost

static func calculate_heuristic(from_coord: Vector2i, goal_coord: Vector2i, topology_type: int, weight: float = 1.0) -> float:
	var h: float = GridTopologyAdapter.calculate_distance(from_coord, goal_coord, topology_type)
	return h * weight * 1.001 # Tie-breaking epsilon
