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