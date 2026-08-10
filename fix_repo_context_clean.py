with open('REPO_CONTEXT.md', 'r') as f:
    content = f.read()

# Replace Spatial Movement Section
old_spatial = """### The Grid System and Spatial Movement

The battlefield operates on a discrete 3D spatial grid represented by `Vector3i` (12x12x2 grid).

#### 4-Directional Cardinal Movement

Pathfinding strictly relies on four-directional cardinal steps (North, South, East, West). The system evaluates movement across individual tiles. Diagonal traversal is strictly prohibited by base impassability evaluations, which query a tile's bitmask and vertical connectivity rules. The core validation function, `BattlefieldMatrix.is_cardinal_passable()`, enforces a strict coordinate offset sum limit: `abs(dx) + abs(dy) == 1`."""
new_spatial = """### The Grid System and Spatial Movement

The battlefield operates on a discrete 3D spatial grid represented by `Vector3i` (12x12x2 grid).

#### 4-Directional Cardinal Movement

Pathfinding strictly relies on four-directional cardinal steps (North, South, East, West). The system evaluates movement across individual tiles. Diagonal traversal is strictly prohibited by base impassability evaluations, which query a tile's bitmask and vertical connectivity rules. The core validation function, `BattlefieldMatrix.is_cardinal_passable()`, enforces a strict coordinate offset sum limit: `abs(dx) + abs(dy) == 1`. Pathfinding logic uses hesitation cooldowns (e.g., 5-tick `path_recalculation_cooldown`) to mitigate deadlocks without locking units out from combat decisions (like swinging at adjacent enemies)."""
content = content.replace(old_spatial, new_spatial)

# Replace Combat Mechanics Section
old_combat = """### Combat Mechanics

#### Weapon Hardness vs. Prop Degradation"""
new_combat = """### Combat Mechanics

#### Weapon Cooldowns and Attack Resolutions
Weapon cooldowns (`attack_cooldown`) are explicitly decremented in the `SimulationServer` micro-tick loop. When an attack executes, the `SimulationServer` resets this cooldown. The `AITreeEvaluator` strictly bypasses attack branches (falling back to `ADVANCE_TO_OBJECTIVE` or `HOLD_ENGAGEMENT`) when cooldowns are > 0. For holding positions due to cooldowns, the evaluator assigns `target_coord = unit_coord` to bypass path generation.

#### Weapon Hardness vs. Prop Degradation"""
content = content.replace(old_combat, new_combat)

# Replace Data Flow Pipeline Section
old_pipeline = """1. **Input (Planning Phase):**
   - The user interfaces with the `BattlefieldView` and `UIManager` to inject active waypoint intents (`active_waypoints`) and override AI directives via the `CommanderInspectorUI`.
   - Once all intents are validated, `MainGameManager` compiles these directives into a `TurnPlanResource`."""
new_pipeline = """1. **Input (Planning Phase):**
   - The user interfaces with the `BattlefieldView` and `UIManager` to inject active waypoint intents (`active_waypoints`, limited to strictly one waypoint per unit) and override AI directives via the `CommanderInspectorUI`. Visual intent lines are drawn directly from the unit's token to the target tile's center.
   - Once all intents are validated, `MainGameManager` compiles these directives into a `TurnPlanResource`."""
content = content.replace(old_pipeline, new_pipeline)

# Replace Single Prefab Section
old_prefab = """### Dynamic Prefab Construction
FANTAC employs a strictly "single-prefab" structural rule for UI elements.
Instead of hardcoding extensive rosters into massive panel layouts, the UI relies on singular dynamically generated blocks. For example, instead of storing individual cards for all active allied units on screen, a single dynamic `CommanderInspectorUI` is injected by the UI Manager. When `unit_selected` is triggered, that single generic prefab parses the respective `UnitDataResource` and reloads all labels and icons, maintaining optimal draw-call efficiency and ensuring complete isolation between the scene hierarchy and active entity caches."""
new_prefab = """### Dynamic Prefab Construction
FANTAC employs a strictly "single-prefab" structural rule for UI elements.
Instead of hardcoding extensive rosters into massive panel layouts, the UI relies on singular dynamically generated blocks. For example, instead of storing individual cards for all active allied units on screen, a single dynamic `CommanderInspectorUI` is injected by the UI Manager. When `unit_selected` is triggered, that single generic prefab parses the respective `UnitDataResource` and reloads all labels and icons, maintaining optimal draw-call efficiency and ensuring complete isolation between the scene hierarchy and active entity caches.

### Note on Advanced Mechanics
For a complete, code-free exhaustive explanation of the mechanics, simulation ticks, Z-level transversals, morale fracturing, and rendering architecture, please consult the `docs/Simulation_Engineering_Manual.md`."""
content = content.replace(old_prefab, new_prefab)

with open('REPO_CONTEXT.md', 'w') as f:
    f.write(content)
