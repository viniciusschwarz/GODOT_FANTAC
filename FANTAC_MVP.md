# MASTER ARCHITECTURAL IMPLEMENTATION PROMPTS FOR GODOT 4

This document contains the exact sequence of isolated, modular prompts designed to be fed one-by-one into a coding AI. Each prompt acts as an architectural contract, forcing the AI to focus strictly on building atomic `.gd` scripts, custom `Resource` schemas, `.tres` data definitions, or `.tscn` scene trees without cross-contaminating systems or inventing unapproved global state.

---

## LAYER 0: DATA CONTRACTS & GLOBAL EVENT BUS

### PROMPT 0.1: Custom Resource Definitions (Data Contracts)

```text
PROMPT TEMPLATE: LAYER 0 - STEP 1 (RESOURCE CLASSES)
---------------------------------------------------------------------------------------------------
ROLE: Lead Godot 4 Systems Engineer.
CONTEXT: Building a 2D top-down WeGo tactical simulation engine in Godot 4.
OBJECTIVE: Write 7 standalone, production-ready custom Resource scripts (.gd files) extending Resource.
           These scripts serve as pure data containers. NO node operations, NO physics, NO UI calls.

REQUIREMENTS & FILE PATHS:
1. res://scripts/resources/unit_data_resource.gd (class_name UnitDataResource)
   - Fields: unit_id: int, faction_id: int (0=Allied, 1=Enemy), unit_name: String, unit_class: int
   - Stats: max_hp: float, current_hp: float, current_stress: float, bravery_rating: float, loyalty_rating: float
   - Initiative/Speed: base_initiative: int, encumbrance_penalty: float, movement_speed_ticks_per_tile: int
   - Combat: weapon_damage: float, weapon_hardness_rating: float, attack_range_min: int, attack_range_max: int, attack_duration_ticks: int, damage_application_tick_offset: int
   - Capabilities: can_vault: bool, max_jump_gap: int, landing_grade: float
   - State Flags: is_stunned: bool, stun_remaining_ticks: int, is_order_fractured: bool
   - References: active_template_id: StringName, template_parameters: Dictionary

2. res://scripts/resources/tile_spatial_node_resource.gd (class_name TileSpatialNodeResource)
   - Fields: grid_position: Vector3i, height_offset_meters: float, base_traversal_cost: float
   - Connectors: vertical_connector_type: int (0=None, 1=Stairs_N, 2=Stairs_S, 3=Stairs_E, 4=Stairs_W)
   - Masks: cardinal_traversal_mask: int (Bitmask for N, S, E, W passage)
   - Cover: cover_type: int (0=None, 1=Low_Railing, 2=Window_Frame, 3=Solid_Parapet), cover_cardinal_vector: Vector2i, damage_reduction_pct: float
   - Occupancy State: occupying_unit_id: int (-1 if empty), reserved_unit_id: int (-1 if unreserved), reservation_micro_tick: int

3. res://scripts/resources/multi_stage_prop_resource.gd (class_name MultiStagePropResource)
   - Fields: prop_id: int, grid_position: Vector3i, max_hp: float, current_hp: float, material_hardness_threshold: float
   - State: current_degradation_state: int (0=Intact, 1=Rubble), attached_elevated_tile_coords: Array[Vector3i]

4. res://scripts/resources/ai_template_resource.gd (class_name AITemplateResource)
   - Fields: template_id: StringName, display_name: String, fallback_health_pct: float, target_priority_bias: int, cover_seeking_weight: float

5. res://scripts/resources/tick_snapshot_data.gd (class_name TickSnapshotData)
   - Fields: micro_tick_index: int (0..99)
   - State Dictionaries: unit_transform_states: Dictionary[int, Vector3i], unit_hp_states: Dictionary[int, float], unit_animation_states: Dictionary[int, int], prop_states: Dictionary[int, int], active_projectiles: Array[Dictionary], telemetry_events: Array[Dictionary]

6. res://scripts/resources/turn_replay_buffer_resource.gd (class_name TurnReplayBufferResource)
   - Fields: turn_number: int, tick_snapshots: Array[TickSnapshotData]

7. res://scripts/resources/turn_plan_resource.gd (class_name TurnPlanResource)
   - Fields: turn_number: int, unit_directives: Dictionary[int, int], unit_templates: Dictionary[int, AITemplateResource]

RULES:
- Use explicit typing for ALL exports and fields.
- Include class_name headers for every script.
- Provide a clean duplicate_data() method for UnitDataResource that duplicates runtime state safely.
---------------------------------------------------------------------------------------------------

```

---

### PROMPT 0.2: Autoload Event Bus Setup

