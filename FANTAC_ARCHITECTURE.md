# FANTAC: Exhaustive Engineering Logic and Architecture Document

## 1. Exhaustive Script-by-Script Breakdown

### 1.1 Core Management (`scripts/core/`)

**`main_game_manager.gd`**
* **Primary Responsibility:** Orchestrates the macro turn-flow loop, manages the phase state machine, and evaluates match win/loss conditions. It is the bridge between the UI planning and headless simulation execution.
* **Core Methods:**
    * `initialize_match(matrix, units)`: Instantiates the `TurnReplayBufferResource` for Tick 0 (initial state), emits `match_started`, and enters the `PLANNING` phase.
    * `enter_planning_phase()`: Instantiates an empty `TurnPlanResource`, unlocking the UI.
    * `execute_simulation(plan)`: Locks the UI. Instantiates the `SimulationServer`, passes the plan and dictionaries, and awaits the returned `TurnReplayBufferResource`.
    * `enter_playback_phase(buffer)`: Receives the output buffer and transitions to the `PLAYBACK` phase, allowing the UI Scrubber to begin.
    * `advance_to_next_turn(buffer)`: Replaces the start state (Tick 0) with the end state (Tick 99) via `commit_simulation_state`. Checks if the Allied faction controls coordinate `(6,11,1)` to trigger `match_ended(true)`. Loops back to `enter_planning_phase()` if turn < 5.
    * `commit_simulation_state(start_snapshot, final_snapshot)`: Deep copies `unit_template_states` back to the live `master_units`. Exclusively processes unit death (HP <= 0), permanently erasing them from `master_units` and clearing their `occupying_unit_id` from the matrix. Updates live unit positions and prop degradation states.
* **Dependencies & Injections:** Relies on `SimulationServer` instantiation. Communicates heavily via `EventBus`. Modifies `BattlefieldMatrix`.

**`scenario_loader.gd`**
* **Primary Responsibility:** Handles one-time dependency injection and initial state loading.
* **Core Methods:**
    * `_ready()`: Instantiates the `BattlefieldMatrix`, loads predefined `.tres` data presets, invokes `duplicate_data()` to create unique runtime instances, forcibly maps units to their starting `Vector3i` coordinates in the matrix and their internal `template_parameters`, and passes the populated dictionaries to `MainGameManager`.
* **Dependencies & Injections:** Depends on external `.tres` files (e.g., `vanguard_preset.tres`, `wooden_gate_preset.tres`). Bootstraps `MainGameManager`.

**`battlefield_matrix.gd`**
* **Primary Responsibility:** The central memory authority for spatial state. Manages a 3D Dictionary of `TileSpatialNodeResource` objects.
* **Core Methods:**
    * `initialize_grid(width, depth, height_levels)`: Creates the blank voxel matrix.
    * `get_tile(coord)`: Safe getter for tile boundaries.
    * `is_cardinal_passable(from_coord, to_coord)`: Computes strict orthogonal movement validation (`abs(dx) + abs(dy) == 1`). If `dz != 0`, evaluates vertical transitions by strictly enforcing the presence of corresponding `STAIRS` properties on the Z0 tile.
    * `calculate_3d_line_of_sight(origin, target)`: Executes a discrete 3D DDA (Digital Differential Analyzer) raycast, offset by a `0.0001` epsilon, checking for structural props (`prop_id`) or evaluating `SOLID_PARAPET` dot-product alignment on the final target tile.
    * `apply_prop_damage(prop_id, amount, hardness)` / `collapse_prop(prop_id)`: Deflects damage if `hardness` is less than `material_hardness_threshold`. If destroyed, sets traversal cost to `2.0` (Rubble), clears LOS occlusion, destroys attached Z1 tiles, and emits `navmesh_dirty`.
* **Dependencies & Injections:** Generates and holds `TileSpatialNodeResource` and `MultiStagePropResource` instances.

### 1.2 Simulation Engine (`scripts/sim/`)

