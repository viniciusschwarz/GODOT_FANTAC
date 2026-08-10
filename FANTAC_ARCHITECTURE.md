# FANTAC: Engineering Logic and Architecture Document

## 1. Executive Summary (The "What" and "Why")

FANTAC is a 2D top-down, WeGo tactical simulation engine built in Godot 4.x. It executes turn-based battles where both allied and enemy units process their actions simultaneously in a headless, deterministic simulation across 100 discrete "micro-ticks." Its primary role is to separate the heavy, concurrent combat logic and pathfinding from the visual rendering pipeline, ensuring that game states are mathematically pure and replayable via a decoupled model-view-controller paradigm.

## 2. Architecture & Data Flow (The "How")

### High-Level Architecture
FANTAC employs a strict Data-Driven, Model-View-Controller (MVC) architecture. It relies entirely on custom Godot Resources (`.tres`) for data contracts and completely separates the headless logic loop from visual representations.

- **The Model (Headless Simulation Server):** Evaluates pathfinding, AI logic, and combat physics in a vacuum. It uses no Godot scene nodes (like Node2D or Tween) and calculates everything mathematically in memory.
- **The View (Battlefield View):** A passive listener that reads coordinate data from simulation snapshots and moves sprites. It never computes logic.
- **The Controller (UI Manager / Event Bus):** Catches user inputs, emits data payloads via a central global event broker (`EventBus`), and controls phase transitions without mutating core unit data.

### Data Flow Pipeline
1. **Input Generation (Planning Phase):** The player clicks the UI to assign waypoints and AI behavior overrides. `UIManager` stores these in dictionaries without altering the active game state. When "Simulate" is pressed, these inputs are bundled into a `TurnPlanResource`.
2. **Headless Execution (Simulating Phase):** `MainGameManager` hands the `TurnPlanResource` to the `SimulationServer`. The server loops synchronously 100 times (ticks 0-99). It copies `master_units` and the `master_matrix` to ensure absolute determinism.
3. **Serialization:** At the end of every micro-tick, the exact spatial coordinates, HP levels, and telemetry events are recorded into a `TickSnapshotData`. The 100 snapshots form a `TurnReplayBufferResource`.
4. **Playback rendering (Playback Phase):** The UI scrubber progresses through time, emitting the current tick integer. The View layer simply reads the active tick from the `TurnReplayBufferResource` and explicitly snaps visual token positions and UI badges to match the serialized state.

### Separation of Concerns
UI components defer all complex logic upward. A single dynamic prefab (`CommanderInspectorUI`) handles visual updates for whatever unit is selected, eliminating massive roster overhead. Actions like movement or combat are not executed when the player clicks; they are merely injected as "intents" into the turn plan, preserving the strict WeGo simultaneity.

## 3. Core Mechanics & Intricate Logic (Step-by-Step)

### The 100-Micro-Tick Engine Loop
During the Simulation Phase, the server runs a strict loop from Tick 0 to Tick 99. Inside *each single tick*, the logic evaluates in this exact chronological order:

1. **Step A (Ballistics & Projectiles):** The `CombatEngine` moves existing projectiles along a 3D vector. It evaluates their precise discrete physical location against terrain blocks or unit hitboxes. If a collision occurs, damage is applied instantly.
2. **Step B (AI Intent Generation):** The `AITreeEvaluator` evaluates every unit's active behavior template (e.g., `AGGRESSIVE_ASSAULT`).
    - It checks if a player manual directive (like an attack intent) overrides the AI.
    - It evaluates conditional logic: "Am I below 15% HP? If so, lock me into a fallback state for 15 ticks to prevent indecisive logic loops."
    - It outputs a unified *Action Intent* (e.g., `ADVANCE_TO_OBJECTIVE`, `MELEE_ATTACK`, `RANGED_ATTACK`).
