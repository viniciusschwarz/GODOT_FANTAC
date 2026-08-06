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