```text
PROMPT TEMPLATE: LAYER 0 - STEP 2 (EVENT BUS AUTOLOAD)
---------------------------------------------------------------------------------------------------
ROLE: Lead Godot 4 Systems Engineer.
CONTEXT: Building the decoupled communication layer for a WeGo tactical game.
OBJECTIVE: Create a single, lightweight global signal broker script to be registered as an Autoload.

FILE PATH: res://scripts/autoloads/event_bus.gd (Autoload Name: EventBus)

SIGNALS TO DEFINE:
1. Phase Signals:
   - signal phase_changed(new_phase: int) # 0=Planning, 1=Simulating, 2=Playback
   - signal turn_simulation_completed(replay_buffer: TurnReplayBufferResource)

2. Selection & Interaction Signals:
   - signal unit_selected(unit_id: int)
   - signal unit_hovered(unit_id: int)
   - signal tile_selected(grid_coord: Vector3i)

3. Simulation & Environment Signals:
   - signal navmesh_dirty(tile_coord: Vector3i)
   - signal prop_state_changed(prop_id: int, new_state: int)

4. Playback & UI Signals:
   - signal scrubber_tick_changed(target_tick: int)
   - signal playback_state_changed(is_playing: bool, speed_multiplier: float)

RULES:
- Script must extend Node.
- NO visual logic, NO state variables inside the Autoload—ONLY signal declarations and helper emit methods if necessary.
---------------------------------------------------------------------------------------------------

```

---

### PROMPT 0.3: Preset Data Files Creation (`.tres`)

```text
PROMPT TEMPLATE: LAYER 0 - STEP 3 (DATA PRESET .TRES FILES)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Technical Content Designer.
CONTEXT: Instantiating pre-configured Resource files (.tres) based on the Custom Resource classes defined in Step 0.1.

OBJECTIVE: Create text-based Godot .tres resource files matching our MVP parameters.

FILES TO GENERATE:
1. res://data/units/vanguard_preset.tres (UnitDataResource)
   - unit_name: "Allied Vanguard", faction_id: 0, unit_class: 0
   - max_hp: 100.0, current_hp: 100.0, base_initiative: 12, movement_speed_ticks_per_tile: 10
   - weapon_damage: 15.0, weapon_hardness_rating: 6.0 (Broadsword), attack_range_min: 1, attack_range_max: 1
   - active_template_id: &"AGGRESSIVE_ASSAULT"

2. res://data/units/skirmisher_preset.tres (UnitDataResource)
   - unit_name: "Allied Skirmisher", faction_id: 0, unit_class: 1
   - max_hp: 60.0, current_hp: 60.0, base_initiative: 18, movement_speed_ticks_per_tile: 10
   - weapon_damage: 8.0, weapon_hardness_rating: 0.0 (Shortbow), attack_range_min: 2, attack_range_max: 6
   - can_vault: true, max_jump_gap: 1
   - active_template_id: &"CAUTIOUS_OVERWATCH"

3. res://data/units/guard_preset.tres (UnitDataResource)
   - unit_name: "Enemy Guard", faction_id: 1, unit_class: 2
   - max_hp: 120.0, current_hp: 120.0, base_initiative: 10, movement_speed_ticks_per_tile: 10
   - weapon_damage: 12.0, weapon_hardness_rating: 5.0, attack_range_min: 1, attack_range_max: 1
   - active_template_id: &"POINT_GUARD"

4. res://data/units/archer_preset.tres (UnitDataResource)
   - unit_name: "Enemy Archer", faction_id: 1, unit_class: 3
   - max_hp: 50.0, current_hp: 50.0, base_initiative: 14, movement_speed_ticks_per_tile: 10
   - weapon_damage: 10.0, weapon_hardness_rating: 0.0, attack_range_min: 2, attack_range_max: 6
   - active_template_id: &"CAUTIOUS_OVERWATCH"

5. res://data/props/wooden_gate_preset.tres (MultiStagePropResource)
   - max_hp: 50.0, current_hp: 50.0, material_hardness_threshold: 5.0, current_degradation_state: 0

6. AI Templates (.tres for AITemplateResource):
   - res://data/ai_templates/aggressive_assault.tres (template_id: &"AGGRESSIVE_ASSAULT", fallback_health_pct: 0.15)
   - res://data/ai_templates/cautious_overwatch.tres (template_id: &"CAUTIOUS_OVERWATCH", fallback_health_pct: 0.40)
   - res://data/ai_templates/point_guard.tres (template_id: &"POINT_GUARD", fallback_health_pct: 0.00)

RULES:
- Provide exact text-based .tres syntax compatible with Godot 4.x.
---------------------------------------------------------------------------------------------------

```

---

## LAYER 1: SPATIAL GRID, Z-LEVELS & TACTICAL PROPS

### PROMPT 1.1: Battlefield Spatial Matrix Manager

