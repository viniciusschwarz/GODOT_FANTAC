# FANTAC MVP - Game Design and Architecture Document (TAD)

## 1. CORE GAME MECHANICS & MATHEMATICAL RULES

### The WeGo Combat System

FANTAC operates on a turn-based WeGo system where both allied and enemy units execute their actions simultaneously. The simulation resolves the turn mechanically via a 100-micro-tick engine loop. This micro-tick approach abstracts a continuous simulation into highly granular steps, completely removing turn order biases and strictly governing real-time intersections of movement, projectile physics, and melee attacks.

#### Active Micro-Initiative Formula

When units compete for resolving spatial occupation or evaluating sequential actions within the identical micro-tick interval, the **Active Micro-Initiative** is calculated. The calculation operates on the principle that the *higher* the final floating-point value, the higher the priority of the unit.

The formula is defined as:
`Req_Initiative = Base Initiative - Encumbrance Penalty + (Unit ID * 0.001)`

- **Base Initiative:** Represents the natural speed/reflexes of the unit class (e.g., skirmishers have high base initiative).
- **Encumbrance Penalty:** Represents the drag of armor and heavy weapons, directly subtracting from the initiative.
- **ID Tiebreaker:** The unique deterministic resolver. When two units have identical derived initiative, the unit with the higher integer `unit_id` takes precedence, resolving race conditions.

### The Grid System and Spatial Movement

The battlefield operates on a discrete 3D spatial grid represented by `Vector3i` (12x12x2 grid).

#### 4-Directional Cardinal Movement

Pathfinding strictly relies on four-directional cardinal steps (North, South, East, West). The system evaluates movement across individual tiles. Diagonal traversal is strictly prohibited by base impassability evaluations, which query a tile's bitmask and vertical connectivity rules. The core validation function, `BattlefieldMatrix.is_cardinal_passable()`, enforces a strict coordinate offset sum limit: `abs(dx) + abs(dy) == 1`.

#### Z-Level Transitions

Transitioning vertically between layers (Z0 to Z1, or Z1 to Z0) represents traversing structural stairs and ramps.

A Z-level movement (`abs(dz) == 1`) imposes strict restrictions on the traversal step direction. To ascend or descend, a unit's cardinal direction must exactly align with the orientation of the structural connector (e.g., `TileSpatialNodeResource.VerticalConnectorType.STAIRS_N`). Moving onto a stair-type connector does not cost more Action Points directly; rather, it demands that the transition adheres to the physical spatial alignment of the stairs. The movement cost itself is factored into the unit's `movement_speed_ticks_per_tile` which manages how many micro-ticks it costs to step into the next spatial vector coordinate.

#### Discrete Line-of-Sight (LOS) Raycasting

FANTAC calculates 3D Line-of-Sight using a discrete 3D Digital Differential Analyzer (DDA) voxel traversal algorithm. A 0.0001 epsilon spatial offset is applied to raycast origins to bypass floating-point boundary errors on exact grid intersections. The trace steps voxel-by-voxel from the attacker to the target.

Occlusions are processed as follows:
- Intermediate tiles with structural props (`prop_id != -1`) immediately block LOS.
- Cover states (`CoverType`) on the *target tile* specifically mitigate damage if the incoming attack direction perfectly opposes the cover's cardinal vector.

### Combat Mechanics

#### Weapon Hardness vs. Prop Degradation

Props, like wooden gates or barricades, are active elements inside the battlefield grid simulation. Destruction of props utilizes a material degradation system evaluated via threshold gating rather than pure HP attrition.

When a structural prop is attacked:
1. The engine checks if the attacker's `weapon_hardness_rating` is greater than or equal to the target prop's `material_hardness_threshold`.
2. If the hardness check passes, damage is applied directly to the prop's HP.
3. If the prop HP falls to zero, the prop collapses into `RUBBLE`. This dynamic state shift forces the base traversal cost of the tile to increase (e.g., `base_traversal_cost = 2.0`), visually replaces the prop state, removes LOS occlusion (`prop_id = -1`), destroys any attached elevated tiles (Z1 parapets), and immediately broadcasts `EventBus.navmesh_dirty`.
4. If the hardness check fails, the attack is deflected entirely and zero damage is applied.

