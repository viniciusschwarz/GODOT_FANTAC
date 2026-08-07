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
## Phase 2: Pre-Battle Setup
**Flow Step:** Map Generation -> Player Deployment -> AI Behavior Setup

**Current Status:** Playable

**Architectural Fixes:**
- **Map Generation:** Created a dedicated `MapGenerator` autoload (`scripts/managers/map_generator.gd`) to handle all procedural map generation and deployment zone logic, removing these responsibilities from `EnvironmentManager`.
- **Player Deployment:** Removed `deployment_screen.tscn`/`gd`. Created `PlayerDeploymentManager` autoload (`scripts/managers/player_deployment_manager.gd`) to handle player deployment logic. The UI (`DeploymentUI`) now strictly emits signals (`player_deployment_requested`, `player_deployment_confirmed`).
- **AI Behavior Setup:** Removed setup logic from `barracks_screen.gd`. Created `PlayerBehaviorSetupManager` autoload (`scripts/managers/player_behavior_setup_manager.gd`) to handle the assignment of unit behaviors without tight coupling.
- **Phase Flow:** Updated `PhaseManager` to include a new `BEHAVIOR_SETUP` phase. The flow is now: Map Generation (`battlefield.gd` -> `MapGenerator`) -> Deployment Phase -> Behavior Setup Phase -> Planning Phase.
- **Scene Transition:** Updated `GameState` to transition directly to `battle_screen.tscn` when a mission is accepted.

**Required Signals/Variables:**
- **Signals:**
  - `SignalBus.player_deployment_requested(unit_type: String, grid_pos: Vector2i)`
  - `SignalBus.player_deployment_confirmed`
  - `SignalBus.player_behavior_setup_requested(unit: Node, preset: String)`
  - `SignalBus.player_behavior_setup_completed`
- **Variables Passed:** `unit_type` and `grid_pos` for deployment. `unit` and `preset` for behavior setup.
