You are an expert Godot 4 developer and a patient, didactic programming mentor. I am building a 2D Tactical Auto-Battler MVP. I need you to generate the code for 4 new phases of development.

### 🏗️ Current Architecture & Strict Guidelines
1. **Decoupled Modularity:** Scripts must not hard-depend on each other. Use the central Autoload `GameHub.gd` for routing data and Custom Signals.
2. **Data-Driven:** All unit stats come from an Autoload `UnitDatabase.gd` that reads a `units_database.json` file. Do not hardcode unit stats.
3. **Beginner-Friendly:** Write heavily commented, clean code. Explain *why* you are doing things. Use simple logic.
4. **Complete Code:** Provide the full updated scripts for any file that needs changing. Do not use placeholders like "// rest of the code here".

### 🚀 Tasks to Implement

Please provide the step-by-step instructions and complete code to implement the following 4 phases:

**Phase 1: Projectiles and Visual Polish**
* Create a new `Projectile.tscn` (Node2D with a Sprite2D).
* Create `Projectile.gd`. It should take a target node, a damage amount, and use a `Tween` to fly to the target's `global_position`. When the Tween finishes, it applies the damage and calls `queue_free()`.
* Update `UnitBase.gd` so that if `attack_range > 1`, it spawns this projectile instead of applying damage instantly.

**Phase 2: Complex Terrain Costs**
* Update `Board.gd` to generate a new terrain type: `WATER` (paint it blue).
* Tell `GameHub.gd` which tiles are water.
* Update `Pathfinder.gd` (which uses `AStarGrid2D`). Use `astar.set_point_weight_scale()` to make water tiles cost 2.0 movement points instead of 1.0. 

**Phase 3: Area of Effect (AoE) Combat & Mages**
* Provide an updated `units_database.json` that includes an "attack_type" key ("melee", "ranged", or "aoe"). Add a "Mage" unit to this JSON with AoE.
* Add a helper function in `GameHub.gd` called `get_enemies_in_radius(center_grid_pos, radius, enemy_team_id)` that returns an array of units.
* Update `UnitBase.gd` so that if its `attack_type` is "aoe", it grabs all enemies in a 1-tile radius of its primary target and damages all of them.

**Phase 4: Expanded AI Behaviors**
* In `GameHub.gd`, add a helper function `get_weakest_enemy(my_team_id)` that iterates through active units and returns the enemy with the lowest current HP.
* In `UnitBase.gd`, flesh out the `Focus.HUNT_WEAKEST` logic to use this new Hub function. 
* Flesh out the `Focus.DEFEND_POSITION` logic so the unit skips its movement phase and ONLY attacks if an enemy naturally walks into its `attack_range`.

Please guide me through implementing these 4 phases sequentially, providing the full updated code for `GameHub.gd`, `Board.gd`, `Pathfinder.gd`, `UnitBase.gd`, and the new `Projectile.gd`.