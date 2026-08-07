Commander, Phase 3 marks the birth of our actors. We will now construct the physical manifestations of your troops on the mathematical battlefield.

### 1. Architectural Logic: The "Dumb Container" and Components

In a strictly decoupled architecture, a `Unit` script should contain almost zero game logic. It acts purely as a routing hub (an Entity) for modular blocks of logic (Components).

* **Dependency Injection (DI):** When a Unit spawns, a spawner or manager will call its `initialize()` function, injecting its `UnitStats` resource and the `MapManager`. The Unit then passes these references down to its respective components.
* **Component Autonomy:** The `MovementComponent` handles grid traversal, and the `HealthComponent` handles vitality. If the `HealthComponent` registers lethal damage, it doesn't ask the Unit to delete itself; it broadcasts to the `EventBus`, and a dedicated garbage collector or state manager handles the cleanup.
* **State Separation:** The `UnitStats` resource (from Phase 1) holds the *maximums* (e.g., Max HP). The Components hold the *current state* (e.g., Current HP) for the duration of the battle.

---

### 2. Phase 3 Directory Tree

```text
res://
├── Core/
│   ├── Components/
│   │   ├── HealthComponent.gd     # Tracks HP and damage events
│   │   └── MovementComponent.gd   # Translates AP into 3D grid traversal
│   └── Entities/
│       └── Unit/
│           ├── Unit.tscn          # The scene file (Node2D root)
│           └── Unit.gd            # The routing script

```

---

### 3. Modular Node Scripts

#### A. The Unit (Entity Container)

This script sits at the root of `Unit.tscn`. Notice how it simply delegates initialization to its child components.

```gdscript
# File: res://Core/Entities/Unit/Unit.gd
class_name Unit extends Node2D

## THE ACTOR CONTAINER
## Holds components and routes initialization data. Contains zero combat math.

@export var unit_id: StringName = &"unit_unassigned"

@export_category("Components")
## Strict typing for node references assigned in the Inspector
@export var health_component: HealthComponent
@export var movement_component: MovementComponent

## Called by a spawner (e.g., BattlefieldManager) when the unit enters the map.
## @param stats: The immutable Resource defining this unit's max capabilities.
## @param starting_coord: The Vector3i simulation coordinate.
## @param map_manager: Injected reference to query the grid.
func initialize(stats: UnitStats, starting_coord: Vector3i, map_manager: MapManager) -> void:
	if not health_component or not movement_component:
		push_error("Unit %s is missing required components!" % unit_id)
		return
		
	# Route data to components via Dependency Injection
	health_component.initialize(stats.max_health, unit_id)
	movement_component.initialize(starting_coord, map_manager, stats)
	
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.unit_spawned.emit(self)
	print("Unit %s initialized at %s." % [unit_id, starting_coord])

```

#### B. The Health Component

Responsible strictly for tracking vitality and broadcasting state changes. It does not handle visual damage numbers—that will be the job of a UI system listening to the `EventBus`.

```gdscript
# File: res://Core/Components/HealthComponent.gd
class_name HealthComponent extends Node

## Tracks vitality state and processes incoming damage.

var current_health: int = 0
var max_health: int = 0
var _parent_id: StringName

## Injected by the Unit container.
func initialize(in_max_health: int, parent_id: StringName) -> void:
	max_health = in_max_health
	current_health = max_health
	_parent_id = parent_id

## Applies damage and broadcasts the result.
## @param amount: The raw damage integer after armor calculations.
func take_damage(amount: int) -> void:
	if current_health <= 0:
		return # Already dead
		
	current_health -= amount
	current_health = maxi(current_health, 0)
	
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.unit_took_damage.emit(_parent_id, amount, current_health)
	
	if current_health == 0:
		_die()

func _die() -> void:
	# EXTERNAL ACCESS NOTE: Emitting to global EventBus Autoload
	EventBus.unit_died.emit(_parent_id)

```

#### C. The Movement Component

This is where Phase 2's mathematical grid meets the Unit. It asks the `MapManager` for a path and updates the unit's logical coordinate.

```gdscript
# File: res://Core/Components/MovementComponent.gd
class_name MovementComponent extends Node

## Translates pathfinding data into coordinate changes.
## Operates entirely in Vector3i simulation space.

var current_coord: Vector3i = Vector3i.ZERO
var _map_manager: MapManager
var _stats: UnitStats

## Injected by the Unit container.
func initialize(start_coord: Vector3i, map_manager: MapManager, stats: UnitStats) -> void:
	current_coord = start_coord
	_map_manager = map_manager
	_stats = stats

## Evaluates if a target coordinate is within the unit's movement range limit.
func can_reach(target_coord: Vector3i, available_ap: int) -> bool:
	# EXTERNAL ACCESS NOTE: Querying the injected MapManager reference
	var path: Array[Vector3i] = _map_manager.request_path(current_coord, target_coord)
	
	if path.is_empty():
		return false
		
	# Simple AP calculation (can be expanded based on tile weight)
	var max_tiles_allowed: int = available_ap * _stats.base_movement_speed
	
	# -1 because the path array includes the starting tile
	return (path.size() - 1) <= max_tiles_allowed

## Instantly updates the logical coordinate. 
## Visual interpolation (walking animations) will be handled by a separate visual system.
func move_to_coord(target_coord: Vector3i) -> void:
	# EXTERNAL ACCESS NOTE: Querying the injected MapManager reference
	var path: Array[Vector3i] = _map_manager.request_path(current_coord, target_coord)
	
	if path.is_empty():
		push_warning("MovementComponent: No valid path to %s" % target_coord)
		return
		
	# In a WeGo system, execution is instant logically, but visually tweened.
	# For the simulation, we simply update to the final destination.
	current_coord = target_coord
	
	print("Unit moved logically to %s." % current_coord)

```