```text
PROMPT TEMPLATE: LAYER 1 - STEP 1 (BATTLEFIELD MATRIX)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Core Engine Programmer.
CONTEXT: Building the memory grid for a 12x12x2 discrete top-down battlefield (Z0 Ground, Z1 Rampart).

OBJECTIVE: Write res://scripts/core/battlefield_matrix.gd (class_name BattlefieldMatrix).
           This script manages a 3D Dictionary indexed by Vector3i(x, y, z) holding TileSpatialNodeResource instances.

KEY METHODS TO IMPLEMENT:
1. initialize_grid(width: int = 12, depth: int = 12, height_levels: int = 2) -> void
   - Populates spatial matrix with default TileSpatialNodeResource objects.
   - Sets Z0 height_offset = 0.0m, Z1 height_offset = 3.0m.

2. get_tile(coord: Vector3i) -> TileSpatialNodeResource
   - Bounds-checked getter returning null if coordinate is out of bounds.

3. is_cardinal_passable(from_coord: Vector3i, to_coord: Vector3i) -> bool
   - Verifies destination is in bounds.
   - Enforces 4-directional cardinal check (distance == 1 tile along X or Y; Z transitions require STAIRS connector).
   - Verifies cardinal_traversal_mask permits passage.

4. calculate_3d_line_of_sight(origin: Vector3i, target: Vector3i) -> Dictionary
   - Performs discrete grid raycast between 3D cell centers.
   - Returns: { "has_los": bool, "cover_level": int, "intercepting_prop_id": int }
   - Evaluates Z-level parapet cover if target sits on Z1 adjacent to a SOLID_PARAPET facing the origin.

RULES:
- No Node2D/Node3D scene requirements—operate purely on Vector3i math and Resources.
- Enforce strict 4-directional cardinal restrictions (N, S, E, W). Diagonal transitions return false.
---------------------------------------------------------------------------------------------------

```

---

### PROMPT 1.2: Destructible Tactical Prop Controller

```text
PROMPT TEMPLATE: LAYER 1 - STEP 2 (TACTICAL PROP SCENE & LOGIC)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Gameplay Programmer.
CONTEXT: Implementing a destructible obstacle (Wooden Gate) that alters pathfinding when broken.

FILES TO GENERATE:
1. res://scenes/props/tactical_prop.tscn (Node2D root scene)
2. res://scripts/props/tactical_prop.gd (Attached script)

FUNCTIONALITY:
1. Setup & Exports:
   - export var prop_data: MultiStagePropResource

2. Core Methods:
   - take_damage(amount: float, hardness_rating: float) -> bool
     * Checks if hardness_rating >= prop_data.material_hardness_threshold.
     * If true, subtracts amount from prop_data.current_hp.
     * If current_hp <= 0 and state is INTACT: calls trigger_collapse(). Returns true.
     * If hardness is insufficient, logs deflection and returns false.

   - trigger_collapse() -> void
     * Sets prop_data.current_degradation_state = 1 (RUBBLE).
     * Updates underlying TileSpatialNodeResource at grid_position: sets base_traversal_cost = 2.0, clears LOS occlusion.
     * Emits EventBus.navmesh_dirty(grid_position).
     * Handles attached Z1 walkway collapses (notifies matrix that attached Z1 tiles are destroyed).

RULES:
- Keep view updates separated from logic—the script handles state changes and emits signals.
---------------------------------------------------------------------------------------------------

```

---

## LAYER 2: HEADLESS PATHFINDING & COMBAT ENGINES

### PROMPT 2.1: 4-Directional Grid A* Pathfinding Engine

```text
PROMPT TEMPLATE: LAYER 2 - STEP 1 (A* PATHFINDING ENGINE)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Algorithmic Engineer.
CONTEXT: Building a headless A* pathfinding server operating on Vector3i discrete grid coordinates.

FILE TO GENERATE: res://scripts/sim/pathfinding_engine.gd (class_name PathfindingEngine)

REQUIREMENTS:
1. Core Method: calculate_path(matrix: BattlefieldMatrix, start: Vector3i, target: Vector3i, unit_data: UnitDataResource) -> Array[Vector3i]
   - Uses standard A* algorithm restricted strictly to 4-directional cardinal steps: N(0,-1,0), S(0,1,0), E(1,0,0), W(-1,0,0).
   - Z-level transitions ONLY permitted if current tile has a valid vertical_connector_type (STAIRS).

2. Traversal Cost Evaluation:
   - Standard Ground = 1.0
   - Staircase = 1.5
   - Rubble Debris = 2.0
   - Static Occupied Tile = +50.0 (High penalty to prevent pathing through standing units)
   - Impassable Wall / Intact Gate = Infinity (Blocked)

3. Recalculation Cooldown Helper:
   - If a path request fails or returns blocked mid-execution, sets unit's recalculation_cooldown_ticks = 5.

RULES:
- Hard-disable all diagonal neighbor checks.
- Pure GDScript algorithm—no Godot AStar2D/3D built-in nodes to ensure total control over Z-level stair logic.
---------------------------------------------------------------------------------------------------

```

---

### PROMPT 2.2: Initiative Reservation Server

```text
PROMPT TEMPLATE: LAYER 2 - STEP 2 (INITIATIVE RESERVATION SERVER)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Systems Engineer.
CONTEXT: Resolving single-tile spatial collisions when two units schedule entry into the same cell at Micro-Tick T.

FILE TO GENERATE: res://scripts/sim/initiative_reservation_server.gd (class_name InitiativeReservationServer)

REQUIREMENTS:
1. Method: resolve_tile_reservation(tile: TileSpatialNodeResource, requesting_unit: UnitDataResource, micro_tick: int) -> bool
   - Calculates requesting_unit's Active Micro-Initiative:
     ActiveMicroInitiative = base_initiative - encumbrance_penalty + (unit_id * 0.001)

   - If tile.reserved_unit_id == -1 (Unreserved):
     * Claims tile: tile.reserved_unit_id = requesting_unit.unit_id, tile.reservation_micro_tick = micro_tick. Returns true.

   - If tile is already reserved at the exact same micro_tick by another unit:
     * Compares active micro-initiatives.
     * If requesting_unit > current_reserver: overwrites reservation with requesting_unit.unit_id and returns true for requesting_unit (losing unit's reservation is cleared and it receives PATH_BLOCKED_BY_INITIATIVE interrupt).
     * If requesting_unit < current_reserver: rejects requesting_unit (returns false).

RULES:
- Pure logic class—determines tile claims deterministically using unit IDs as absolute tie-breakers.
---------------------------------------------------------------------------------------------------

```

