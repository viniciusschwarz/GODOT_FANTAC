# Game Flow & Screen Management (The User Journey)

Welcome to **Section 1: Game Flow & Screen Management** of our Master Architectural Blueprint!

This document defines the complete user journey for your 2D tactical medieval auto-battler in Godot 4. By establishing a decoupled, state-driven screen management architecture first, we ensure that every menu, map, and battle transition operates smoothly without tight dependencies or memory leaks.

---

## 1. Global Scene & Transition Architecture

In a modular Godot 4 engine, individual UI screens never instantiate or destroy other screens directly. Instead, screen navigation is driven by event notifications sent to the **`SignalBus`** and processed asynchronously by the **`SceneManager`** autoload.

```
┌─────────────────┐       Emits event       ┌──────────────┐
│  MainMenuUI     ├────────────────────────►│  SignalBus   │
└─────────────────┘                         └──────┬───────┘
                                                   │
                                            Triggers transition
                                                   ▼
┌─────────────────┐   Loads asynchronously  ┌──────────────┐
│  WarDeskScreen  │◄────────────────────────┤ SceneManager │
└─────────────────┘                         └──────────────┘

```

### Why This Architecture?

* **Zero Script Dependencies:** The `MainMenu.gd` script does not need `var war_desk = preload("res://.../WarDesk.tscn")`. This eliminates circular dependencies and reduces initial load times.
* **Non-Blocking Threaded Loading:** Heavy scenes (like the tactical battlefield) load in the background via `ResourceLoader.load_threaded_request()`, maintaining a responsive UI and smooth loading animations.
* **Centralized State Validation:** `SceneManager` checks with `GameState` before switching scenes (e.g., verifying if a save file exists before loading the War Desk).

---

## 2. Detailed Screen-by-Screen Specification

Below is the functional specification, UI breakdown, and logic responsibilities for every screen in the game journey.

```
               ┌────────────────────────┐
               │    Boot / Logo Screen   │
               └───────────┬────────────┘
                           │
                           ▼
               ┌────────────────────────┐
               │    Main Menu Screen    │
               └───────────┬────────────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
  ┌─────────────────────┐     ┌─────────────────────┐
  │  Settings Overlay   │     │  War Desk Screen    │
  └─────────────────────┘     └──────────┬──────────┘
                                         │
                         ┌───────────────┴───────────────┐
                         ▼                               ▼
              ┌─────────────────────┐         ┌─────────────────────┐
              │   Barracks / Roster │         │ Pre-Battle Deployment│
              └─────────────────────┘         └──────────┬──────────┘
                                                         │
                                                         ▼
                                              ┌─────────────────────┐
                                              │ Active Battle Screen│
                                              └──────────┬──────────┘
                                                         │
                                                         ▼
                                              ┌─────────────────────┐
                                              │ Post-Battle Report  │
                                              └─────────────────────┘

```

---

### Screen 1: Boot / Logo Screen

* **File Path:** `res://Scenes/UI/Screens/BootScreen.tscn`
* **Script:** `BootScreen.gd`

#### Purpose

Initializes essential global systems, verifies directory paths in `user://`, applies saved player configurations (resolution, audio levels), and seamlessly transitions to the Main Menu.

#### Key Features & UI Components

* Full-screen background color with fading Studio / Game Title logo (`TextureRect` + `AnimationPlayer`).
* Hidden initialization triggers running in `_ready()`.

#### Step-by-Step Execution Flow

1. Load user settings from disk (`user://settings.cfg`) via `SettingsManager`.
2. Apply window mode, resolution, and Audio Bus volumes.
3. Emit `SignalBus.boot_completed`.
4. Trigger `SceneManager.goto_scene("res://Scenes/UI/Screens/MainMenuScreen.tscn")`.

---

### Screen 2: Main Menu Screen

* **File Path:** `res://Scenes/UI/Screens/MainMenuScreen.tscn`
* **Script:** `MainMenuScreen.gd`

#### Purpose

Acts as the primary entry point for the player to begin a new campaign, continue an existing save, adjust options, or exit the application.

#### Key Features & UI Components

* **Title Banner:** Medieval kingdom typography/logo.
* **Action Buttons (`VBoxContainer`):**
* `New Campaign Button`: Clears current `GameState`, initializes default battalion data, transitions to War Desk.
* `Continue Button`: Enabled only if a valid save file exists in `user://saves/`. Loads save data into `GameState` and transitions to War Desk.
* `Settings Button`: Instantiates the Settings Overlay modally.
* `Quit Button`: Safely closes the desktop application.



---

### Screen 3: Settings & Options Screen

* **File Path:** `res://Scenes/UI/Screens/SettingsScreen.tscn`
* **Script:** `SettingsScreen.gd`

#### Purpose

