# Section 6: Map Generation & World Simulation

Welcome to **Section 6: Map Generation & World Simulation**.

This section details the systems responsible for building the tactical battlefields, handling spatial data like Z-levels, managing initial unit deployment, and integrating the generated environment with the combat simulation engine.

Our environment strategy relies on a hybrid approach: **procedural terrain generation combined with pre-generated logical structures**, utilizing Godot 4's built-in tile tools, and custom data resources for dynamic elements.

---

## 1. Procedural Generation Pipeline

To create realistic and tactically interesting scenes, maps are not purely random noise. Instead, they are generated using a logical, multi-step pipeline. The `EnvironmentManager` (Autoload) oversees this generation process.

### Generation Steps

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Terrain Base & Height Map                                │
│    - Generate underlying terrain elevation (Z-levels).      │
│    - Define base biomes (e.g., grass, mud, rock).           │
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Road & Path Networks                                     │
│    - Draw paths connecting key points or map edges.         │
│    - Smooth/level the terrain along roads (lighter height   │
│      differences to allow traversal).                       │
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Pre-Generated Structures Placement                       │
│    - Spawn hand-crafted prefabs (houses, towers, villages). │
│    - Snap to logical locations (e.g., adjacent to roads).   │
│    - Flatten terrain underneath structures automatically.   │
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Scatter Objects & Obstacles                              │
│    - Place trees, rocks, barrels, and debris organically.   │
│    - Define pre-battle deployment zones based on terrain.   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Tile Mapping, Z-Levels, & Data Layers

We leverage Godot 4's built-in tilemap features to handle static terrain, separating static data from dynamic map objects.

### Static Terrain (Godot TileSets & Custom Data Layers)
For static ground, roads, and immovable map boundaries, we use Godot's `TileMapLayer` nodes configured with **Custom Data Layers**. These layers bake intrinsic properties directly into the grid tiles.

| Custom Data Layer | Type | Description |
| :--- | :--- | :--- |
| `base_z_height` | Integer | The base elevation level of the terrain tile (e.g., 0 for ground, 1 for hill). |
| `move_penalty` | Float | Multiplier for pathfinding cost (e.g., mud = 1.5, road = 0.8). |
| `static_los_block` | Boolean | True if the terrain tile inherently blocks Line of Sight (e.g., a solid cliff face). |

### Dynamic & Placeable Objects (Custom Resources `.tres`)
For everything else—like trees, destructible barrels, rocks, rubble, and barricades—we use instanced nodes driven by custom `MapObjectData` resources (`.tres`).

These `.tres` files define how the object interacts with units, pathing, and targeting:

*   **`blocks_pathing`** (Bool): Does it physically block movement?
*   **`los_block_height`** (Integer): At what Z-level does this object block Line of Sight?
*   **`movement_cost`** (Float): Penalty applied when stepping onto the object's tile (e.g., rubble).
*   **`cover_bonus`** (Float): Damage mitigation granted to units taking cover behind or inside this object.

---

## 3. Pre-Battle Deployment Phase

Before the auto-battler simulation begins, players must allocate their forces. This is seamlessly integrated into the existing `PhaseManager` state flow.

### Updated PhaseManager Flow

The `PhaseManager` is expanded to include a new `DEPLOYMENT_PHASE` at the very beginning of the battle scene.

```
[ START BATTLE SCENE ]
          │
          ▼
┌──────────────────────┐
│  DEPLOYMENT_PHASE    │  <-- NEW
│  - Time Paused       │
│  - Player assigns    │
│    units to valid    │
│    Spawn Zones       │
└─────────┬────────────┘
          │ (Player Confirms Placement)
          ▼
┌──────────────────────┐
│  PLANNING_PHASE      │  (From Section 3)
│  - AI evaluates      │
│  - Action Queues     │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│  EXECUTION_PHASE     │  (From Section 3)
└──────────────────────┘
```

**Deployment Zones:** During Map Generation (Step 4), specific logical areas are tagged as `deployable_tiles`. The player's UI allows drag-and-drop or click-to-place assignment of units strictly within these zones.

---

## 4. Combat Simulation Integration

To efficiently process the effects of terrain on combat (e.g., stepping on rubble, gaining high-ground advantage, or finding cover), the environment data is pushed *onto* the units, rather than forcing the `CombatManager` to constantly poll the `GridManager`.

### Dynamic Terrain States on Units
When a unit's `MovementComponent` moves onto a new tile, it queries the `GridManager` for that specific tile's combined static and dynamic properties. The unit then caches these properties as local states.

**Unit Data State Changes:**
1.  **Movement Update:** If stepping on rubble, the unit's local `current_move_speed` is multiplied by the rubble's `movement_cost`.
2.  **Cover & Defense:** If stepping onto a tile adjacent to a tree/rock relative to enemy fire, the unit applies a `cover_bonus` to its `HealthComponent` mitigations.
3.  **Z-Level Advantage:** The unit's active `current_z_elevation` state is updated. The `CombatManager` and `TargetingComponent` use this state directly to grant range extensions or accuracy bonuses, without needing to re-check the tile data.

### Interaction Flow Example

```text
Unit MovementComponent steps onto Tile (X: 10, Y: 15)
  ├── Queries GridManager for Tile(10, 15) Data
  ├── GridManager returns: { "z_height": 1, "move_penalty": 1.2, "cover_bonus": 0.0 }
  └── Unit locally updates:
        - self.elevation = 1
        - self.speed_modifier = 1.2

AIManager Planning Phase
  ├── TargetingComponent checks LOS to Enemy
  ├── Compares self.elevation (1) vs Enemy elevation (0)
  └── Calculates bonus attack range based on elevation delta.
```

---

## 5. Directory & File Structure Updates

The file structure is updated to support the map generation and map object features described above:

```text
res://
├── Managers/
│   ├── PhaseManager.gd          # Updated with DEPLOYMENT_PHASE
│   ├── GridManager.gd           # Handles TileMap interactions & tile data queries
│   └── EnvironmentManager.gd    # NEW: Orchestrates the procedural generation pipeline
│
├── Scenes/
│   └── Map/
│       ├── Battlefield.tscn     # The main battle scene holding the TileMapLayer
│       └── Prefabs/             # Pre-generated structures for logical placement
│           ├── house_basic.tscn
│           ├── watchtower.tscn
│           └── road_segment.tscn
│
├── Entities/
│   └── MapObjects/              # Dynamic/placeable objects
│       ├── map_object.gd        # Base script for dynamic objects
│       ├── tree.tscn
│       └── rock_formation.tscn
│
└── Data/
    └── Models/
        └── map_object_data.gd   # Custom Resource defining obstacle stats (cover, LOS, cost)
```
