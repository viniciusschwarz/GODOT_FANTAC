# FANTAC MVP - Simulation Engineering Manual

## 1. Introduction and Global Architecture
FANTAC operates on a strictly decoupled Model-View-Controller (MVC) architecture using Godot 4. The game state and combat rules are resolved entirely in a headless environment, meaning visual nodes (`Node2D`, `TileMapLayer`) never dictate or calculate gameplay logic.

The global neural pathway is the `EventBus` autoload. All cross-system communication (UI to Simulation, Model to View) is handled via strict signals defined in `EventBus`, enforcing a rule that cross-domain `get_node()` pathing is strictly forbidden. The overarching game flow is dictated by the `Phase` enum (INITIALIZATION, PLANNING, SIMULATING, PLAYBACK, MATCH_END) tracked by `MainGameManager`.

## 2. The Micro-Tick Execution Flow (SimulationServer)
The `SimulationServer` is a headless controller instantiated by `MainGameManager`. It receives a `TurnPlanResource` payload, deep-duplicates the `master_units` and `master_matrix`, and processes a rigid 100-step loop (`current_tick` from 0 to 99). It does not yield or wait on visual rendering.

### Step-by-Step Loop Evaluation Order:
1. **Projectile Physics (`CombatEngine.process_projectile_step`):**
   Active projectiles in the buffer have their `current_pos_3d` advanced by their `velocity` vector. Intersections are queried against the `BattlefieldMatrix`.
2. **AI Intent Generation (`AITreeEvaluator.evaluate_unit_behavior`):**
   Every active unit executes its assigned `active_template_id`. The evaluator checks conditions like `current_hp` versus `fallback_health_pct`. Crucially, if `unit.template_parameters["attack_cooldown"]` is greater than 0, the evaluator strictly bypasses `MELEE_ATTACK` and `RANGED_ATTACK` branches, forcing the logic to drop down to `ADVANCE_TO_OBJECTIVE` or `HOLD_ENGAGEMENT`.
3. **Movement Cooldown Resolution:**
   If a unit's intent is to move, the simulation inspects `unit.template_parameters["unit_movement_cooldown"]`. If greater than 0, it is decremented, and spatial movement is skipped. If it reaches 0, a spatial transition is attempted.
4. **Initiative Reservation and Collision (`InitiativeReservationServer.resolve_tile_reservation`):**
   When a unit attempts to step onto a new tile from its `current_path` array, it submits a request to the server. The server calculates an Active Micro-Initiative value using the unit's `base_initiative`, `encumbrance_penalty`, and `unit_id`. If the target `TileSpatialNodeResource` is claimed by another unit on the exact same micro-tick, the higher initiative wins. The loser's `current_path` is cleared, and a `path_recalculation_cooldown` (typically 5 ticks) is applied.
5. **Damage and Morale Resolution:**
   Melee intents check cardinal adjacency. Projectile hit states apply damage based on `weapon_damage` against `current_hp`. Stress is appended (damage * 0.5). If accumulated stress exceeds the unit's fracture threshold (bravery * loyalty), `is_order_fractured` is flagged true.
6. **Tick Snapshot Serialization:**
   At the end of the tick, the server serializes `unit_transform_states`, `unit_hp_states`, `prop_states`, and active projectiles into a `TickSnapshotData` object, appending it to the `TurnReplayBufferResource`.

## 3. Spatial Mechanics, Z-Levels, and Matrix Queries

### BattlefieldMatrix and TileSpatialNodeResource
The `BattlefieldMatrix` holds the 3D spatial grid data. It stores `TileSpatialNodeResource` objects within a 3D Dictionary indexed by `Vector3i(x, y, z)`. The grid dimensions are queried dynamically via `_width` and `_depth` variables. Z-levels are explicitly mapped to floating-point spatial heights (e.g., Z0 = 0.0m, Z1 = 3.0m).

### 3D Line of Sight (LOS) and Cover
LOS is determined via `calculate_3d_line_of_sight()` in `BattlefieldMatrix`. It uses a discrete 3D Digital Differential Analyzer (DDA) raycast.
- The target's precise 3D transform is queried via `intent.target_id` from the active unit map, not integer grid coordinates.
- A 0.0001 epsilon offset is injected into the raycast origin to circumvent floating-point boundary anomalies.
- If the DDA ray traverses a tile where `prop_id != -1` (an intact prop), LOS is immediately intercepted.
- If the target tile possesses a `cover_cardinal_vector` perfectly opposing the incoming vector's ray, the `damage_reduction_pct` variable from the cover data is applied during combat resolution.

