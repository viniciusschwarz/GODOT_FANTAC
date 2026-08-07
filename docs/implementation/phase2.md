Commander, welcome to **Phase 2: The Mathematical Battlefield**.

In this phase, we divorce the visual representation of the world from the simulation. Our 2.5D tactical board must exist entirely as a mathematical data structure in the background. The visual engine (which we will build in a later phase) will simply read this data to place sprites and `TileMapLayer` nodes.

### 1. Architectural Logic: The Invisible Grid

**The Z-Level Paradigm:**
We will use a `Vector3i` coordinate system. Even though the game looks 2D from the top-down, a unit at `(5, 5, 0)` is on the ground, while a unit at `(5, 5, 1)` is on a roof directly above them.

**Pathfinding (AStar3D):**
Standard 2D grids cannot comprehend jumping off a roof or climbing stairs. We will wrap Godot's `AStar3D` class within a dedicated `GridAStar3D` system. It will dynamically connect nodes based on adjacent `Vector3i` coordinates. If a tile is designated as "stairs", it will bridge `(x, y, z)` with `(x+1, y, z+1)`.

**Line of Sight (LoS):**
We do not use physics raycasts. We use a purely mathematical 3D line-drawing algorithm (Bresenham's 3D) on our data grid. If the line passes through a coordinate that contains a wall or a higher elevation tile that blocks vision, the shot is invalid.

---

### 2. Phase 2 Directory Tree

```text
res://
├── Core/
│   └── Systems/
│       ├── MapManager.gd         # API layer for all map queries
│       └── GridAStar3D.gd        # Pathfinding mathematics engine
└── Data/
    └── Resources/
        ├── Map/
        │   ├── TacticalTileData.gd # Defines behavior of a single tile
        │   └── MapData.gd          # Stores the entire battlefield layout

```

---

### 3. Data-Driven Resources

First, we define what a single tile is capable of, and then we create the blueprint resource that holds the entire map.

```gdscript
# File: res://Data/Resources/Map/TacticalTileData.gd
class_name TacticalTileData extends Resource

## Defines the simulation rules for a single grid coordinate.
## This has no visual data; it only dictates tactical math.

@export var tile_name: String = "Ground"
@export var is_walkable: bool = true
@export var blocks_vision: bool = false

## If true, this tile allows units below to see units here, but blocks units 
## from seeing through it horizontally.
@export var blocks_vision_from_above: bool = false 

@export_category("Verticality")
## If true, this tile connects to a walkable tile at z + 1
@export var is_stairs: bool = false 
@export var movement_cost: float = 1.0

```

```gdscript
# File: res://Data/Resources/Map/MapData.gd
class_name MapData extends Resource

## The complete mathematical blueprint of a battlefield.
## Can be generated procedurally or saved in the editor.

@export var map_name: String = "Debug Map"
@export var width: int = 20
@export var height: int = 20
@export var max_z_levels: int = 3

## Godot 4 does not yet support fully typed dictionaries in exports.
## Structure: Dictionary[Vector3i, TacticalTileData]
@export var grid_tiles: Dictionary = {}

## Helper to safely check if a coordinate exists in our mathematical grid.
func has_tile(coord: Vector3i) -> bool:
	return grid_tiles.has(coord)

## Helper to fetch tile data, returns null if empty space.
func get_tile(coord: Vector3i) -> TacticalTileData:
	return grid_tiles.get(coord, null)

```

---

### 4. Modular Node Scripts (The Systems)

Next, we build the engine that calculates paths based on our `MapData`. It is a pure data-processing class, completely decoupled from the SceneTree.

```gdscript
# File: res://Core/Systems/GridAStar3D.gd
class_name GridAStar3D extends RefCounted

## Handles all 3D pathfinding mathematics.
## Wrapper for Godot's AStar3D, decoupled from any visual Nodes.

var _astar: AStar3D = AStar3D.new()
# Maps a Vector3i to an integer ID required by AStar3D
var _point_ids: Dictionary = {} 
var _next_id: int = 0

## Initializes the pathfinding grid based on the injected MapData.
## @param map_data: The resource containing all tile rules.
func build_graph(map_data: MapData) -> void:
	_astar.clear()
	_point_ids.clear()
	_next_id = 0
	
	# 1. Add all walkable points
	for coord: Vector3i in map_data.grid_tiles.keys():
		var tile: TacticalTileData = map_data.get_tile(coord)
		if tile and tile.is_walkable:
			_point_ids[coord] = _next_id
			_astar.add_point(_next_id, Vector3(coord.x, coord.y, coord.z), tile.movement_cost)
			_next_id += 1
			
	# 2. Connect points (Orthogonal 2D + Vertical stairs)
	for coord: Vector3i in _point_ids.keys():
		_connect_adjacent(coord, map_data)

func _connect_adjacent(coord: Vector3i, map_data: MapData) -> void:
	var current_id: int = _point_ids[coord]
	var tile: TacticalTileData = map_data.get_tile(coord)
	
	# Standard 2D Orthogonal connections
	var directions: Array[Vector3i] = [
		Vector3i.RIGHT, Vector3i.LEFT, Vector3i.DOWN, Vector3i.UP
	]
	
	for dir: Vector3i in directions:
		var neighbor_coord: Vector3i = coord + dir
		if _point_ids.has(neighbor_coord):
			_astar.connect_points(current_id, _point_ids[neighbor_coord], false)
			
	# Handle vertical stair connections
	if tile.is_stairs:
		# Define stair logic (e.g., stairs connect to the tile directly "above" and "forward")
		# For this implementation, we simply check the tile directly above (z+1)
		var up_coord: Vector3i = coord + Vector3i(0, 0, 1)
		if _point_ids.has(up_coord):
			_astar.connect_points(current_id, _point_ids[up_coord], true)

## Calculates a path between two coordinates.
## @return Array[Vector3i]: An array of coordinates forming the path.
func get_path_coords(start: Vector3i, end: Vector3i) -> Array[Vector3i]:
	if not _point_ids.has(start) or not _point_ids.has(end):
		return []
		
	var path_3d: PackedVector3Array = _astar.get_point_path(_point_ids[start], _point_ids[end])
	var path_coords: Array[Vector3i] = []
	
	for vec: Vector3 in path_3d:
		path_coords.append(Vector3i(roundi(vec.x), roundi(vec.y), roundi(vec.z)))
		
	return path_coords

```

Finally, the `MapManager`. This Node acts as the single source of truth for the rest of the game when querying the battlefield.

```gdscript
# File: res://Core/Systems/MapManager.gd
class_name MapManager extends Node

## The API layer for the tactical board.
## Units and UI will query this manager for paths, LoS, and valid targets.

@export var current_map_data: MapData

var _pathfinder: GridAStar3D

func _ready() -> void:
	# EXTERNAL ACCESS NOTE: Will eventually listen to EventBus for map loading events
	_pathfinder = GridAStar3D.new()
	if current_map_data:
		initialize_map(current_map_data)

## Dependency Injection: Loads a new map into the simulation.
func initialize_map(map_data: MapData) -> void:
	current_map_data = map_data
	_pathfinder.build_graph(current_map_data)
	print("MapManager: Initialized grid with %d tiles." % current_map_data.grid_tiles.size())

## Requests a path from the AStar3D system.
func request_path(start: Vector3i, end: Vector3i) -> Array[Vector3i]:
	return _pathfinder.get_path_coords(start, end)

## Calculates if a 3D line exists between two points without hitting a blocking tile.
## Uses a basic 3D Bresenham algorithm adaptation.
func is_line_of_sight_clear(start: Vector3i, target: Vector3i) -> bool:
	var current: Vector3i = start
	var diff: Vector3i = target - start
	var steps: int = maxi(maxi(abs(diff.x), abs(diff.y)), abs(diff.z))
	
	if steps == 0:
		return true
		
	var x_inc: float = diff.x / float(steps)
	var y_inc: float = diff.y / float(steps)
	var z_inc: float = diff.z / float(steps)
	
	var exact_pos: Vector3 = Vector3(start.x, start.y, start.z)
	
	for i: int in range(1, steps):
		exact_pos.x += x_inc
		exact_pos.y += y_inc
		exact_pos.z += z_inc
		
		var check_coord: Vector3i = Vector3i(roundi(exact_pos.x), roundi(exact_pos.y), roundi(exact_pos.z))
		var tile: TacticalTileData = current_map_data.get_tile(check_coord)
		
		# If the line passes through a solid blocking tile, LoS is broken
		if tile and tile.blocks_vision:
			return false
			
	return true

```

---