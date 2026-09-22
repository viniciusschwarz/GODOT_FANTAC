class_name NavigationProfileDefinition
extends RefCounted

const NavTopologyContract = preload("res://framework/pathfinding/contracts/nav_topology_contract.gd")

var agent_footprint_in_cells: Vector2i = Vector2i(1, 1)
var topology_type: int = NavTopologyContract.TopologyType.ORTHOGONAL_4
var required_mask: int = 0
var ignored_mask: int = 0
var allows_diagonal: bool = false
var allow_corner_cutting: bool = false
var max_node_budget: int = 2048
var heuristic_weight: float = 1.0
