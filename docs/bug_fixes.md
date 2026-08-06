# Bug Fixes
## Date: $(date +"%Y-%m-%d")

### Issues Resolved:
1. **Duplicate Global Class Hiding:**
   - `UnitData` and `WeaponData` classes were duplicated across `scripts/data/models/` and `scripts/resources/`.
   - **Fix:** Removed the duplicated JSON-parsing classes in `scripts/resources/` in favor of keeping the `data/models/` classes that utilize Godot's built-in `@export` attributes, honoring the "data-driven" workflow directive using `.tres` resources.

2. **Missing `DamageType` property in `WeaponData`:**
   - The JSON parsing variant of `WeaponData` lacked the `DamageType` enum, causing errors in `CombatManager.gd`.
   - **Fix:** Removed the inadequate JSON parsing model, leaving the `scripts/data/models/weapon_data.gd` which already had the enum.

3. **`SaveManager.save_game()` missing arguments:**
   - `scenes/ui/screens/war_desk_screen.gd` called `SaveManager.save_game()` without passing the required `slot_name` and `state_data` arguments.
   - **Fix:** Updated the function calls to `SaveManager.save_game("auto_save", {})` to resolve the script parse error and allow proper transition testing from the main menu/war desk.

4. **Migrated Data System from JSON to .tres:**
   - With the old JSON parsing scripts gone, the JSON data files were removed.
   - **Fix:** Authored valid Godot 4 `.tres` files for Weapons (`iron_sword.tres`, `short_bow.tres`, `wooden_staff.tres`), Units (`knight.tres`, `archer.tres`, `mage.tres`), and Rules (`physics.tres`, `weather.tres`) under the `resources/` folder.
   - Rewrote `scripts/autoloads/data_manager.gd` to parse `.tres` resource files from their respective directories instead of loading missing `.json` files.

5. **Boot Screen Initialization Error:**
   - The game crashed on startup due to a missing file `res://assets/graphics/sprites/icon.svg`.
   - **Fix:** Created a placeholder `icon.svg` in `assets/graphics/sprites/` to satisfy the project configuration.

6. **Invalid Function Call in `boot_screen.gd`:**
   - `scenes/ui/screens/boot_screen.gd` attempted to call `SettingsManager.load_and_apply_settings()`, which doesn't exist on the `SettingsManager` Autoload (it automatically loads and applies settings in `_ready`).
   - **Fix:** Removed the invalid function call `SettingsManager.load_and_apply_settings()` from `boot_screen.gd`.
7. **PhaseManager hardcoded paths in AIManager:**
   - The AIManager was trying to access the `PhaseManager` autoload via `get_node("/root/PhaseManager")`.
   - **Fix:** Switched it to use the global `PhaseManager` Autoload directly as Godot 4 automatically registers it.

8. **AIManager hardcoded root path coupling:**
   - The AIManager was explicitly targeting `get_node_or_null("/root/Battlefield/Units")` which could crash/fail depending on the active root level scene.
   - **Fix:** Added fallback logic to check `get_tree().current_scene.has_node("Units")` first before falling back to absolute paths.

9. **EnvironmentManager dynamic load references inside loops:**
   - The `EnvironmentManager` dynamically used `load("res://...")` for generating houses, rocks, and trees, which is not editable in the editor and could cause runtime hitches.
   - **Fix:** Exported variables initialized with `preload("res://...")` for `structure_scene`, `tree_scene`, and `rock_scene`, exposing them to the inspector while preserving the logic.