**`simulation_server.gd`**
* **Primary Responsibility:** The core WeGo execution environment. Evaluates the turn entirely in memory using a 100-tick loop. No visual rendering or UI wait-states occur here.
* **Core Methods:**
    * `run_turn_simulation(plan, initial_matrix, initial_units)`: Duplicates the live matrix and unit dictionaries. Executes the massive `for current_tick in range(100)` loop. Collects and serializes a `TickSnapshotData` object per tick. Garbage collects itself when complete.
    * `check_morale_fracture(unit, current_tick...)`: Checks if `current_stress >= (bravery * loyalty)`. If true, purges scheduled attacks, purges A* paths, flips `is_order_fractured = true`, and hard-forces the AI branch into `UNCONTROLLED_FALLBACK`.
    * `_cleanup_dead_units()`: Handles real-time death mid-simulation loop. Instantly emits a 15.0 passive stress shockwave to allied units within a 3-tile Manhattan distance and clears spatial occupancy to prevent pathfinding ghost collisions.
* **Dependencies & Injections:** Instantiates `CombatEngine`, `AITreeEvaluator`, `InitiativeReservationServer`, `PathfindingEngine`, and `TurnTelemetryLogger`.

**`pathfinding_engine.gd`**
* **Primary Responsibility:** Calculates discrete A* paths restricted strictly to cardinal movement.
* **Core Methods:**
    * `calculate_path(matrix, start, target, unit_data)`: Runs standard A*. Temporarily ignores target tile occupancy to permit adjacency routing for melee.
    * `_get_valid_neighbors()`: Evaluates valid steps using `matrix.is_cardinal_passable()`. Costs vary (Ground: `1.0`, Stairs: `1.5`, Rubble: `2.0`). Blocks nodes occupied by standard units (`+50.0` or skipped entirely).
    * `_reconstruct_path()`: Rebuilds the path array, intentionally popping the start node (to avoid self-reserving the current tile) and conditionally popping the final node if the destination targets an occupied enemy (stopping adjacent).
* **Dependencies & Injections:** Reads `BattlefieldMatrix` strictly for data checks.

**`initiative_reservation_server.gd`**
* **Primary Responsibility:** Resolves exact-frame race conditions between units entering the same coordinate.
* **Core Methods:**
    * `resolve_tile_reservation(tile, requesting_unit, units_map, micro_tick) -> int`: Evaluates `Active Micro-Initiative`. If the tile is unreserved, writes a reservation lock based on the unit's `movement_speed_ticks_per_tile`. If a collision occurs, the loser has their path array destroyed and suffers a 5-tick `path_recalculation_cooldown`. Returns `1` (Success) or `0` (Failure).
* **Dependencies & Injections:** Passive evaluator. Mutates `TileSpatialNodeResource` occupancy flags.

**`combat_engine.gd`**
* **Primary Responsibility:** Steps ballistic projectiles through space and resolves melee adjacency.
* **Core Methods:**
    * `process_projectile_step(projectile, matrix, units_map)`: Iterates a projectile by its `velocity` vector. Compares exact Z-heights against terrain limits (`Z + 2.5m` for intact props, `Z + 1.8m` for parapets). If it clips a unit's bounds (`unit_base_z` to `unit_base_z + 1.8m`), returns a `HIT_UNIT` state. Clamps ground collisions at `Z <= 0.0`.
    * `resolve_melee_attack()`: Validates `abs(dx) + abs(dy) == 1` and `dz == 0`. Schedules a `MELEE_SCHEDULED` event deferred by `damage_application_tick_offset`.
* **Dependencies & Injections:** Reads `BattlefieldMatrix` for physical grid blocking limits.

**`turn_telemetry_logger.gd`**
* **Primary Responsibility:** Records string-based debug and UI logs deduplicating rapid micro-tick spam.
* **Core Methods:**
    * `log_ai_decision`, `log_movement`, `log_rejection`, `log_ui_intent`: Uses `_deduplicate()` to ensure the same AI loop printing the exact same condition across 10 ticks only logs once to the `TurnReplayBufferResource`.

### 1.3 AI Engine (`scripts/ai/`)

**`ai_tree_evaluator.gd`**
* **Primary Responsibility:** The stateless decision engine for unit behaviors. Processes dynamic branches.
* **Core Methods:**
    * `evaluate_unit_behavior(unit, matrix, all_units, current_tick, plan)`: Evaluates the `TurnPlanResource` overrides first. If no override, checks `fallback_lock_until_tick` for hysteresis. Processes specific templates (`AGGRESSIVE_ASSAULT`, `CAUTIOUS_OVERWATCH`, `POINT_GUARD`) via if/elif/else blocks to output an intent.
    * `evaluate_ranged_attack(unit, unit_coord, matrix, ranged_targets)`: Modular helper function checking minimum/maximum ranges and line-of-sight simultaneously for templates that permit ranged fire.
