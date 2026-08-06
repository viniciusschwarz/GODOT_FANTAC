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
