# Section 8: Campaign Map & Missions

Welcome to **Section 8: Campaign Map & Missions**.

This section outlines the meta-game loop that exists outside of the combat simulation. For the MVP, the "Campaign Map" serves as a straightforward interface where the player selects their next battle, transitioning the game state from the campaign UI, into the map generation/deployment phase, and back again upon combat resolution.

---

## 1. The Campaign Flow

The core game loop relies on the `GameState` Autoload to track the player's progress and transition between scenes via the `SceneManager`.

### Flow Chart

```text
┌─────────────────────────┐
│     Campaign Screen     │
│  (Mission Select UI)    │
└────────────┬────────────┘
             │ (Player selects a MissionData.tres)
             ▼
┌─────────────────────────┐
│  Battle Initialization  │
│  - EnvironmentManager   │
│    generates map.       │
│  - Enemy logic parses   │
│    the selected mission.│
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│    DEPLOYMENT_PHASE     │ (Handled by PhaseManager)
│  - Player places units. │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Combat Simulation Loop │ (Planning & Execution Phases)
└────────────┬────────────┘
             │ (Victory or Defeat Triggered)
             ▼
┌─────────────────────────┐
│  Post-Battle Screen     │
│  - Rewards/Losses calculated.
└────────────┬────────────┘
             │
             ▼
      (Return to Top)
```

---

## 2. Mission Data Structure (`MissionData.tres`)

To keep the game data-driven, we do not hardcode missions. Instead, every mission is defined by a custom Godot Resource extending a new script `mission_data.gd`.

These `.tres` files are stored in `res://resources/rules/missions/` and are automatically loaded by the `DataManager` upon startup.

### `MissionData` Resource Properties

| Property Name | Type | Description |
| :--- | :--- | :--- |
| `mission_id` | String | A unique identifier (e.g., "mission_01_tutorial"). |
| `mission_name` | String | Display name in the UI (e.g., "Defend the Crossroads"). |
| `description` | String | Lore or tactical briefing shown in the selection UI. |
| `difficulty_rating` | Integer | A numerical representation of the challenge (1-10). |
| `map_size` | Vector2i | The dimensions of the procedurally generated grid (e.g., 64x64). |
| `biome_preset` | Resource | Link to a specific environment generator ruleset (e.g., `ForestBiome.tres`). |
| `enemy_roster` | Array[Dictionary] | Defines exactly which enemies appear and in what quantities (see Section 9). |
| `win_condition` | String/Enum | Defaults to "Rout_Enemy" for MVP. |

---

## 3. Campaign Interface (MVP)

For the MVP, the campaign interface avoids complex branching maps (like nodes or world-maps) in favor of a clean, functional UI list.

### `CampaignScreen.tscn` Overview

The scene is constructed using standard Godot `Control` nodes, integrated into the UI Manager system (detailed in Section 10).

1.  **Mission List Panel:** A `ScrollContainer` populated with `Button` nodes. The `DataManager` populates this list dynamically by iterating through all loaded `MissionData` resources.
2.  **Mission Details Panel:** When a mission button is clicked, this panel updates to show:
    *   Mission Name & Description
    *   Difficulty Rating
    *   Map Environment Type
    *   Enemy Composition (e.g., "Contains: 3x Goblin Melee, 2x Goblin Archer").
3.  **Deploy / Start Button:** Confirms the selection. Clicking this invokes the `SceneManager` to transition to the `Battlefield.tscn`, passing the chosen `MissionData` resource as an argument to set up the generation and enemy deployment.