* **Dependencies & Injections:** Instantiated within `SimulationServer`.

### 1.4 User Interface (`scripts/ui/`)

**`ui_manager.gd`**
* **Primary Responsibility:** Centralized UI catcher and data proxy.
* **Core Methods:**
    * `_on_simulate_pressed()`: Compiles local `active_waypoints` and `draft_directives` dictionaries into the `TurnPlanResource` and emits `plan_submitted`. Locks input.
    * `_on_tile_right_clicked(unit_id, grid_coord)`: Intercepts spatial grid clicks. If clicking an enemy, generates an `"ATTACK"` directive in `active_directives`. If clicking empty space, generates a `Vector3i` in `active_waypoints`. Overwrites previous intents to enforce the 1-intent MVP rule.
    * `_process(delta)`: During playback, increments `accumulated_playback_time`. Emits `scrubber_tick_changed` to sync the global engine to a specific integer tick.
* **Dependencies & Injections:** Heavily utilizes `EventBus` to bypass node hierarchy limits.

**`commander_inspector_ui.gd`**
* **Primary Responsibility:** The singular dynamic visual prefab (`unit_card_prefab.tscn`) displaying the currently selected unit.
* **Core Methods:**
    * `_on_unit_selected(unit_id)`: Clears all previous visual data from the generic prefab, looks up `unit_id` in `master_units`, and maps `max_hp`, `current_stress`, and valid `AITemplateResource` names to the labels. Disables UI bindings if `is_order_fractured` is true.
    * `_sync_playback_state(tick)`: Listens to the scrubber integer and updates the HP/Stress progress bars dynamically based on the snapshot data, ensuring the UI tracks real-time damage exactly as the view layer does.

### 1.5 View Layer (`scripts/view/`)

**`battlefield_view.gd`**
* **Primary Responsibility:** Pure 2D renderer mapping `Vector3i` coordinates to screen-space `Vector2`.
* **Core Methods:**
    * `paint_debug_grid(matrix)`: Procedurally generates `128x64` textures using `Image.create` without loading external `.png` files, mapping colors to Z0 (Green) and Z1 (Gray) across a `TileSetAtlasSource`.
    * `_initialize_tokens_from_buffer(replay_buffer)`: Spawns exactly one visual token for every unit/prop located in the Tick 0 snapshot.
    * `_on_scrubber_tick_changed(target_tick)`: Fetches the `unit_transform_states` coordinate for the given tick. Moves tokens visually. Applies a `Z1_VISUAL_Y_OFFSET` of `-12.0` pixels if the Z-axis is `1`. Hides tokens completely if their Z-axis is above the user's `active_z_level` (Q/E toggle).
    * `_redraw_intent_lines()`: Parses `active_waypoints`. Draws a straight `Line2D` from the visual screen position of the unit token to the absolute center of the target tile coordinates, bypassing Manhattan geometric rendering.
* **Dependencies & Injections:** Safe-reads `TurnReplayBufferResource` and `BattlefieldMatrix`. Emits `unit_selected` via `_unhandled_input()`.

---

## 2. The Nervous System (Event Bus & Signals Mapping)

Every critical state transition routes through `res://scripts/autoloads/event_bus.gd`. No system communicates using relative `.get_node()` paths across domains.

| Signal Name | Emitted By (Script) | Listened To By (Scripts) | Payload Exchanged |
| :--- | :--- | :--- | :--- |
| `phase_changed` | `MainGameManager` | `UIManager`, `BattlefieldView`, `CommanderInspectorUI` | `EventBus.Phase` (Enum) |
| `turn_simulation_completed` | `MainGameManager` / `SimulationServer` | `UIManager`, `BattlefieldView`, `CommanderInspectorUI` | `TurnReplayBufferResource` |
| `plan_submitted` | `UIManager` | `MainGameManager` | `TurnPlanResource` |
| `playback_completed` | `UIManager` | `MainGameManager` | *None* |
| `grid_initialized` | `MainGameManager` | `BattlefieldView`, `UIManager` | `BattlefieldMatrix` |
| `match_started` | `MainGameManager` | `BattlefieldView` | `BattlefieldMatrix`, `master_units` (Dict) |
| `match_ended` | `MainGameManager` | (Future Resolution Panels) | `allied_won` (bool) |
| `scrubber_tick_changed`| `UIManager` | `BattlefieldView`, `CommanderInspectorUI` | `target_tick` (int) |
| `playback_state_changed`| `UIManager` | *System wide UI listeners* | `is_playing` (bool), `speed_multiplier` (float) |
| `unit_selected` | `BattlefieldView` | `UIManager`, `CommanderInspectorUI` | `unit_id` (int) |
| `tile_right_clicked` | `BattlefieldView` | `UIManager` | `selected_unit_id` (int), `grid_coord` (Vector3i) |
| `navmesh_dirty` | `BattlefieldMatrix` | (Future Grid Regenerators) | `tile_coord` (Vector3i) |
| `prop_state_changed` | `BattlefieldMatrix` | (Future View Decals) | `prop_id` (int), `new_state` (int) |