A modal overlay screen accessible from both the Main Menu and the Battle Pause Menu, allowing real-time adjustment of technical parameters.

#### Key Features & UI Components

* **Tabbed Navigation (`TabContainer`):**
* **Video Tab:** Window Mode (`OptionButton`: Windowed, Fullscreen, Borderless), Resolution selector, V-Sync toggle (`CheckBox`), FPS Cap slider (`HSlider`).
* **Audio Tab:** Volume sliders (`HSlider`) mapped to Godot Audio Buses: `Master`, `BGM`, `SFX`, `Ambient`.
* **Controls Tab:** Key binding remapping list for camera controls (W, A, S, D, Scroll Wheel).


* **Footer Controls:** "Apply", "Reset Defaults", and "Back/Close" buttons.

---

### Screen 4: War Desk / Campaign Screen (The Tactical Hub)

* **File Path:** `res://Scenes/UI/Screens/WarDeskScreen.tscn`
* **Script:** `WarDeskScreen.gd`

#### Purpose

Serves as the main strategic hub between battles. Designed as a medieval commander's tactical desk featuring dispatch letters, military reports, and a map of the kingdom's front lines.

#### Key Features & UI Components

* **Strategic Map Texture:** Displays contested territories and active war front nodes.
* **Dispatch Letter Panel (`PanelContainer`):** Shows selected mission assignment details (enemy forces, weather/terrain forecasts, objective, rewards).
* **War Status Header:** Displays total kingdom casualty meter, remaining battalion strength, and current campaign act/phase.
* **Navigation Bar:**
* `Open Barracks`: Transitions to the Roster & AI Customization Screen.
* `Accept Assignment`: Sets selected mission in `GameState` and transitions to Pre-Battle Deployment.
* `Save & Exit`: Triggers `SaveManager.save_game()` and returns to Main Menu.



#### Auto-Save Behavior

When entering or leaving the War Desk, `SaveManager.save_game()` is automatically executed. Mid-battle saving is disabled to guarantee state integrity during simulation.

---

### Screen 5: Barracks & Roster Management Screen

* **File Path:** `res://Scenes/UI/Screens/BarracksScreen.tscn`
* **Script:** `BarracksScreen.gd`

#### Purpose

Allows players to review their entire battalion, inspect individual unit attributes, manage equipment, and assign AI Behavior Tree parameters.

#### Key Features & UI Components

* **Troop List Panel (`ScrollContainer` + `VBoxContainer`):** Lists all active soldiers in the battalion. Uses a single dynamic prefab (`UnitRosterSlot.tscn`) instantiated for each unit.
* **Unit Inspection Panel:**
* Displays 2D character preview, base stats (HP, Armor Type, Speed, Elevation Range).
* Equipment slots (Weapon, Shield/Accessory).


* **Tactical AI Scripting Panel:** Dropdown selection for unit behavior presets (e.g., *Frontline Defender*, *Flank Aggressor*, *Rear Support*).
* **Return Button:** Saves roster modifications to `GameState` and returns to the War Desk.

---

### Screen 6: Pre-Battle Deployment Screen

* **File Path:** `res://Scenes/UI/Screens/DeploymentScreen.tscn`
* **Script:** `DeploymentScreen.gd`

#### Purpose

The tactical phase immediately preceding combat where players analyze the terrain and place their available troops into designated deployment zones.

#### Key Features & UI Components

* **Tactical Grid View:** Displays the battle map with highlighted green tiles (Player Zone) and red tiles (Enemy Zone).
* **Deployment Dock (`HBoxContainer`):** Displays available unit cards from the battalion roster.
* **Deployment Budget Meter:** Shows spent vs. available deployment points for the mission.
* **Formation Presets:** Quick buttons to arrange deployed troops into standard military lines (Wedge, Shield Wall, Skirmish Line).
* **"Commence Battle" Button:** Locks unit positions, serializes deployment layout into `GameState`, and transitions to the Active Battle Screen.

---

### Screen 7: Active Battle Screen

* **File Path:** `res://Scenes/UI/Screens/BattleScreen.tscn`
* **Script:** `BattleScreen.gd`

#### Purpose

Hosts the core 2D WEGO auto-battler simulation. Displays tactical HUD controls, turn phase indicators, and unit status overlays.

#### Key Features & UI Components

* **Phase Bar Overlay:** Displays current WEGO state (*Planning Phase* vs. *Real-Time Execution Phase*).
* **Simulation Speed Bar:** Controls game time scale (`Engine.time_scale` = `0.0` [Pause], `1.0x`, `2.0x`, `4.0x`).
* **Tactical Camera Controls:** Zoom and pan overlays.
* **Unit Health & Morale Indicators:** Floating 2D world-space UI nodes anchored above active units.
* **Pause Menu Overlay:** Triggered via `ESC`, offering Options, Restart Assignment, or Surrender.