---

### PROMPT 2.3: Ballistic Trajectory & Interception Engine

```text
PROMPT TEMPLATE: LAYER 2 - STEP 3 (COMBAT & BALLISTICS ENGINE)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Physics & Combat Engineer.
CONTEXT: Simulating dynamic ranged projectiles moving frame-by-frame through 3D discrete grid space.

FILE TO GENERATE: res://scripts/sim/combat_engine.gd (class_name CombatEngine)

REQUIREMENTS:
1. Method: process_projectile_step(projectile: Dictionary, matrix: BattlefieldMatrix, units_map: Dictionary) -> Dictionary
   - Input projectile dictionary: { "id": int, "source_id": int, "target_id": int, "current_pos_3d": Vector3, "velocity": Vector3, "damage": float, "hardness": float }
   - Advances current_pos_3d by velocity per micro-tick.
   - Calculates grid_coord = Vector3i(floor(pos.x), floor(pos.y), floor(pos.z / 3.0)).

2. Collision & Interception Checks:
   - Check Terrain/Props: Query matrix.get_tile(grid_coord). If cell contains an intact prop or Z1 parapet and projectile height < obstruction height -> Destroy projectile, Return { "status": "INTERCEPTED_TERRAIN" }.
   - Check Units: Query units at grid_coord (excluding source_id). If hit -> Apply damage, Return { "status": "HIT_UNIT", "hit_unit_id": unit.unit_id, "damage": damage }.

3. Melee Resolution Helper:
   - Method: resolve_melee_attack(attacker: UnitDataResource, defender: UnitDataResource) -> Dictionary
   - Validates cardinal adjacency. Applies weapon_damage against defender's current_hp. Handles damage application tick offset.

RULES:
- Dynamic calculation per micro-tick—no instantaneous hitscan calculations for ranged weapons.
---------------------------------------------------------------------------------------------------

```

---

## LAYER 3: DECENTRALIZED AI TREE & BEHAVIOR TEMPLATES

### PROMPT 3.1: Pre-Baked AI Tree Evaluator

```text
PROMPT TEMPLATE: LAYER 3 - STEP 1 (AI TREE EVALUATOR)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 AI Architecture Programmer.
CONTEXT: Executing parameterized conditional behavior trees headlessly during WeGo simulation passes.

FILE TO GENERATE: res://scripts/ai/ai_tree_evaluator.gd (class_name AITreeEvaluator)

REQUIREMENTS:
1. Method: evaluate_unit_behavior(unit: UnitDataResource, matrix: BattlefieldMatrix, all_units: Dictionary, current_tick: int) -> Dictionary
   - Evaluates active AITemplateResource assigned to unit.

2. Behavior Template Branch Implementations:
   - "AGGRESSIVE_ASSAULT":
     * Branch 1: If current_hp / max_hp < 0.15 -> Action: Fallback_To_Cover.
     * Branch 2: If enemy in melee range -> Action: Melee_Attack.
     * Default: Action: Advance_Shortest_Path_To_Objective.

   - "CAUTIOUS_OVERWATCH":
     * Branch 1: If current_hp / max_hp < 0.40 -> Action: Fallback_To_Cover.
     * Branch 2: If enemy in ranged threat envelope -> Action: Ranged_Trade_From_Cover.
     * Default: Action: Advance_Via_Cover_Tiles.

   - "POINT_GUARD":
     * Branch 1: If enemy in melee/threat range -> Action: Attack_Target.
     * Default: Action: Hold_Anchor_Tile.

3. Hysteresis Timer & Telemetry Logging:
   - Enforces 15-tick branch lock when entering a fallback state to prevent logic flickering.
   - Outputs: { "action_type": Enum, "target_coord": Vector3i, "telemetry_entry": Dictionary }

RULES:
- Pure conditional logic—evaluates memory states and outputs action commands for the SimulationServer.
---------------------------------------------------------------------------------------------------

```

---

## LAYER 4: HEADLESS SIMULATION SERVER & REPLAY BUFFER

### PROMPT 4.1: Simulation Server Controller