---

## 3. Mechanics & Algorithms: Deep Dive

### 3.1 The 100-Micro-Tick Synchronization Loop
In `SimulationServer.run_turn_simulation()`, the server executes a single thread that blocks Godot's process loop entirely until `100` iterations complete.

**Execution Order Algorithm:**
1. **A. Projectiles:** `pos = pos + velocity`. Z-bounds clamped at `0.0`. Immediate bounding-box calculation against `unit_base_z` (`Z * 3.0`) + `1.8m`. If intercepted, instantly processes damage payload.
2. **B. AITreeEvaluator:** Pulls from `working_units`. Overrides templates if `is_order_fractured`. Returns an Intent dictionary (`action_type`, `target_coord`).
3. **C. Movement Cooldown:** Checks `unit_movement_cooldown`. `IF cooldown > 0`: `cooldown -= 1`, `CONTINUE` (skip physics this tick). `ELSE`: proceed to Step D.
4. **D. Initiative Reservation:** Grabs the 0th index from the unit's A* path array. Passes it to `InitiativeReservationServer`. If `1` (Success), `path_array.pop_front()`, updates the unit's internal `last_coord` states, assigns `occupying_unit_id` to the new tile, clears the old tile, and resets `unit_movement_cooldown` back to `movement_speed_ticks_per_tile` (e.g., `10`).
5. **E. Combat Processing:** Decrements scheduled melee events. If `current_tick >= application_tick`, subtracts `weapon_damage` from `current_hp`.
    - *Simultaneous Tie-Breaker:* Two units swinging at each other on the identical tick BOTH calculate damage successfully. If BOTH fall below 0 HP, BOTH die at the exact same tick.
    - *Stress Math:* `Stress += (Damage * 0.5)`. `IF Stress >= (Bravery * Loyalty)` -> Fracture Order.
6. **F. Serialization:** Appends the exact states into `TickSnapshotData`.

### 3.2 Active Micro-Initiative (The Tie-Breaker Formula)
When two units request the same `TileSpatialNodeResource` inside `InitiativeReservationServer` at the exact same tick, the system resolves the collision deterministically:
`req_initiative = base_initiative - encumbrance_penalty + (unit_id * 0.001)`
`res_initiative = reserver.base_initiative - reserver.encumbrance_penalty + (reserver.unit_id * 0.001)`

* **IF `req_initiative > res_initiative`:** The requesting unit steals the tile lock. The existing reserver receives a hard rejection, setting `reserver.is_path_blocked = true`, and their `recalculation_cooldown_ticks` is forcibly set to `5`.
* **ELSE:** The requesting unit is rejected and receives the 5-tick penalty instead.
By injecting `(unit_id * 0.001)`, it guarantees impossible mathematical ties, ensuring the lowest engine-level ID acts as the absolute ultimate tie-breaker.

### 3.3 Prop Degradation Threshold Logic
When a unit attacks a wooden gate prop (`MultiStagePropResource`):
1. `BattlefieldMatrix.apply_prop_damage(amount, hardness)` evaluates.
2. `IF hardness >= material_hardness_threshold` (e.g., broadsword rating `6.0` vs wood rating `5.0`): The attack succeeds. `current_hp -= amount`.
3. `IF hardness < material_hardness_threshold`: The attack bounces harmlessly and deals `0` damage.
4. If HP <= 0, the state transitions explicitly to `DegradationState.RUBBLE`. The underlying tile's `base_traversal_cost` jumps to `2.0`, and `prop_id` is set to `-1`, instantly dissolving LOS blocking rules.

---

## 4. Exhaustive State, Resources, and Variable Dictionary

### 4.1 Custom Resources (The Data Model)