#### Projectile Trajectory Interception

Ranged attacks simulate discrete projectile physics every micro-tick in 3D space.
When calculating trajectory intersections per-tick, the engine does not perform a mathematical continuous raycast; instead, it processes discrete voxel step updates based on a 3D velocity vector.

The 2.5D visual abstraction maps Z-levels to concrete physical elevations: `Z0 = 0.0m`, `Z1 = 3.0m`.
A projectile tests interception boundaries against the specific spatial tile it occupies each tick.
- Obstructions range from structural bounds (like `LOW_RAILING` offsetting block heights to `Z + 1.0m`, or `INTACT` props at `Z + 2.5m`). If the projectile's Z-height is less than the obstruction boundary within the current voxel grid, it registers `INTERCEPTED_TERRAIN`.
- Unit collisions test if the projectile is within a strictly aligned vertical slice (`unit_base_z` to `unit_base_z + 1.8m`). If it collides, the state logs `HIT_UNIT` and damage is immediately processed within that tick loop.

---

## 2. SYSTEM ARCHITECTURE & DATA FLOW (THE PIPELINE)

The architectural structure obeys a strictly enforced unidirectional Model-View-Controller (MVC) paradigm ensuring that Game State remains pure, decoupled, and highly deterministic.

### The Data Flow Pipeline

1. **Input (Planning Phase):**
   - The user interfaces with the `BattlefieldView` and `UIManager` to inject active waypoint intents (`active_waypoints`) and override AI directives via the `CommanderInspectorUI`.
   - Once all intents are validated, `MainGameManager` compiles these directives into a `TurnPlanResource`.

2. **Processing (Simulation Phase):**
   - `TurnPlanResource` acts as the payload submitted to the `SimulationServer`.
   - The `SimulationServer` is completely headless. It deep-copies the `master_units` and `master_matrix`, and loops through the 100-micro-tick state machine. It does not wait on UI signals, does not yield to rendering trees, and resolves the entirety of the combat turn instantaneously in memory.

3. **Output (Serialization):**
   - As the simulation completes its 100 loops, it serializes positional transforms, states, and projectile metadata into a `TurnReplayBufferResource`, an array of 100 distinct `TickSnapshotData` resources.
   - Once compilation is complete, the `SimulationServer` garbage-collects itself and emits the replay buffer.

4. **Rendering (Playback Phase):**
   - The global `UIManager` engine captures the buffer and updates an `accumulated_playback_time` variable in `_process(delta)`.
   - As the time counter steps over micro-ticks, it emits `EventBus.scrubber_tick_changed`.
   - The `BattlefieldView` purely observes the tick counter and directly manipulates the transforms and visibilities of tokens according to the data inside the active `TickSnapshotData`. The view layer never computes its own grid logic.

### UI Constraint Policies
The UI strictly limits itself to issuing commands and recording telemetry. It never directly updates a `UnitDataResource` or mutates the `BattlefieldMatrix`. Action intents are exclusively funneled via `UIDirectivePayloads` through the `EventBus` to delay any real state execution until the headless simulation server runs.

---

## 3. DATA CONTRACTS (RESOURCE SCHEMAS)

Game data relies entirely on custom Godot Resources (`.tres`) instead of instancing scene nodes. The following defines the critical field structures of the primary data contracts:

