# Architecture and Refactor Log

This document tracks the module responsibilities and the refactoring steps applied during the codebase modularization process.

## Phase 1: Autoloads & Data Models

### `scripts/autoloads/audio_manager.gd`
- **Core Responsibility:** Manages Background Music (BGM), Ambient sounds, and provides an object pool for Sound Effects (SFX).
- **Functions List:**
  - `_ready()`: Triggers setup of buses and initialization of players.
  - `_setup_buses()`: Placeholder for assigning default bus layouts.
  - `_initialize_players()`: Initializes standard streams for music, ambiance, and populates the SFX pool array.
  - `play_music(stream: AudioStream, crossfade_time: float)`: Plays background music if different from current stream.
  - `play_ambient(stream: AudioStream)`: Plays looping ambient tracks.
  - `stop_all_bgm()`: Halts BGM and ambient tracks simultaneously.
  - `play_sfx(stream: AudioStream, position: Vector2)`: Fetches an idle player from the SFX pool and executes a sound at a specific position.
- **Refactor Notes:**
  - Applied strict GDScript typing to local variables (e.g., `var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()`).

### `scripts/autoloads/data_manager.gd`
- **Core Responsibility:** Responsible for reading Godot custom resources (`.tres`) directly from directories, parsing metadata, and caching them into accessible lookup dictionaries.
- **Functions List:**
  - `_ready()`: Invokes data load procedure.
  - `_load_all_data()`: Centralized caller for loading specific categories of data.
  - `_load_directory_resources(dir_path: String) -> Array[Dictionary]`: Generic reusable helper to scan a target directory for `.tres` files and instantiate them.
  - `_load_units()`, `_load_weapons()`, `_load_rules()`, `_load_missions()`: Wrappers for caching specific data types using the generic loader.
  - `get_unit_data(id: String) -> UnitData`: Safely fetches unit models from cache.
  - `get_weapon_data(id: String) -> WeaponData`: Safely fetches weapon models from cache.
  - `get_rules(category: String) -> Variant`: Fetches rules data resources or converts meta layouts to dictionaries.
  - `get_mission(id: String) -> MissionData`: Safely fetches mission parameters from cache.
  - `get_all_missions() -> Array`: Returns the entire list of cached missions.
- **Refactor Notes:**
  - Applied strict array and dictionary typing. Updated `_load_directory_resources` to cleanly return strongly typed `Array[Dictionary]` instead of loosely typed Variant arrays.
  - Typed local file and string iterators.
  - Assured `get_rules` returns a `Variant` to satisfy its dual `Dictionary` / `Resource` return behavior.

### `scripts/autoloads/fx_manager.gd`
- **Core Responsibility:** Interacts globally via `SignalBus` to spawn floating visual effects independently from game logic.
- **Functions List:**
  - `_ready()`: Connects to health changed signals on the bus.
  - `_on_unit_health_changed(unit: Node, current_health: int, max_health: int, amount: int)`: Responds to damage or healing applied to nodes, spawning a floating text representation and managing tween animations before freeing it.
- **Refactor Notes:**
  - Standardized local variables typing (`text_instance: Label`, `tween: Tween`).

### `scripts/autoloads/game_state.gd`
- **Core Responsibility:** Acts as a session-wide global cache for ongoing run data such as current missions, deployment units, and previous battle results.
- **Functions List:**
  - `clear_state()`: Resets all tracked properties for starting new runs.
- **Refactor Notes:**
  - Strongly typed `current_mission` field to strictly hold `MissionData`.
  - Added specific `void` return types and strongly typed initializers.

### `scripts/autoloads/save_manager.gd`
- **Core Responsibility:** Handles game serialization and JSON formatting to save/load persistent campaign states.
- **Functions List:**
  - `_ready()`: Invokes setup of the standard save path.
  - `_ensure_save_directory_exists()`: Validates that the underlying OS user path structure exists to avoid save failures.
  - `save_game(slot_name: String, state_data: Dictionary) -> bool`: Wraps core state into a structured JSON save node and writes directly to disk.
  - `load_game(slot_name: String) -> Dictionary`: Opens local JSON state definitions, unpacks file strings, and transforms them into usable Godot Dictionaries.
  - `get_available_saves() -> Array[String]`: Reads the saves directory and strips `.json` tags to return formatted slot names.
  - `has_save_file() -> bool`: Helper checking for any populated index keys.
  - `delete_save(slot_name: String) -> bool`: Explicitly unlinks local files and removes game state references.