```text
PROMPT TEMPLATE: LAYER 4 - STEP 1 (HEADLESS SIMULATION SERVER)
---------------------------------------------------------------------------------------------------
ROLE: Lead Systems Architect.
CONTEXT: Combining Layers 0-3 into a standalone 100-micro-tick headless simulation server.

FILE TO GENERATE: res://scripts/sim/simulation_server.gd (class_name SimulationServer)

REQUIREMENTS:
1. Core Entry Point: run_turn_simulation(plan: TurnPlanResource, initial_matrix: BattlefieldMatrix, initial_units: Array[UnitDataResource]) -> TurnReplayBufferResource
   - Instantiates a TurnReplayBufferResource.
   - Runs a strict 100-micro-tick loop (ticks 0 to 99) in CPU memory (< 10ms execution time).

2. Micro-Tick State Machine Execution Order (Per Tick):
   - Step A: Process environment and active projectile positions (CombatEngine).
   - Step B: Evaluate unit AI tree conditions and interrupts (AITreeEvaluator).
   - Step C: Resolve initiative claims and tile reservations (InitiativeReservationServer).
   - Step D: Execute cardinal unit movement steps and path updates (PathfindingEngine).
   - Step E: Resolve combat hits, damage application, and morale/order fracture checks.
   - Step F: Capture tick snapshot (Unit positions, HP, states, active projectiles, telemetry) -> Append to TurnReplayBufferResource.

3. Completion:
   - Returns fully populated TurnReplayBufferResource.
   - Emits EventBus.turn_simulation_completed(buffer).

RULES:
- NO process(delta), NO physics threads, NO visual scene nodes used during simulation pass.
---------------------------------------------------------------------------------------------------

```

---

## LAYER 5: VIEW LAYER, UI INTERFACES & SCRUBBER

### PROMPT 5.1: Top-Down Orthographic Board Renderer

```text
PROMPT TEMPLATE: LAYER 5 - STEP 1 (BATTLEFIELD VIEW & SPRITE RENDERER)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Visual & Graphics Programmer.
CONTEXT: Rendering the 2D top-down battlefield, unit tokens, and height depth sorting.

FILES TO GENERATE:
1. res://scenes/view/battlefield_view.tscn (Node2D Scene)
2. res://scripts/view/battlefield_view.gd (Attached Script)
3. res://scenes/view/unit_token_view.tscn / .gd (Visual Unit Token)

REQUIREMENTS:
1. Grid Visual Setup:
   - Renders 12x12 orthogonal grid cells.
   - Manages Z-level depth rendering (Z0 ground layer vs. elevated Z1 rampart layer).

2. Replay Synchronization:
   - Listens to EventBus.scrubber_tick_changed(target_tick: int).
   - Reads TurnReplayBufferResource.tick_snapshots[target_tick].
   - Hard-sets unit sprite positions, animations, and visible status to match the tick snapshot directly.

RULES:
- View layer MUST NEVER calculate game logic—it solely reflects snapshot data provided by the replay buffer.
---------------------------------------------------------------------------------------------------

```

---

### PROMPT 5.2: Replay Scrubber & Telemetry UI Controller

```text
PROMPT TEMPLATE: LAYER 5 - STEP 2 (UI SCRUBBER & TELEMETRY BADGE)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 UI/UX Engineer.
CONTEXT: Creating the planning interface, 0-99 tick playback bar, and unit telemetry badge.

FILES TO GENERATE:
1. res://scenes/ui/ui_manager.tscn (CanvasLayer Root Scene)
2. res://scripts/ui/ui_manager.gd (Attached Script)
3. res://scenes/ui/floating_telemetry_badge.tscn / .gd

REQUIREMENTS:
1. Playback Controls:
   - HSlider (range 0 to 99) representing turn micro-ticks.
   - Play/Pause toggle button.
   - Dragging slider emits EventBus.scrubber_tick_changed(slider.value).

2. Floating Telemetry Badge:
   - Anchors visually to the currently selected unit token.
   - Displays major event telemetry entries logged on or before the active render tick (e.g., "[Tick 12] Gate Destroyed", "[Tick 34] Cautious Overwatch Active").

3. Directive Panel:
   - Exposes dropdowns during Planning Phase to assign AI Templates (Aggressive Assault, Cautious Overwatch, Point Guard) to allied units.

RULES:
- Clean UI layout designed for desktop resolutions. Slider scrubbing must feel smooth and instantaneous.
---------------------------------------------------------------------------------------------------

```
## LAYER 6: PLAYABLE MVP INTEGRATION PROMPTS
Feed these exact prompts to your coding AI to finalize the MVP loop.

### PROMPT 6.1: Macro Phase Controller (MainGameManager)
Plaintext
PROMPT TEMPLATE: LAYER 6 - STEP 1 (MACRO PHASE CONTROLLER)
---------------------------------------------------------------------------------------------------
ROLE: Lead Godot 4 Systems Engineer.
CONTEXT: Building the overarching state machine that drives the WeGo tactical engine loop.
OBJECTIVE: Write res://scripts/core/main_game_manager.gd (Attached to a Node).

REQUIREMENTS:
1. State Management:
   - Define enum Phase { INITIALIZATION, PLANNING, SIMULATING, PLAYBACK, MATCH_END }
   - Track current_phase, current_turn (1 to 5), master_matrix, master_units.

2. Phase Loop Execution:
   - enter_planning_phase(): Creates a fresh TurnPlanResource, unlocks UI via EventBus.phase_changed(PLANNING).
   - execute_simulation(plan: TurnPlanResource): Sets phase to SIMULATING. Instantiates SimulationServer, passes master_matrix and master_units. Yields/Waits for SimulationServer to return the TurnReplayBufferResource.
   - enter_playback_phase(buffer): Emits EventBus.turn_simulation_completed(buffer) and EventBus.phase_changed(PLAYBACK).

