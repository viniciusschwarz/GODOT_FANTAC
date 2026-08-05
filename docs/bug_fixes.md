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