- **Refactor Notes:**
  - Upgraded arbitrary `var` initialization into static-typed instances (e.g., `Error`, `String`, `FileAccess`, `JSON`, `Dictionary`).

### `scripts/autoloads/scene_manager.gd`
- **Core Responsibility:** Minimal manager to facilitate scene transitions dynamically.
- **Functions List:**
  - `goto_scene(path: String)`: Handles synchronous scene swaps using local `.tscn` resource paths.
- **Refactor Notes:**
  - Strongly typed the standard returned `Error` enumerator inside `change_scene_to_file`.

### `scripts/autoloads/settings_manager.gd`
- **Core Responsibility:** Caches application config strings (`.cfg`) focusing on OS presentation, frame limiting, and audio routing.
- **Functions List:**
  - `_ready()`: Triggers configuration loading and immediate application.
  - `_load_settings()`: Reads `user://settings.cfg`, defaults to new structure if empty.
  - `_create_default_settings()`: Hardcodes baseline constants to apply to raw devices for resolution and volumes.
  - `_apply_settings()`: Pushes data into `WindowManager` when explicitly prompted or loaded.
  - `save_settings()`: Triggers a manual flush to disk.
  - `get_setting(section: String, key: String, default_val) -> Variant`: Abstraction over `ConfigFile.get_value`.
  - `set_setting(section: String, key: String, value: Variant, auto_save: bool)`: Value injection API.
- **Refactor Notes:**
  - Strongly typed loaded metrics from configs (e.g. `w_mode: int`, `vsync: bool`, `fps_limit: int`).

### `scripts/autoloads/signal_bus.gd`
- **Core Responsibility:** Hub of loosely coupled signals allowing all other Autoloads and Managers to observe actions without concrete dependencies.
- **Refactor Notes:**
  - Verified no changes were strictly needed as GDScript signals intrinsically dictate their parameters cleanly.

### `scripts/autoloads/ui_manager.gd`
- **Core Responsibility:** Handles dynamic UI injection of Modals over existing screens using a 100-indexed CanvasLayer, effectively blocking interactions beyond the overlay.
- **Functions List:**
  - `_ready()`: Instantiates core layout backgrounds (`modal_layer`, `background_blocker`) and connects up to `SignalBus` UI requests.
  - `_on_navigation_requested(panel_name: String)`: Standard event handler swapping active windows based on string requests.
  - `_open_modal(scene_pack: PackedScene)`: Frees existing modular overlays, pushes an active blocking mask, and injects a new instanced `.tscn`. Connects tree exit listeners to self-manage blocker visibility.
  - `_close_all_modals()`: Blindly dumps current UI children that don't match the background structure.
  - `_check_modals()`: Validation tool polling to determine if standard blockers should remain visible.
- **Refactor Notes:**
  - Extracted potentially ambiguous duck-typing for `tree_exited` listening, explicitly checking `.has_signal()` directly on the instantiated node.
  - Applied strict standard static typing (`Node`, `Control`, `int`).

### `scripts/autoloads/window_manager.gd`
- **Core Responsibility:** Direct mediator for `DisplayServer` and `Engine` interactions. Hooks specifically into `_notification` to capture global OS system-level closure requests for safe game state saving.
- **Functions List:**
  - `_ready()`: Disables auto OS quitting and forces default initialization parameters by polling `SettingsManager`.
  - `_notification(what: int)`: Responds inherently to Godot notifications mapping OS commands.
  - `_handle_safe_quit()`: Wraps signal emitting logic prior to formal process death.
  - `set_fullscreen(is_fullscreen: bool)`, `set_vsync(enabled: bool)`, `set_fps_limit(fps_limit: int)`: Concrete implementations modifying `DisplayServer` characteristics.
- **Refactor Notes:**
  - Typed polled local variable attributes on startup (`int`, `bool`).

