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