### `UnitDataResource`
Tracks unit combat stats, state flags, and dynamically calculated AI parameters.
```gdscript
@export var unit_id: int = -1
@export var faction_id: Faction = Faction.ALLIED
@export var current_hp: float = 100.0
@export var current_stress: float = 0.0
@export var movement_speed_ticks_per_tile: int = 10
@export var weapon_damage: float = 10.0
@export var weapon_hardness_rating: float = 0.0
@export var damage_application_tick_offset: int = 10
@export var is_order_fractured: bool = false
@export var active_template_id: StringName = &""
@export var template_parameters: Dictionary = {} # Stores dynamic cooldowns, objective goals, current path arrays.
```

### `TileSpatialNodeResource`
Defines 3D traversal costs, occupancy IDs, and cover masking rules on the battlefield grid.
```gdscript
@export var grid_position: Vector3i = Vector3i.ZERO
@export var base_traversal_cost: float = 1.0
@export var vertical_connector_type: VerticalConnectorType = VerticalConnectorType.NONE
@export var cardinal_traversal_mask: int = 15 # N, S, E, W Bitmask rules
@export var cover_type: CoverType = CoverType.NONE
@export var cover_cardinal_vector: Vector2i = Vector2i.ZERO # The exact facing direction of the parapet/wall
@export var damage_reduction_pct: float = 0.0
@export var occupying_unit_id: int = -1
@export var reserved_unit_id: int = -1
@export var reservation_micro_tick: int = -1
@export var prop_id: int = -1
```

### `TickSnapshotData`
The exact dictionary structures capturing a single slice of time in the micro-tick engine.
```gdscript
@export var micro_tick_index: int = 0
@export var unit_transform_states: Dictionary = {} # int unit_id -> Vector3i coordinate
@export var unit_hp_states: Dictionary = {} # int unit_id -> float hp
@export var unit_stress_states: Dictionary = {} # int unit_id -> float stress
@export var prop_states: Dictionary = {} # int prop_id -> int degradation_state (0 = INTACT, 1 = DAMAGED, 2 = RUBBLE)
@export var active_projectiles: Array[Dictionary] = [] # Projectile payload: { id, source_id, current_pos_3d, velocity }
@export var telemetry_events: Array[Dictionary] = [] # UI event payload: { tick, msg, unit_id, major_event_flag }
```

---

## 4. THE HEADLESS SIMULATION SERVER (DEEP DIVE)

The `SimulationServer` evaluates the game state by progressing an internal integer `current_tick` from 0 to 99 in a single synchronous blocking loop. State mutation occurs exclusively on isolated dictionary copies to maintain absolute mathematical determinism.

### The 100-Micro-Tick Loop Execution Order

**A. Projectile Physics processing:**
Existing active projectiles are updated by their `velocity` vector. Intersections against terrain occlusions (based on physical Z-height blocks) or unit `unit_base_z` bounds dictate immediate destruction or scheduling a hit payload.

**B. `AITreeEvaluator` condition checks:**
For all active units, the AI engine processes branch logic (e.g., fallback hysteresis, targeting checks) and returns an action `intent`. Intended Ranged attacks immediately serialize a projectile object into the pool on the tick they evaluate.

**C. Movement Cooldown Processing:**
If an intent is an objective movement type, it decrements the active `unit_movement_cooldown` mapped within the unit's `template_parameters`. Units actively locked in a cooldown skip movement execution.

**D. `InitiativeReservationServer` Collision Resolution:**
If a unit completes its movement cooldown and requests an empty tile via `PathfindingEngine` step arrays, it validates against the `InitiativeReservationServer`.
- **Method Signature:** `resolve_tile_reservation(tile: TileSpatialNodeResource, requesting_unit: UnitDataResource, units_map: Dictionary, micro_tick: int) -> int` (returns 1 for success).
- If two units attempt to cross the same vector coordinate in the same tick interval window, the system evaluates the **Active Micro-Initiative**. The winning unit secures a tile lock (`reserved_unit_id`) spanning their micro-tick movement cost duration. The loser suffers a hard rejection: the reservation server clears their path array, forces a 5-tick `path_recalculation_cooldown` penalty, and resets the unit movement cooldown.