### `scripts/data/models/` (Data Model References)
- **Core Responsibility:** Standardized structural class models (`.gd`) establishing properties applied to custom resources (`.tres`) mapped by `DataManager`.
- **Processed Files:**
  - `armor_data.gd`, `map_object_data.gd`, `mission_data.gd`, `unit_data.gd`, `weapon_data.gd`.
- **Refactor Notes:**
  - Verified they accurately employ GDScript 2.0 `@export` systems correctly and use type annotations out of the box.

---
*End of Phase 1 Execution*
## Phase 2: Managers & AI Framework

### `scripts/managers/ai_manager.gd`
- **Core Responsibility**: Global AI evaluation processor coordinating the Planning Phase. Manages enemy deployment by spawning units in zones with respect to AI roles and triggers Behavior Tree evaluation for active units.
- **Functions List**:
  - `_ready()`: Connects `wego_phase_started` and `enemy_deployment_requested` signals.
  - `register_unit(unit: Node)`: Adds unit to AI processing list.
  - `unregister_unit(unit: Node)`: Removes unit from list.
  - `_on_enemy_deployment_requested(...)`: Expands roster, sorts by tactical role, instantiates enemy unit scenes, scores available deployment tiles, places units, and registers them.
  - `_on_phase_started(...)`: Validates planning phase and initiates AI processing.
  - `process_planning_phase()`: Loops through active units executing their AI component Behavior Trees. Afterwards starts execution via `PhaseManager`.
- **Refactor Notes**:
  - Replaced Godot 3 signal string connects with Godot 4 `Signal.connect` syntax.
  - Removed tight coupling to absolute UI root (`/root/Battlefield/Units`). Instead, implemented fallback logic checking `get_tree().current_scene.get_node("Units")`.
  - Removed tight coupling assumption of `PhaseManager` existing at root (`get_node("/root/PhaseManager")`) and replaced it with direct Autoload access (`PhaseManager`).
  - Added strict static typing to loop variables and arguments (e.g., `unit_data: UnitData`, `score: float`).

### `scripts/managers/combat_manager.gd`
- **Core Responsibility**: A pure logic/math service that calculates physical interaction results between units like damage values and knockback impacts. Orchestrates the initial deployment signal using `GameState`.
- **Functions List**:
  - `_ready()`: Connects `wego_phase_started`.
  - `_on_phase_started(...)`: On deployment, fetches the `enemy_roster` from `GameState.current_mission` and emit `enemy_deployment_requested`.
  - `calculate_damage(...)`: Analyzes attacker/defender elevations, weapon damage types, facing directions, and armor data to return final hit damage.
  - `calculate_impact(...)`: Uses weapon knockback force and direction to compute a resulting displacement vector.
- **Refactor Notes**:
  - Updated signal connect syntax to Godot 4 standard.
  - Added strict static typing across internal formula calculations (e.g., `var damage_modifier: float`, `var base_dmg: int`, `var final_damage: int`).

### `scripts/managers/environment_manager.gd`
- **Core Responsibility**: Orchestrates procedural map generation pipeline including base terrains, paths, structures, and scatter placements. Also handles rendering Z-layers, lighting (day/night), and weather overlays.
- **Functions List**:
  - `_ready()`: Bootstraps weather particle systems, canvas modulations, noise parameters, and signal connections.
  - `generate_map(...)`: Entry point. Triggers GridManager init, followed by generation steps.
  - `step1_terrain_base()`: Loops grid using Perlin noise to assign z-heights, move penalties, and spawn tile rectangles.
  - `step2_roads()`: (Placeholder logic) Overrides middle rows to road properties.
  - `step3_structures()`: Selects random coordinates, flattens ground, configures map object blocking data, and instantiates structures.
  - `step4_scatter_and_deploy_zones()`: Places scatter items (trees, rocks) based on noise and highlights deployment tiles at the top/bottom edges.
  - `get_enemy_deployment_zones()`: Returns array of valid positions for enemies to spawn.
  - `_get_or_create_layer(...)`: Helper to build z-indexed `Node2D` groups for sorting Map visuals.
  - UI/Vis Helpers: `_on_camera_z_level_changed`, `_spawn_tile_visual`, `_highlight_deploy_zone`, `transition_to_night/day`, `start/stop_weather`.