3. The Tick 99 Turn Handoff (CRITICAL):
   - Method: advance_to_next_turn(buffer: TurnReplayBufferResource)
   - Extracts snapshot 99: var final_state = buffer.tick_snapshots[99]
   - Iterates through master_units. Updates unit_current_hp and stress from the snapshot.
   - If unit HP <= 0, removes unit from master_units and clears its occupying_unit_id from master_matrix.
   - Evaluates Win/Loss (See Step 4).
   - Increments current_turn. If current_turn > 5, triggers MATCH_END (Loss). Otherwise, loops back to enter_planning_phase().

4. Win Condition Evaluation:
   - At the end of advance_to_next_turn, check the master_matrix tile at Vector3i(6, 11, 1).
   - If occupying_unit_id belongs to an ALLIED faction unit, emit EventBus.match_ended(true).

RULES:
- Ensure strict guardrails: execute_simulation MUST do nothing if current_phase != PLANNING.
- Use GDScript strictly (No C#).
---------------------------------------------------------------------------------------------------
### PROMPT 6.2: Scenario Loader & Main Scene
Plaintext
PROMPT TEMPLATE: LAYER 6 - STEP 2 (SCENARIO LOADER & MAIN SCENE)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Gameplay Programmer.
CONTEXT: Assembling the final game scene that wires the Data, View, and UI layers together.
OBJECTIVE: Create res://scenes/main.tscn and its attached script res://scripts/core/scenario_loader.gd.

REQUIREMENTS:
1. Scene Tree Structure (main.tscn):
   - Root: Node (Main)
     - ScenarioLoader (Script attached here)
     - MainGameManager (Node)
     - BattlefieldView (Instantiated Scene)
     - UIManager (Instantiated CanvasLayer Scene)

2. ScenarioLoader.gd Initialization Logic (_ready):
   - Instantiates BattlefieldMatrix.
   - Loads the .tres presets from res://data/units/ and res://data/props/.
   - Duplicates them (.duplicate_data()) to create runtime instances.
   - Spawns Allied Vanguard at (8,1,0), Allied Skirmisher at (4,1,0).
   - Spawns Enemy Guard at (6,5,0), Enemy Archer at (6,8,1).
   - Spawns Wooden Gate prop at (6,4,0).
   - Registers all units into a dictionary and the matrix.

3. Dependency Injection:
   - Passes the populated master_matrix and master_units dictionary into MainGameManager.
   - Calls MainGameManager.start_match() to kick off Turn 1.

RULES:
- ScenarioLoader is a one-time setup script. Once it injects data into MainGameManager, its job is done.
- Use explicit ResourceLoader.load() calls to grab the .tres files.
---------------------------------------------------------------------------------------------------
### PROMPT 6.3: UI Handoff & Morale Lockout
Plaintext
PROMPT TEMPLATE: LAYER 6 - STEP 3 (UI HANDOFF & MORALE ENFORCEMENT)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 UI/UX Engineer.
CONTEXT: Finalizing the UI Manager to respect the Turn Handoff and Morale state of the units.
OBJECTIVE: Update res://scripts/ui/ui_manager.gd to handle the Submit button and Order Fractures.

REQUIREMENTS:
1. Submit Plan Button:
   - Add a "Simulate Turn" Button to the UI.
   - When clicked: Emits a local signal to MainGameManager containing the active TurnPlanResource.
   - IMMEDIATELY disables the button and all template dropdowns to prevent the Double-Click Race Condition.

2. Morale Lockout (Order Fracture UI):
   - During the PLANNING phase, when the player selects a unit, read unit_data.is_order_fractured.
   - If true: Disable the AI Template Dropdown for that unit.
   - Force the UI text of the dropdown to read "FRACTURED: UNCONTROLLED".
   - This ensures the player cannot magically override a panicked unit's behavior until they recover.

3. End of Playback Catch:
   - When the playback slider naturally reaches Tick 99 and completes the 5-second turn, emit a signal back to MainGameManager: EventBus.playback_completed.emit().
   - This signal tells the MainGameManager to trigger the advance_to_next_turn() logic.

RULES:
- The UI MUST NOT mutate unit data during playback or transition. It only reads states and passes the TurnPlanResource.
---------------------------------------------------------------------------------------------------

## LAYER 7: DEBUG RENDERING & TELEMETRY VISUALIZATION

### PROMPT 7.1: Procedural Grid Rendering (No Art Assets)

```text
PROMPT TEMPLATE: LAYER 7 - STEP 1 (PROCEDURAL GRID RENDERING)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Technical Artist & Systems Programmer.
CONTEXT: We need to see the BattlefieldMatrix rendered in BattlefieldView without relying on any external art files (.png). 
OBJECTIVE: Update res://scripts/view/battlefield_view.gd to programmatically generate a TileSet and paint the grid.

REQUIREMENTS:
1. Procedural TileSet Generation (in `_ready` or an initialization method):
   - Create a new `TileSet` with `tile_size = Vector2i(64, 64)`.
   - Programmatically create two `ImageTexture` objects using `Image.create(64, 64, false, Image.FORMAT_RGBA8)`.
   - Tile 0 (Z0 Ground): Fill with Color(0.15, 0.3, 0.15) (Dark Green) and draw a 2px black border around the edges.
   - Tile 1 (Z1 Rampart): Fill with Color(0.4, 0.4, 0.4) (Gray) and draw a 2px black border around the edges.
   - Create a `TileSetAtlasSource`, assign the textures, and add them to the `TileSet`.
   - Assign this programmatic `TileSet` to both `GroundLayerZ0` and `RampartLayerZ1`.

2. Matrix Parsing & Painting:
   - Add a method `paint_debug_grid(matrix: BattlefieldMatrix)` called upon receiving the initial Tick 0 snapshot.
   - Iterate x from 0 to 11, y from 0 to 11.
   - Query the matrix. If a tile exists at (x, y, 0), use `GroundLayerZ0.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))`.
   - If a tile exists at (x, y, 1), use `RampartLayerZ1.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))`.

RULES:
- Do NOT abandon the TileMapLayer architecture. Use pure GDScript to inject the textures into it.
---------------------------------------------------------------------------------------------------
```
### PROMPT 7.2: CONSOLE TELEMETRY DUMP