### A* Pathfinding and Z-Level Vertical Transitions
The `PathfindingEngine` calculates strictly four-directional navigation routes.
- **Neighbor Generation:** The `_get_valid_neighbors` helper function iterates potential moves. Diagonal validation is hardcoded out.
- **Z-Level Constraints:** Vertical transitions (`abs(dz) == 1`) delegate validation entirely to `BattlefieldMatrix.is_cardinal_passable()`. The bitmask of the target tile is ignored; instead, the function ensures the `vertical_connector_type` (e.g., STAIRS_N) aligns exactly with the unit's cardinal entry vector.
- **Occupancy Skips:** During A* evaluation, if `occupying_unit_id` is not -1 (and is not the requesting unit), the tile is skipped, EXCEPT for the final target destination (allowed for melee adjacency checks) which is subsequently stripped in `_reconstruct_path` to prevent the unit from attempting to physically occupy an enemy's exact square.

## 4. Destructible Tactics and State Persistence

### MultiStagePropResource
Tactical props (like gates) are governed by `MultiStagePropResource`.
When the simulation resolves an attack against a prop, it compares the attacker's `weapon_hardness_rating` against the prop's `material_hardness_threshold`.
- If successful, `current_hp` is deducted.
- If HP hits 0, `current_degradation_state` is mutated to RUBBLE.
- The Matrix clears the `occupying_unit_id`, increases the tile's `base_traversal_cost` (e.g., to 2.0), and destroys any appended Z1 structural tiles found in the prop's `attached_elevated_tile_coords` array.
- This state change is written to `prop_states` inside the `TickSnapshotData` so it persists across simulation turns.

## 5. View Layer Rendering and the Playback Scrubber

### The Render Pipeline (`BattlefieldView`)
The `BattlefieldView` acts exclusively as an observer. It never performs physics calculations or pathing grids.
During the PLAYBACK phase, `UIManager` iterates an `accumulated_playback_time` float in `_process(delta)`. As it steps over integer thresholds, it emits `EventBus.scrubber_tick_changed(target_tick)`.

`BattlefieldView` listens to this signal:
- It queries `TurnReplayBufferResource.tick_snapshots[target_tick]`.
- It iterates the `unit_transform_states` dictionary.
- It applies 2D orthographic screen projection offsets using the formula: `Vector2(grid_x * 64 + 32, grid_y * 64 + 32 + (grid_z * -12))`. Tokens translate between these discrete offsets to visually update.
- Z-level hiding is handled via an `active_z_level` variable. Entities with a Z-coordinate greater than this variable are visually hidden using visibility toggles, allowing players to view lower floors.

### UI Architecture and Player Intents
The UI strictly enforces modularity. Parent controllers (like `UIManager` or `CommanderInspectorUI`) manage dictionary states, while child components are passive signal emitters.
- **Single Prefab Inspector:** Instead of complex UI trees, `CommanderInspectorUI` uses a single dynamic prefab (`UnitCardPrefab`). Upon `EventBus.unit_selected(unit_id)`, the manager reloads this identical node's variables to reflect the active `UnitDataResource`.
- **Intent Drafting:** If a player assigns a new AI behavior, it is stored in a local `draft_directives` dictionary. It does not overwrite the unit resource until `MainGameManager.compile_plan` fires.
- **Spatial Overrides:** Waypoints are logged into `active_waypoints` as a dictionary map (`unit_id: Vector3i`). The view layer draws visual intent lines from the unit's token directly to the target tile's center. When submitted, these directives are funneled into `TurnPlanResource.unit_directives`, which the `SimulationServer` eventually passes into `AITreeEvaluator` to override local behaviors.
- **Morale UI Locks:** If the source `UnitDataResource` flags `is_order_fractured == true`, the UI layer intercepts this flag during the Planning Phase, forces the template OptionButton text to "FRACTURED: UNCONTROLLED", and disables interactions, preventing the player from injecting waypoint overrides on panicked entities.

## 6. Simulation Telemetry and Debug Verification
The headless simulation requires external verification.
- **TurnTelemetryLogger:** Instantiated by `SimulationServer`. It aggregates key logic evaluations (e.g., AITree fallbacks, fractured orders) and deduplicates them using a `_last_logged_event_per_unit` cache mapping. These events are appended into the tick snapshot's `telemetry_events` array. The UI layer scans this array backward to update a `FloatingTelemetryBadge` over unit tokens.
- **Console Differential Dumps:** At tick 99, `MainGameManager.advance_to_next_turn()` triggers a state-commit pipeline. Before scrubbing dead units (setting `occupying_unit_id` to -1 on the master matrix), it explicitly logs the delta between `tick_snapshots[0]` and `tick_snapshots[99]`, documenting HP mutations, spatial coordinate changes, and assigned templates directly into the terminal, ensuring engine validation relies on raw data output rather than visual confirmation.