- **Refactor Notes**:
  - Removed dynamic `load("res://...")` calls inside the procedural map generation steps.
  - Extracted hardcoded object scenes into `@export var structure_scene: PackedScene` fields, preloading defaults to ensure they are statically resolved and editable in Inspector.
  - Explicitly typed all procedural calculation variables (`z_height: int`, `move_penalty: float`, `cell_pos: Vector2i`, etc.).

### `scripts/managers/grid_manager.gd`
- **Core Responsibility**: Central system managing AStar grid logic, tile statistics, multi-floor Z-level elevations, pathfinding computations, and line-of-sight algorithms.
- **Functions List**:
  - `initialize_grid(...)`: Resets grid configurations and AStar references.
  - `set_tile_data(...)`: Injects specific configuration onto a coordinate, tracking z-heights, movement weights, and static blocking.
  - `add_map_object(...)`: Integrates environmental objects (structures, trees) by updating movement costs and cover values on standard tiles.
  - `finalize_grid()` & `_connect_grid_neighbors()`: Links adjacent tiles in AStar, forbidding connections if the Z-level difference is greater than 1.
  - Conversion Helpers: `get_grid_position2d`, `get_grid_position` (3D), `get_world_position`.
  - `get_effective_distance(...)`: Calculates 3D distance considering vertical height scaling constraints.
  - `get_grid_path(...)`: Core A* request for pathfinding array.
  - `check_line_of_sight(...)`: Raycasts algorithm checking elevation/static blocks.
- **Refactor Notes**:
  - Applied strict static typing across mathematical and iterative blocks.
  - Updated AStar ID retrieval and loops to handle Godot 4 `PackedInt64Array` types cleanly.
  - Converted loose implicit assignments into explicit types (`var delta_x: int = pos_b.x - pos_a.x`, `var max_sight_height: int`).

### `scripts/managers/phase_manager.gd`
- **Core Responsibility**: Controls the WEGO (Simultaneous turn-based) flow engine, handling phase cycling (Deployment -> Planning -> Execution -> Resolution). Controls time scaling.
- **Functions List**:
  - Phase states tracking (`current_phase`, `turn_counter`, `units_executing`).
  - `start_combat()`: Initializes counter and drops into deployment.
  - Phase Transitioners: `start_deployment_phase`, `end_deployment_phase`, `start_planning_phase`, `start_execution_phase`, `start_resolution_phase`.
  - `_on_unit_action_finished(...)`: Tracker subtracting from pending active units to determine when EXECUTION is complete.
- **Refactor Notes**:
  - Rewrote Godot 3 signal subscription format to `SignalBus.unit_action_finished.connect(...)`.
  - Verified logic typing and enum usages, no tight node paths needed replacing.

### `scripts/ai/framework/`
- **Modules**: `bt_action.gd`, `bt_node.gd`, `bt_selector.gd`, `bt_sequence.gd`
- **Core Responsibility**: Modular Behavior Tree engine for AI unit decisions.
- **Functions List**:
  - `tick(unit, blackboard)`: Polymorphic tree execution logic. Selectors branch on SUCCESS, Sequences branch on FAILURE.
- **Refactor Notes**:
  - Refactored `bt_selector.gd` and `bt_sequence.gd` loop structures. Changed loose `for child in children:` to strictly typed `for child: BTNode in children:`.

---
*End of Phase 2 Execution*
## Phase 3: Entities & Components

### `scripts/entities/unit/unit.gd`
- **Core Responsibility:** Lightweight, team-agnostic root container node that visually and mechanically represents a unit in combat, deferring logic to its components.
- **Functions List:**
  - `_ready()`: Wires up WEGO execution phase listener and calls initialization.
  - `initialize(unit_data: UnitData, team: int = 0)`: Configures core stats, assigns ID/Name, and loops through components injecting a reference to itself.
  - `_on_phase_started(phase_name: String)`: Triggers AI component queuing when `execution` phase is triggered.
  - `set_facing(direction: Vector2)`: Stores unit facing and visually updates via `AnimationComponent`.