---

### Screen 8: Post-Battle Report Screen

* **File Path:** `res://Scenes/UI/Screens/PostBattleScreen.tscn`
* **Script:** `PostBattleScreen.gd`

#### Purpose

Presents the outcome of the battle, details casualties and rewards, and updates the overarching campaign state.

#### Key Features & UI Components

* **Victory / Defeat Header:** Dynamic title reflecting battle results.
* **Casualty & Loss Summary:** Detailed breakdown of surviving, wounded, or permanently lost units.
* **Territory & Campaign Impact:** Updates the global kingdom casualty meter and front-line territory control.
* **Loot & Rewards Section:** Displays gained equipment or army supplies.
* **"Return to War Desk" Button:**
* **Standard Branch:** Applies casualty/reward modifications to `GameState` and returns to the War Desk. The narrative continues even if the battle was lost.
* **Critical Failure Branch:** If total kingdom casualties or territory losses exceed the maximum threshold, presents a final "Campaign Failed" screen with an option to restart the campaign.



---

## 3. State Persistence & Data Flow Across Screens

To keep UI components completely decoupled, screens never pass variables directly to each other. All cross-screen data flows through the centralized **`GameState`** autoload.

```
                  ┌────────────────────────┐
                  │    GameState (Autoload)│
                  └───────────┬────────────┘
                              │
     ┌────────────────────────┼────────────────────────┐
     │ Reads/Writes           │ Reads                  │ Reads/Writes
     ▼                        ▼                        ▼
┌──────────────┐      ┌──────────────┐      ┌────────────────────┐
│ WarDeskUI    │      │ DeploymentUI │      │ PostBattleReport   │
└──────────────┘      └──────────────┘      └────────────────────┘

```

### Data Flow Sequence Example

1. **War Desk Screen:** Player selects a mission dispatch.
* `WarDeskScreen.gd` sets `GameState.current_mission = selected_mission_resource`.
* Calls `SceneManager.goto_scene("DeploymentScreen.tscn")`.


2. **Deployment Screen:** Reads mission requirements.
* `DeploymentScreen.gd` queries `GameState.current_mission` for terrain/budget data.
* Player places units. Placed unit configurations are written to `GameState.active_deployment_list`.
* Calls `SceneManager.goto_scene("BattleScreen.tscn")`.


3. **Active Battle Screen:** Executes simulation.
* `BattleManager.gd` spawns units defined in `GameState.active_deployment_list`.
* On battle conclusion, battle results (casualties, survivors) are written to `GameState.last_battle_results`.
* Calls `SceneManager.goto_scene("PostBattleScreen.tscn")`.


4. **Post-Battle Report Screen:** Updates overall campaign status.
* `PostBattleScreen.gd` processes `GameState.last_battle_results`, removing fallen units from `GameState.player_roster`.
* Triggers `SaveManager.save_game()` upon returning to the War Desk.



---

## 4. Complete Directory & File Structure

Below is the directory structure for all files associated with **Game Flow & Screen Management** in your Godot 4 project:

```text
res://
├── Autoloads/
│   ├── SignalBus.gd              # Central event hub
│   ├── GameState.gd              # Central campaign & session data store
│   ├── SceneManager.gd           # Asynchronous scene transition controller
│   └── SettingsManager.gd        # Options serializer & engine setting applicator
│
├── Scenes/
│   └── UI/
│       ├── Components/           # Reusable UI prefabs
│       │   ├── LoadingScreen.tscn
│       │   ├── LoadingScreen.gd
│       │   ├── UnitRosterSlot.tscn
│       │   └── UnitRosterSlot.gd
│       │
│       ├── Overlays/             # Modal dialogs overlaying other screens
│       │   ├── SettingsScreen.tscn
│       │   ├── SettingsScreen.gd
│       │   ├── PauseMenu.tscn
│       │   └── PauseMenu.gd
│       │
│       └── Screens/              # Primary full-screen nodes
│           ├── BootScreen.tscn
│           ├── BootScreen.gd
│           ├── MainMenuScreen.tscn
│           ├── MainMenuScreen.gd
│           ├── WarDeskScreen.tscn
│           ├── WarDeskScreen.gd
│           ├── BarracksScreen.tscn
│           ├── BarracksScreen.gd
│           ├── DeploymentScreen.tscn
│           ├── DeploymentScreen.gd
│           ├── BattleScreen.tscn
│           ├── BattleScreen.gd
│           ├── PostBattleScreen.tscn
│           └── PostBattleScreen.gd
│
└── Assets/
    └── UI/                       # UI textures, icons, fonts, and themes
        ├── Themes/
        │   └── MedievalTheme.theme
        ├── Fonts/
        └── Icons/

```

---