**`UnitDataResource`**
Stores static profile constants and volatile combat flags.
* `unit_id` (int): Absolute identifier.
* `faction_id` (Enum): `0` = Allied, `1` = Enemy.
* `current_hp` (float) / `current_stress` (float): Tracked linearly. Modified during Step E (Combat Processing) in the Simulation Server.
* `base_initiative` (int) / `encumbrance_penalty` (float): Constants used by the `InitiativeReservationServer`.
* `movement_speed_ticks_per_tile` (int): Determines the physical reset value of `unit_movement_cooldown` (i.e. how many micro-ticks it takes to step 1 spatial coordinate).
* `is_order_fractured` (bool): Flipped in `SimulationServer`'s `check_morale_fracture()` if stress threshold fails.
* `template_parameters` (Dictionary): The most volatile variable in the engine. It is the unit's local memory stack, holding keys like:
    * `"unit_movement_cooldown"`: Decrements every tick in Step C.
    * `"attack_cooldown"`: Decrements every tick. Halts AI combat decisions when > 0.
    * `"fallback_lock_until_tick"`: Used for AI hysteresis to lock behaviors.
    * `"current_path"` (Array[Vector3i]): The active A* path execution array.
    * `"last_coord_x / y / z"` (int): Defines absolute positional reality before state commits back to the matrix.

**`TileSpatialNodeResource`**
Defines grid properties.
* `base_traversal_cost` (float): Cost multiplier for A*. Mutates to `2.0` when a prop is destroyed.
* `cardinal_traversal_mask` (int): Bitmask (1=N, 2=S, 4=E, 8=W).
* `vertical_connector_type` (Enum): Required for Z-transitions (e.g. `STAIRS_N`).
* `occupying_unit_id` (int): Shifted exactly in Step D when a unit successfully completes movement cooldown.
* `reserved_unit_id` (int) / `reservation_micro_tick` (int): Written/overwritten exclusively by `InitiativeReservationServer` during collision checks.

**`TurnReplayBufferResource` & `TickSnapshotData`**
* `tick_snapshots` (Array[`TickSnapshotData`]): Sized explicitly to 100 entries by the Simulation Server.
* `unit_transform_states` (Dictionary): Maps `unit_id` -> `Vector3i`. Overwritten at the bottom of the Tick Loop (Step F).
* `unit_template_states` (Dictionary): Maps `unit_id` -> a deep duplication of `unit.template_parameters` to ensure cooldowns perist across turns when `MainGameManager.commit_simulation_state()` runs at Tick 99.

### 4.2 Manager & UI States

**`MainGameManager` States**
* `current_phase` (`EventBus.Phase`): Mutates based on function calls from `INITIALIZATION` -> `PLANNING` -> `SIMULATING` -> `PLAYBACK` -> `PLANNING` or `MATCH_END`.
* `master_units` (Dictionary): The single source of truth for living units. Mutated only in `scenario_loader` and `commit_simulation_state` (where `erase()` purges dead IDs).

**`UIManager` States**
* `active_waypoints` (Dictionary): Maps `unit_id` -> `Vector3i`. Stores manual movement clicks. Created in `_on_tile_right_clicked`. Appended to `TurnPlanResource.unit_objectives`. Emptied explicitly in `_on_phase_changed(PLANNING)`.
* `draft_directives` (Dictionary): Maps `unit_id` -> `StringName` (e.g., `"CAUTIOUS_OVERWATCH"`). Stores AI dropdown selections until "Simulate" merges them into the turn plan.
* `accumulated_playback_time` (float): Mutates in `_process(delta)` during `PLAYBACK`. Tracks visual real-time and casts to an `int` to emit `scrubber_tick_changed`.

**`SimulationServer` States**
* `working_units` (Dictionary): A deep duplication of `master_units`. Exists exclusively within the memory scope of `run_turn_simulation`. Mutated wildly across all 100 ticks.
* `working_matrix` (BattlefieldMatrix): A deep duplication of `master_matrix`. Tracks instantaneous spatial occupations and prop degradations in a vacuum.
* `active_projectiles` (Array[Dictionary]): Holds volatile dictionaries mapping `pos_3d`, `velocity`, and `damage`. Flushed if a projectile intercepts terrain. Duplicated into `TickSnapshotData` every tick.
* `scheduled_melee_events` (Array[Dictionary]): Holds deferred damage instructions mapping an attacker, defender, and `application_tick`. Polled every loop; triggers damage when `current_tick >= application_tick`. Cleared if the attacker suffers an order fracture before the tick arrives.