- **Refactor Notes:**
  - Added strict variable typing `current_elevation: int = 0`.
  - Refactored `initialize` to act as a proper Component Hub, passing `self` explicitly to each component (`health_component.initialize(self, data.max_health)`) to entirely eliminate tight coupling and the usage of `get_parent()`.

### `scripts/entities/unit/components/health_component.gd`
- **Core Responsibility:** Tracks current/max health and processes incoming damage along with calculating structural damage mitigation based on dynamically tracked cover.
- **Functions List:**
  - `_ready()`: Connects to `SignalBus.unit_cover_bonus_changed`.
  - `initialize(unit: Node, health: int)`: Receives owner reference and resets health states, emitting UI updates.
  - `_on_unit_cover_bonus_changed(unit: Node, cover_bonus: float)`: Dedicated listener replacing tight component polling. Updates local mitigation stats when `MovementComponent` detects terrain changes.
  - `take_damage(amount: int)`: Calculates mitigated damage against active cover bonus. Emits UI events and checks for death.
  - `die()`: Sets dead flag and signals completion, handling AI unregistration.
- **Refactor Notes:**
  - Removed `get_parent()` usage; owner is injected via `initialize(unit: Node, health: int)`.
  - Removed direct access/coupling of Autoloads via `has_node("/root/AIManager")`; instead references the global Autoload class `AIManager` natively.
  - Adopted `SignalBus` to decouple communication of terrain cover bonuses.

### `scripts/entities/unit/components/movement_component.gd`
- **Core Responsibility:** Handles AStar path execution, movement speed math, physics knockback implementations, and calculating tile transition status variables.
- **Functions List:**
  - `_ready()`: Empty initialization (replaced tight coupling).
  - `initialize(unit: Node, speed: float)`: Injects CharacterBody2D owner and establishes initial speeds.
  - `_physics_process(delta: float)`: Executes pathfinding nodes iteratively, adjusting velocity based on grid terrain penalties.
  - `set_path(new_path: Array[Vector2])`: Overwrites queue arrays.
  - `_update_terrain_state()`: Reads underlying `GridManager` TileData, directly updating its owner's `current_elevation` variable and broadcasting cover stats.
  - `apply_impulse(impulse_vector: Vector2)`: Instantly adjusts and applies knockback velocity.
- **Refactor Notes:**
  - Eradicated completely the anti-pattern `get_parent() is CharacterBody2D`. Owner is now correctly injected.
  - Eradicated completely the horizontal direct coupling to `HealthComponent` (`unit_owner.get_node("HealthComponent").current_cover_bonus = ...`). Component now uses `SignalBus.unit_cover_bonus_changed.emit(unit_owner, ...)` for complete isolation.

### `scripts/entities/unit/components/ai_component.gd`
- **Core Responsibility:** Holds the unit's active Behavior Tree (`BTNode`) instance and transforms AI execution decisions into executable command queues for WEGO phasing.
- **Functions List:**
  - `_ready()`: Emptied (stripped `get_parent()`).
  - `initialize(unit: Node, bt_preset: Resource)`: Assigns owner, tree resources, and directly registers to `AIManager`.
  - `evaluate_behavior()`: Core logic updating the blackboard and executing `tick` cycles against the behavior tree.
  - `queue_action(action_name: String, params: Dictionary)`: Stashes a behavior intended for the execution phase.
  - `execute_queued_action()`: Simulated delegation logic that eventually emits signal completion.
- **Refactor Notes:**
  - Refactored `initialize` to accept the `unit: Node` argument.
  - Removed explicit string path references (`/root/AIManager`) in favor of direct standard global Autoload resolution (`AIManager.register_unit(unit_owner)`).

### `scripts/entities/unit/components/animation_component.gd`
- **Core Responsibility:** Manages visual states like sprite flip directions, animations, and shader effects (e.g., hit flash parameters).
- **Functions List:**
  - `_ready()`: Wires up strictly to global health/death signals.
  - `initialize(unit: Node)`: Caches injected owner.
  - `_process(delta: float)` / `_process_hit_flash(delta: float)`: Counts down timers to revert shader properties.
  - `play_animation(anim_name: String)`: Skeleton mapping frame cycles.
  - `update_facing(facing_vector: Vector2)`: Adjusts sprite horizontal flips based on calculated velocity.
  - Event Handlers: `_on_unit_health_changed`, `_on_unit_died`. Triggers hit flashes.
