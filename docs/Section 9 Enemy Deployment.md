# Section 9: Enemy Deployment & Logic

Welcome to **Section 9: Enemy Deployment & Logic**.

This section outlines how enemy forces are generated and placed onto the procedural battlefield prior to the start of combat. To provide a tactical challenge, enemies are not scattered entirely at random; their deployment utilizes basic spatial logic that accounts for unit roles, Z-levels, and cover.

---

## 1. Roster Definition via `MissionData`

As outlined in Section 8, the enemy composition is strictly data-driven, defined within the `MissionData.tres` resource selected by the player on the Campaign screen.

The `enemy_roster` property is an `Array` of `Dictionaries`, mapping a specific `UnitData.tres` to a spawn quantity.

**Example Data Structure:**
```json
[
  { "unit_data": "res://resources/units/goblin_melee.tres", "count": 4 },
  { "unit_data": "res://resources/units/goblin_archer.tres", "count": 2 },
  { "unit_data": "res://resources/units/goblin_shaman.tres", "count": 1 }
]
```

---

## 2. Enemy Deployment Zones

During the Map Generation pipeline (Section 6, Step 4), the `EnvironmentManager` designates specific areas as `enemy_deployment_zones`.

These zones are typically generated on the opposite side of the map from the player's deployment zone, though custom `MissionData` settings can enforce specific configurations (e.g., an ambush scenario where enemies surround the center).

---

## 3. Auto-Deployment AI Logic

When the `Battlefield.tscn` initializes and enters the `DEPLOYMENT_PHASE`, the `CombatManager` tasks the `AIManager` with auto-deploying the enemy forces.

The deployment algorithm evaluates the valid tiles within the `enemy_deployment_zones` and assigns tiles based on the unit's **Tactical Role** (defined in their `UnitData.tres`).

### Deployment Priorities by Role

1.  **Ranged Units (e.g., Archers, Mages):**
    *   **Priority 1: High Ground.** The AI scans the deployment zone for tiles with a `z_height` greater than the base level (Z>0). Ranged units are placed here first to maximize range bonuses.
    *   **Priority 2: Cover.** If no high ground is available, they seek tiles adjacent to objects granting a `cover_bonus` (e.g., trees, rocks).
    *   **Positioning:** Generally placed in the middle or rear rows of the deployment zone.

2.  **Melee & Tank Units:**
    *   **Priority 1: Frontline.** Placed in the row of tiles closest to the player's deployment zone to intercept incoming attacks.
    *   **Priority 2: Chokepoints.** If the terrain features natural funnels (like a narrow path between rocks), melee units will prioritize blocking these gaps.
    *   **Positioning:** Placed ahead of ranged and support units.

3.  **Support/Healer Units:**
    *   **Priority 1: Safety.** Placed in the furthest rear tiles of the deployment zone.
    *   **Priority 2: Line of Sight.** Ensure they have unobstructed LOS to the melee/tank units they are meant to support.

### The Algorithm Flow

```text
┌────────────────────────────────────────────────────────┐
│ 1. Parse MissionData.tres                              │
│    - Load enemy roster array.                          │
│    - Sort units by Role (Ranged -> Melee -> Support).  │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ 2. Analyze Deployment Zone                             │
│    - Query GridManager for all valid enemy tiles.      │
│    - Score tiles based on Z-level, Cover, and Frontline│
│      proximity.                                        │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ 3. Assign & Instantiate                                │
│    - Loop through sorted roster.                       │
│    - Pop the highest-scoring valid tile for that role. │
│    - Instantiate the Unit node at that grid coordinate.│
└────────────────────────────────────────────────────────┘
```

By utilizing this basic scoring system, the enemy will naturally form cohesive, tactically sound formations based solely on the procedurally generated terrain, ensuring varied and interesting engagements for the MVP.