**E. Damage Application and Morale Checks:**
Scheduled melee strikes (triggered by spatial cardinal adjacency and matched Z-levels) or projectile collisions are verified. Reductions in unit HP actively trigger stress generation in parallel (`dmg * 0.5`).
- **Fracture Check:** If accumulated stress exceeds `bravery_rating * loyalty_rating`, the unit immediately suffers a morale failure. `is_order_fractured` triggers true, instantly purging any scheduled attacks or move reservations, forcing the AI to evaluate an `UNCONTROLLED_FALLBACK` branch next tick. Nearby allied units suffer a 15.0 passive stress shockwave if an entity hits 0 HP.

**F. Snapshot Serialization:**
The server collects the precise positional states, HP/Stress meters, prop degradation mappings, and active telemetry logs, committing them into a `TickSnapshotData` instance appended to the `TurnReplayBufferResource`.

---

## 5. GLOBAL SYSTEMS & EVENT BUS DICTIONARY

The `EventBus` (`scripts/autoloads/event_bus.gd`) acts as the exclusive neural pathway for interconnecting isolated systems.
Cross-domain node-pathing (`get_node("../AnotherSystem")` or `owner.get_node()`) is **strictly forbidden**.

### Critical EventBus Signatures

**Turn Flow & Phasing:**
- `signal phase_changed(new_phase: Phase)` (Phase Enum: INITIALIZATION, PLANNING, SIMULATING, PLAYBACK, MATCH_END)
- `signal plan_submitted(plan: TurnPlanResource)`
- `signal turn_simulation_completed(replay_buffer: TurnReplayBufferResource)`
- `signal grid_initialized(matrix: BattlefieldMatrix)`

**Playback & UI Hooks:**
- `signal scrubber_tick_changed(target_tick: int)`
- `signal playback_state_changed(is_playing: bool, speed_multiplier: float)`
- `signal unit_selected(unit_id: int)`
- `signal tile_right_clicked(selected_unit_id: int, grid_coord: Vector3i)`

**Simulation & Environment Feedback:**
- `signal navmesh_dirty(tile_coord: Vector3i)`
- `signal prop_state_changed(prop_id: int, new_state: int)`

---

## 6. STRICT UI/UX TECHNICAL IMPLEMENTATION

The User Interface operates under absolute modularity and strict isolation rules.

### Render Pipeline
UI systems never directly manipulate engine data. A `FloatingTelemetryBadge` tracking a unit scans backward through the `TurnReplayBufferResource` tick history, looking for specific dictionary key matches (`unit_id`, `major_event_flag`, `telemetry_text`) at the designated timeline index to dynamically update textual reporting. Screen projection offsets for 3D coordinates rely explicitly on formulas like `Vector2(grid_x * 64 + 32, grid_y * 64 + 32 + (grid_z * -12))` utilizing the viewport's active transform canvas.

### Logic Centralization and Drag-and-Drop
Component interfaces strictly isolate layout configurations from behavior logic.
- Child UI slot controls (like a specific inventory square or directive parameter) **never process** state changes. They only act as passive visual blocks that transmit raw interaction signals (e.g., `pressed(self.id)`).
- Parent UI Managers (e.g., `UIManager` or `CommanderInspectorUI`) subscribe to those signals to exclusively evaluate state changes, execute drag-and-drop mechanics, update global dictionaries, or dispatch external `EventBus` events.

### Dynamic Prefab Construction
FANTAC employs a strictly "single-prefab" structural rule for UI elements.
Instead of hardcoding extensive rosters into massive panel layouts, the UI relies on singular dynamically generated blocks. For example, instead of storing individual cards for all active allied units on screen, a single dynamic `CommanderInspectorUI` is injected by the UI Manager. When `unit_selected` is triggered, that single generic prefab parses the respective `UnitDataResource` and reloads all labels and icons, maintaining optimal draw-call efficiency and ensuring complete isolation between the scene hierarchy and active entity caches.