- **Refactor Notes:**
  - Removed `get_parent()` usage, introducing a new `initialize(unit: Node)` method to abide by uniform Component patterns established.

### `scripts/entities/unit/components/targeting_component.gd`
- **Core Responsibility:** Performs structural line-of-sight verification and handles calculating target distances while cross-referencing multi-floor Z-levels.
- **Functions List:**
  - `_ready()`: Emptied.
  - `initialize(unit: Node)`: Assigns reference owner.
  - `get_nearest_target(max_range: float, elevation: int) -> Node`: Query framework skeleton logic.
  - `has_line_of_sight(target: Node) -> bool`: Coordinates GridManager requests matching start and target coordinates + specific elevation values.
- **Refactor Notes:**
  - Stripped `get_parent()` instantiation via explicit DI through `initialize`.
  - Eradicated cross-component coupling querying `MovementComponent` directly for elevations. Now cleanly polls the `current_elevation` integer explicitly injected onto the hub `unit_owner` level.

### `scripts/entities/map_objects/map_object.gd`
- **Core Responsibility:** Serves as the concrete Node2D representations of static terrain details (trees, rocks, destructibles) modifying the Grid dynamically during generation.
- **Functions List:**
  - `_ready()`: Ensures default `MapObjectData` parameters apply offset heights to UI elements mimicking cover/Z-level perspectives.
- **Refactor Notes:**
  - Scanned for strict typing and decoupling needs. Verified logic meets parameters as no node coupling exists and typing applies correctly to properties (`data: MapObjectData`, `color_rect: ColorRect`).
## Phase 4: Environment, UI & VFX Scripts

### `scripts/managers/input_manager.gd` (New)
- **Core Responsibility**: Centralizes global input processing (WASD camera panning, mouse wheel zooming, Z-level keys, map clicks) and translates them into semantic signals broadcast via `SignalBus`.
- **Functions List**:
  - `_process(delta: float)`: Polls WASD input for camera panning.
  - `_input(event: InputEvent)`: Delegates event logic to handlers.
  - `_handle_camera_pan()`: Emits `camera_pan_input`.
  - `_handle_camera_zoom(event)`: Detects scroll wheel and emits `camera_zoom_input`.
  - `_handle_z_level(event)`: Detects PageUp/Down and emits `camera_z_level_input`.
  - `_handle_mouse_clicks(event)`: Emits `map_clicked` upon left-click for world interactions.
- **Refactor Notes**:
  - Created to eliminate direct input querying in disparate scripts (like `TacticalCamera2D` and `DeploymentUI`), enforcing a centralized event-driven input architecture.

### `scripts/managers/deployment_manager.gd` (New)
- **Core Responsibility**: Manages the logic of spawning units during the deployment phase, cleanly separating visual UI interactions from actual scene modification.
- **Functions List**:
  - `_ready()`: Connects to `spawn_unit_requested` signal.
  - `_on_spawn_unit_requested(...)`: Validates deployment phase, verifies deployable tiles via `EnvironmentManager`, instantiates the unit, configures its initial position/Z-height, appends it to the `Battlefield/Units` container, and broadcasts `unit_spawned`.
- **Refactor Notes**:
  - Abstracted unit instantiation away from `DeploymentUI`. Prevents UI from tightly coupling with `get_tree().root.get_node("Battlefield")`.

### `scripts/map/battlefield.gd`
- **Core Responsibility**: Bootstraps the tactical combat map environment, triggering tilemap generation and officially starting the combat phase logic.
- **Functions List**:
  - `_ready()`: Initiates map generation, broadcasts calculated bounds via `SignalBus`, and calls `PhaseManager.start_combat()`.
- **Refactor Notes**:
  - Removed tight coupling to `$TacticalCamera2D`. Now emits an `environment_bounds_changed` signal so the camera configures its own limits independently.