3. **Step C (Movement Cooldowns):** If a unit intends to move, the engine checks their `unit_movement_cooldown`. If greater than zero, it is decremented, and the unit holds still. This cooldown (e.g., 10 ticks per tile) acts as their physical travel time across the grid.
4. **Step D (Tile Reservation & Collision):** If the movement cooldown hits zero, the unit requests the next coordinate in its A* path array from the `InitiativeReservationServer`.
    - *The Tie-Breaker:* If two units attempt to step into the exact same tile at the exact same tick, their `Active Micro-Initiative` is calculated (`Base Initiative - Encumbrance + (ID * 0.001)`).
    - The winner gets the tile reservation. The loser receives a "blocked" status, their path is cleared, and they are forced into a 5-tick hesitation penalty before they can recalculate a new path.
5. **Step E (Combat Resolution & Morale):** Adjacent melee attacks are processed. Damage immediately subtracts HP. Simultaneously, taking damage applies "Stress." If a unit's stress exceeds their bravery threshold, they suffer an "Order Fracture"—they drop all attack intents and are forced into panic mode.
6. **Step F (Snapshot Serialization):** The precise state of the board is saved into the tick snapshot for later playback.

### 4-Directional 3D A* Pathfinding
The `PathfindingEngine` evaluates standard A* but strictly forbids diagonal movement. When evaluating neighbors:
- **X/Y Plane:** It checks a tile's bitmask (`cardinal_traversal_mask`) to ensure movement isn't blocked by walls.
- **Z-Axis Transitions:** It enforces that vertical movement is only valid if the tile possesses a specific structural connector (e.g., `STAIRS_N`). The traversal cost increases slightly to simulate climbing.

## 4. Dependency Mapping & Interactions

### External Dependencies
FANTAC is built with pure GDScript 2.0 and Godot Custom Resources. It intentionally avoids Godot's built-in physics engine, AStar2D/3D nodes, and Node tweens for core logic, ensuring absolute deterministic control over the simulation.

### Interaction Mapping
- `MainGameManager`: The absolute orchestrator. It listens for `plan_submitted` from the UI, executes the `SimulationServer`, and handles the final state commit (`commit_simulation_state`) where dead units are permanently purged and victory conditions are evaluated.
- `EventBus`: The sole nervous system. Systems never call `get_node()` on one another. If a prop is destroyed, the logic emits `prop_state_changed`. The View layer hears this and swaps the sprite.
- `ScenarioLoader`: Operates strictly at start-up. It deep-duplicates base `.tres` data templates, spawns entities into the `master_matrix`, and destroys itself.

## 5. Key Variables, State, and Data Structures

| Name | Type | Purpose/Role | How it mutates over time |
| :--- | :--- | :--- | :--- |
| `master_units` | `Dictionary` | Central registry mapping `unit_id` integers to `UnitDataResource` objects. | Populated at startup. Units are permanently erased from this dict at the end of Tick 99 if their HP hits zero. |
| `master_matrix` | `BattlefieldMatrix` | 3D Dictionary mapping `Vector3i` to `TileSpatialNodeResource` data cells. | `occupying_unit_id` shifts dynamically as units step between cells. Structural props collapsing mutate a tile's traversal cost to INF. |
| `template_parameters` | `Dictionary` | Lives inside `UnitDataResource`. Holds all volatile internal AI states, active cooldowns, and path arrays. | Mutated rapidly by the `SimulationServer` every micro-tick (e.g., `unit_movement_cooldown` decrements, `current_path` arrays are popped). |
| `TurnReplayBufferResource` | `Resource` | Array holding exactly 100 `TickSnapshotData` objects. | Generated sequentially during the Simulating phase. Read-only during the Playback phase. |
| `active_waypoints` | `Dictionary` | Lives in `UIManager`. Maps a `unit_id` to a target `Vector3i`. | Created when a player right-clicks during Planning. Emptied entirely once "Simulate" is clicked. |
| `is_order_fractured` | `bool` | Flag inside `UnitDataResource` tracking morale failure. | Flips to `true` mid-simulation if Stress exceeds a threshold limit. Forces UI dropdowns to lock in subsequent turns. |
| `Active Micro-Initiative`| `float` | Ephemeral calculation used by the `InitiativeReservationServer`. | Calculated dynamically only during collisions using `Base Initiative - Encumbrance + (ID * 0.001)`. Does not persist. |