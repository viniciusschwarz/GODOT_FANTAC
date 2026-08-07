# Gameplay Flow Validation

This document tracks the validation and refactoring of the end-to-end gameplay loop to ensure the game is fully playable without tight coupling.

## Phase 1: The Out-of-Battle Loop
**Flow Step:** Boot -> Start Screen -> Campaign Screen -> Mission Selection -> Return to Campaign

**Current Status:** Playable

**Architectural Fixes:**
- Added new flow signals to `SignalBus`: `change_scene_requested`, `new_campaign_requested`, `continue_campaign_requested`, `mission_accepted`.
- Refactored `SceneManager` to listen to `change_scene_requested` and map scene IDs (e.g., "main_menu", "war_desk") to actual file paths, removing hardcoded paths from UI scripts.
- Refactored `GameState` to handle campaign data serialization/deserialization. It now listens to flow signals (`new_campaign_requested`, `continue_campaign_requested`, `mission_accepted`) to modify state and trigger scene transitions via `change_scene_requested`.
- Refactored `BootScreen`, `MainMenuScreen`, `WarDeskScreen`, and `PostBattleScreen` to emit signals instead of calling `SceneManager` directly.
- Replaced hardcoded mission list items in `WarDeskScreen` with a new `mission_list_item` dynamic prefab container (`scenes/ui/components/mission_list_item.tscn`), enforcing scalable logic.

**Required Signals/Variables:**
- **Signals:**
  - `SignalBus.change_scene_requested(scene_id: String)`
  - `SignalBus.new_campaign_requested`
  - `SignalBus.continue_campaign_requested`
  - `SignalBus.mission_accepted(mission: MissionData)`
- **Variables Passed:** `MissionData` is passed through the `mission_accepted` signal. State transitions interact with `GameState.current_mission` and `GameState.player_roster`.
## Phase 3: The Combat Loop
**Flow Step:** Enemy Deployment -> Battle Start -> Auto-Battler Execution -> End/Results Screen -> Return to Campaign

**Current Status:** Playable

**Architectural Fixes:**
- Consolidated the `DeploymentScreen` and `BattleScreen` concepts directly into `battlefield.tscn`, managed by `PhaseManager` to prevent loading disjointed map views. `deployment_ui.tscn` overlay acts as the player deployment interface and correctly hides itself via signals rather than scene changes.
- Adjusted `AIManager` and `DeploymentUI` to emit new deployment pipeline signals (`player_deployment_finished`, `enemy_deployment_finished`, `all_units_planned`) that cleanly separate the phases.
- Overhauled `PhaseManager` loop transitions to properly stop time, wait for units to deploy, pause for AI planning (`start_planning_phase`), trigger the `execution` phase, wait for all units, and transition back smoothly.
- Implemented Win/Loss checks inside `CombatManager` that listens to `unit_died` and checks remaining active AI units per team before emitting `combat_ended`.
- Decoupled End Results by showing an AcceptDialog modal in `battlefield.gd` that requests transition to the revised `post_battle_screen`, which correctly purges state and sends the user back to the war desk.

**Required Signals/Variables:**
- **Signals:**
  - `SignalBus.player_deployment_finished`
  - `SignalBus.enemy_deployment_finished`
  - `SignalBus.all_units_planned`
  - `SignalBus.combat_ended(result: String)`
- **Variables Passed:** `CombatManager` calculates unit counts via team ID and forwards `"victory"`, `"defeat"`, or `"draw"` as the outcome. `GameState` retains this result to initialize UI text inside the Post Battle scene.