### `scripts/map/tactical_camera.gd`
- **Core Responsibility**: Controls the visual viewport, managing pan, continuous zoom, boundary limits, and broadcasting Z-level view changes for level rendering.
- **Functions List**:
  - `_ready()`: Subscribes to input signals (`pan`, `zoom`, `z_level`, `bounds`).
  - `_process(delta: float)`: Applies smoothed vectors to position and zoom.
  - `_on_environment_bounds_changed(...)`: Updates clamping limits based on generated environment sizes.
  - Handlers (`_on_pan_input`, `_on_zoom_input`, `_on_z_level_input`): Translate incoming signals into target vectors.
  - `_apply_movement(...)` / `_apply_zoom(...)`: Core math applying smoothed interpolation.
- **Refactor Notes**:
  - Eliminated raw `_input` handling and `Input.is_key_pressed` queries, entirely replacing them with listeners to `SignalBus`. Removed dependency on `battlefield.gd` explicitly setting its limits.

### `scripts/ui/deployment_ui.gd`
- **Core Responsibility**: User interface for selecting and confirming troop placements during the WEGO deployment phase.
- **Functions List**:
  - `_ready()`: Wires up UI button listeners and `SignalBus.map_clicked`.
  - `_on_unit_selected(...)`: Caches selected string.
  - `_on_map_clicked(...)`: Converts viewport mouse positions into global coordinates, translates them into grid coordinates, and emits `spawn_unit_requested`.
  - `_on_confirm_pressed()`: Triggers deployment phase end.
- **Refactor Notes**:
  - Deleted raw input handling and `get_global_mouse_position()` querying through hardcoded camera references.
  - Replaced tight coupling to `get_tree().root.Battlefield.Units` with a pure signal broadcast handled by `DeploymentManager`.

### `scripts/ui/overlays/tactical_visualizer.gd`
- **Core Responsibility**: Standalone UI overlay (toggled via debug key) responsible for visualizing AI intent lines and queue states during combat processing.
- **Functions List**:
  - `_ready()`: Hides overlay and connects to `ai_debug_data_broadcasted`.
  - `_input(event)`: Listens for debug key F3 to toggle visibility.
  - `toggle_visualizer()`: Flips visibility and clears lines/labels if hidden.
  - `_on_ai_debug_data_broadcasted(active_units: Array)`: Dynamically renders labels and line primitives based on `AIComponent` states.
  - `clear_visuals()`: safely purges drawn nodes.
- **Refactor Notes**:
  - Stripped `_process` and direct querying of `/root/AIManager`. Now behaves passively, entirely driven by `ai_debug_data_broadcasted` signals to avoid coupling visualizers to core system managers.

### `scripts/managers/ai_manager.gd` (Updated for Phase 4)
- **Refactor Notes**:
  - Added a `_process` function specifically to broadcast its `active_units` array via `SignalBus.ai_debug_data_broadcasted` every frame, fulfilling the decoupled data needs of debug overlays like `TacticalVisualizer`.

### `scripts/visual_effects/floating_text.gd`
- **Core Responsibility**: Instantiable visual effect representing transient data (damage, healing, states) dynamically drawn over units.
- **Functions List**:
  - `_ready()`: Instantiates parallel tweens to animate the position vertically, fade opacity to zero, and automatically queue itself for deletion.
- **Refactor Notes**:
  - Implemented missing logic for the placeholder script, ensuring basic functionality without adding complexity or coupling to unit logic.

## Phase 5: Map & Camera Scenes (`scenes/map/`)

### `scripts/map/battlefield.gd`
- **Core Responsibility:** Bootstraps the tactical combat map environment, triggering tilemap generation and officially starting the combat phase logic.
- **Functions List:**
  - `_ready()`: Initiates map generation, broadcasts calculated bounds via `SignalBus`, and calls `PhaseManager.start_combat()`.
- **Refactor Notes:**
  - Verified logic. It properly avoids tight coupling to the camera and uses `SignalBus` to decouple bounds configuration. The file paths in the `battlefield.tscn` were correctly referencing `scenes/ui/screens/deployment_ui.tscn` and `scenes/map/tactical_camera.tscn`.