```text

PROMPT TEMPLATE: LAYER 7 - STEP 2 (CONSOLE TELEMETRY DUMP)
---------------------------------------------------------------------------------------------------
ROLE: Lead Godot 4 Systems Engineer.
CONTEXT: The headless SimulationServer is a "black box". We need mathematical proof in the output console that units are evaluating their AI trees and attempting to move or attack during the simulation.
OBJECTIVE: Update res://scripts/core/main_game_manager.gd to output a clean State Differential Dump.

REQUIREMENTS:
1. Implement `debug_print_turn_summary(buffer: TurnReplayBufferResource)`
   - Call this method inside `advance_to_next_turn` or immediately after `execute_simulation` finishes.
   - Fetch `tick_snapshots[0]` (Start) and `tick_snapshots[99]` (End).

2. Console Formatting:
   - Print a clear header: `print("=== SIMULATION TURN %d COMPLETED ===" % current_turn)`
   - Iterate through all units in `master_units`.
   - For each unit, print a single string containing:
     * Unit Name & ID
     * Assigned AI Template
     * Start Coord -> End Coord
     * Start HP -> End HP
   - Example output: `[ID:0] Allied Vanguard (AGGRESSIVE_ASSAULT) | Pos: (8, 1, 0) -> (8, 4, 0) | HP: 100 -> 100`

RULES:
- Keep the print output extremely concise. Only print the delta between Tick 0 and Tick 99 to avoid console spam.
---------------------------------------------------------------------------------------------------
```
## PROMPT 8.1: Player Selection & Waypoint Injection
```text
PROMPT TEMPLATE: LAYER 8 - STEP 1 (SELECTION & WAYPOINTS)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Gameplay & UI Engineer.
CONTEXT: We need to implement unit selection and waypoint assignment during the Planning Phase to make the MVP playable.
OBJECTIVE: Update `battlefield_view.gd` and `ui_manager.gd` to handle mouse inputs, draw intent lines, and inject objectives into the Turn Plan.

REQUIREMENTS:
1. Grid Raycasting & Selection (`battlefield_view.gd`):
   - Listen for `_unhandled_input(event)`.
   - On Left-Click: Convert mouse position to grid coordinate. Query `master_matrix` for `occupying_unit_id`. If allied, emit `EventBus.unit_selected(unit_id)`.
   - On Right-Click: If `current_phase == PLANNING` and a unit is selected, validate that the clicked grid coordinate exists in `master_matrix`. If valid, emit `EventBus.tile_right_clicked(selected_unit_id, grid_coord)`.

2. Waypoint Management (`ui_manager.gd`):
   - Listen for `tile_right_clicked`. Store it in a dictionary: `active_waypoints[unit_id] = grid_coord`.
   - When the "Simulate" button is clicked, write `active_waypoints` into the new `TurnPlanResource.unit_objectives` dictionary alongside the templates.
   - Clear `active_waypoints` completely at the start of a new turn.

3. Visual Intent Lines (`battlefield_view.gd`):
   - Create a `Line2D` container. Whenever `active_waypoints` changes, draw a simple line from the selected unit's visual token to the target tile's center. Hide these lines instantly when the phase changes to `SIMULATING`.

RULES:
- Keep UI management strictly in one container. Do not create complex nested UI elements for every unit state; just update a central selection panel.
- Ensure strict GDScript only.
---------------------------------------------------------------------------------------------------
```