### `scripts/map/tactical_camera.gd`
- **Core Responsibility:** Controls the visual viewport, managing pan, continuous zoom, boundary limits, and broadcasting Z-level view changes for level rendering.
- **Functions List:**
  - `_ready()`: Subscribes to input signals (`pan`, `zoom`, `z_level`, `bounds`).
  - `_process(delta: float)`: Applies smoothed vectors to position and zoom.
  - `_on_environment_bounds_changed(...)`: Updates clamping limits based on generated environment sizes.
  - Handlers (`_on_pan_input`, `_on_zoom_input`, `_on_z_level_input`): Translate incoming signals into target vectors.
  - `_apply_movement(...)` / `_apply_zoom(...)`: Core math applying smoothed interpolation.
- **Refactor Notes:**
  - Verified logic. Uses explicit typing and strictly listens to central `SignalBus` events rather than polling inputs directly.

## Phase 6: Entity & Component Scenes (`scenes/entities/`)

### `scripts/entities/unit/unit.gd`
- **Core Responsibility:** Lightweight, team-agnostic root container node representing combatants. Loads appearance, stats, and behavior dynamically from `UnitData`.
- **Functions List:**
  - `_ready()`: Wires the execution phase via `SignalBus`.
  - `initialize(unit_data, team)`: Injects data and recursively initializes all dependent components without `get_parent()` coupling.
  - `_on_phase_started(phase_name)`: Triggers AI component queues during the execution phase.
  - `set_facing(direction)`: Relays directional logic to the `AnimationComponent`.
- **Refactor Notes:**
  - Verified logic. Strongly typed and passes dependency injection down correctly.

### Components (`scripts/entities/unit/components/`)
- **Core Responsibility:** Provide isolated logic for health (`health_component.gd`), movement and pathing (`movement_component.gd`), targeting (`targeting_component.gd`), AI commands (`ai_component.gd`), and animation logic (`animation_component.gd`).
- **Refactor Notes:**
  - Validated all components for strict typing and isolation. None rely on `get_parent()`. All rely on their `initialize(unit: Node)` functions. They exclusively communicate across the framework using `SignalBus` events like `unit_health_changed` and `unit_cover_bonus_changed`.

### `scripts/entities/map_objects/map_object.gd`
- **Core Responsibility:** Serves as the concrete Node2D representation for static terrain elements like rocks and trees.
- **Functions List:**
  - `_ready()`: Instantiates visual offsets based on `MapObjectData` definitions.
- **Refactor Notes:**
  - Validated typing and logic. Safely retrieves its UI nodes via `has_node()` checks.

## Phase 7: UI & VFX Scenes (`scenes/ui/`, `scenes/visual_effects/`)

### `scripts/ui/screens/`
- **Core Responsibility:** Central scripts for major screen flows like `boot_screen.gd`, `main_menu_screen.gd`, `war_desk_screen.gd`, `deployment_screen.gd`, `battle_screen.gd`, `post_battle_screen.gd`.
- **Functions List:**
  - `_ready()` / event handlers: Configure local UI routing and handle button clicks.
- **Refactor Notes:**
  - Refactored physical file paths. All UI `.gd` scripts were extracted from `scenes/ui/` into a dedicated `scripts/ui/` matching directory.
  - Eliminated hardcoded `preload()` string paths in scripts like `battle_screen.gd` and `pause_menu.gd` by exposing them via `@export var packed_scene` to prevent hard-coupling to `scenes/ui/` folders.
  - Updated standard routing like `SceneManager.goto_scene("res://scenes/...tscn")` to remain functional. Strict typing (e.g., `-> void`) added to lifecycle methods.

### `scripts/visual_effects/floating_text.gd`
- **Core Responsibility:** Basic floating text effect that animates upward, fades out, and frees itself using Tweens.
- **Functions List:**
  - `_ready()`: Configures and plays the property tweens for the float and fade effect.
- **Refactor Notes:**
  - Validated that the visual effect does not contain any game logic, relies strictly on Godot 4's Tween system, and auto-cleans up memory. Typing is fully strict.