## PROMPT 8.2: AI Execution & Headless Movement
```text
PROMPT TEMPLATE: LAYER 8 - STEP 2 (HEADLESS PATH EXECUTION)
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 Core Engine Programmer.
CONTEXT: The SimulationServer must physically move units across the matrix based on player objectives.
OBJECTIVE: Update `simulation_server.gd` and `ai_tree_evaluator.gd` to calculate paths and execute step-by-step movement.

REQUIREMENTS:
1. Objective Injection (Start of Simulation):
   - At Tick 0, iterate through `plan.unit_objectives`. For each unit, set `unit.template_parameters["objective_coord"] = plan.unit_objectives[unit_id]`.
   - Clear `unit.template_parameters["current_path"]` to ensure a clean slate.

2. AI Path Request (`ai_tree_evaluator.gd`):
   - If a unit's AI decides to `ADVANCE_TO_OBJECTIVE`, check if `template_parameters["current_path"]` is empty.
   - If empty, call `PathfindingEngine.calculate_path` to the `objective_coord`. Store the resulting array in `current_path`.

3. Step Execution (`simulation_server.gd` - Step D Movement):
   - For every unit whose AI output an `ADVANCE` action:
   - Check `unit_movement_cooldown`. If > 0, decrement and skip.
   - If cooldown is 0, pop the next `Vector3i` coordinate from their `current_path`.
   - Call `InitiativeReservationServer` to claim that tile.
   - If granted: 
     - Update the unit's position in `master_matrix` (clear old tile, occupy new tile).
     - Set `unit_movement_cooldown = unit.movement_speed_ticks_per_tile`.
   - If denied (blocked):
     - Clear `current_path`. Set a short AI hesitation cooldown (e.g., 5 ticks) so it recalculates a new route on its next evaluation.

RULES:
- Never use Godot Tweens or visual position vectors here. Movement is strictly updating the `occupying_unit_id` across discrete `Vector3i` matrix tiles.
```
---------------------------------------------------------------------------------------------------

## LAYER 9: DYNAMIC COMMANDER INTERFACE

### PROMPT 9.1: Single Dynamic Prefab Container & Inspector
---------------------------------------------------------------------------------------------------
ROLE: Godot 4 UI/UX Engineer.
CONTEXT: We must avoid overcomplicating the interface system with multiple separate UI scripts. 
OBJECTIVE: Write a centralized `commander_inspector_ui.gd` and a single `unit_card_prefab.tscn` that updates dynamically based on player selection.

REQUIREMENTS:
1. Single Prefab Instantiation:
   - Create `UnitCardPrefab.tscn` (Control Node) containing a Name Label, HP/Stress ProgressBars, and a Template OptionButton. 
   - `commander_inspector_ui.gd` hosts ONE instance of this prefab.
   - When `EventBus.unit_selected(unit_id)` fires, populate this single prefab container with data from `master_units[unit_id]`. Do not spawn multiple panels.
   
2. Draft State & Visual Reset:
   - Track `draft_directives: Dictionary[int, StringName]`. Save dropdown choices here before "Simulate" is clicked.
   - When updating the prefab, EXPLICITLY reset all visual states before applying new data.
   - If `unit.is_order_fractured == true`, force the prefab's OptionButton text to "FRACTURED" and disable it.

3. Phase Handoff:
   - PLANNING: Prefab reads `master_units`.
   - PLAYBACK: Dropdown locks. Prefab reads HP/Stress from `TurnReplayBufferResource.tick_snapshots[current_tick]` via `scrubber_tick_changed`.

RULES:
- Use strict GDScript (GDS). No C#.
---------------------------------------------------------------------------------------------------

## LAYER 10: ARCHITECTURAL PATCHES & FIXES

### PROMPT 10.1: Target Updates for Layers 7 & 8 (GDS Only)
---------------------------------------------------------------------------------------------------
ROLE: Lead Godot 4 Systems Engineer.
CONTEXT: We are issuing a targeted refactor pass to update our existing Layers 7 and 8 scripts to fix WeGo movement timing, telemetry timing, and procedural texture generation.
OBJECTIVE: Apply the following patches to existing scripts using pure GDScript (no C#).

REQUIREMENTS:
1. Procedural Grid Patch (`battlefield_view.gd` & `event_bus.gd`):
   - Add `signal grid_initialized(matrix)` to `event_bus.gd`.
   - Update grid painting to generate a SINGLE `128x64` Image for the `TileSetAtlasSource`. (X 0-63 is Z0 Green, X 64-127 is Z1 Gray). Explicitly set texture filtering to Nearest to prevent pixel bleeding.

2. Telemetry Timing Patch (`main_game_manager.gd`):
   - Move the call for `debug_print_turn_summary(buffer)` to the VERY BEGINNING of `advance_to_next_turn()`.
   - It MUST execute before any dead units (HP <= 0) are removed from `master_units` to ensure combat results are logged. Include Stress deltas in the string output.

3. Waypoint & Intent Patch (`battlefield_view.gd` & `ui_manager.gd`):
   - Limit `active_waypoints` to STRICTLY ONE waypoint per unit.
   - Draw the `Line2D` intent line as a straight path from the unit token to the target tile center, completely ignoring grid geometry (no Manhattan paths).

4. Async Movement Cooldown Patch (`simulation_server.gd`):
   - REMOVE the global modulo check (`current_tick % speed == 0`) from Step D.
   - REPLACE it with a check against `unit.template_parameters["unit_movement_cooldown"]`. Decrement this value. When it hits 0, execute the matrix step and reset the cooldown.
---------------------------------------------------------------------------------------------------