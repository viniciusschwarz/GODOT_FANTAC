# Medieval 2D Tactical Auto-Battler (MVP)

Welcome to the Godot 4 Medieval 2D Tactical Auto-Battler project! This project is designed with a robust, modular, and heavily decoupled architecture, meant to serve as a strong foundation for an intricate strategy game.

This document serves as your central guide to understanding the project, how to play the game, and how a new developer can quickly navigate and update its systems.

---

## 1. Gameplay Overview (A Session Journey)

The game focuses on macro-level strategy, army management, and WEGO (simultaneous execution) auto-battling. Here is what a typical gameplay session looks like:

### The War Desk (Strategic Hub)
After loading a save or starting a new campaign, you enter the **War Desk**. This is the strategic layer of the game where you examine the kingdom's map, review the overall casualty meter, and select your next mission dispatch.
* **What you do:** Review enemy forces, weather forecasts, and objective rewards. Choose your battle.

### The Barracks (Preparation & AI Setup)
Before deploying, you visit the **Barracks** to inspect your battalion roster.
* **What you do:** Review stats, equip weapons/armor, and most importantly, assign **AI Behavior Trees** (e.g., *Frontline Defender*, *Flank Aggressor*) to your troops. You do not control them directly in combat, so their AI scripts are their only guide.

### Pre-Battle Deployment
Once a mission is accepted, you enter the **Deployment Phase**.
* **What you do:** Analyze the battlefield's terrain and elevation (Z-levels). Spend your deployment budget to place units onto the grid in specific formations (Wedge, Shield Wall, etc.) before the battle begins.

### Active Battle (WEGO Auto-battler)
The simulation executes in a WEGO cycle divided into distinct phases:
1. **Planning Phase (Paused):** The `AIManager` secretly calculates intended actions for every unit based on their Behavior Tree presets.
2. **Execution Phase (Real-Time):** Time resumes, and all units (both player and enemy) execute their commands simultaneously.
3. **Resolution Phase:** Damage, morale, and casualties are evaluated before the next planning cycle begins.
* **What you do:** Watch the simulation unfold, control time speed, and manage emergency tactical options if available.

### Post-Battle Report
* **What you do:** Review victory/defeat, analyze casualties, and collect rewards. Territory control is updated globally, and the game automatically saves before returning to the War Desk.

---

## 2. Structural Overview & Core Architecture

This project strictly adheres to a **modular, decoupled architecture**. UI screens, combat logic, and visual effects do not directly control one another. Instead, they communicate via central **Autoloads** (Managers) and a global **SignalBus**.

### Global Managers (Autoloads)
| Manager | Responsibility |
| --- | --- |
| **`SignalBus`** | Central event hub. All decoupled systems communicate by shouting to the bus (e.g., `unit_died`). |
| **`GameState`** | Holds campaign data, unit rosters, mission selections, and session state. |
| **`SceneManager`** | Asynchronously loads UI screens and maps to prevent memory leaks and circular dependencies. |
| **`DataManager`** | Loads and serves static data (units, weapons, rules) from consolidated JSON files and Custom Resources. |
| **`SaveManager`** | Serializes/Deserializes `GameState` to/from the local disk (`user://`). |
| **`PhaseManager`** | Controls the WEGO turn loop (Planning, Execution, Resolution) during combat. |
| **`CombatManager`** | Pure logic processor calculating combat math (armor vs. damage type, elevation bonuses). |

### Data Flow Structural View
```text
┌─────────────────┐       (Emits Event)       ┌─────────────────┐
│ System/Screen A ├──────────────────────────►│    SignalBus    │
└─────────────────┘                           └────────┬────────┘
                                                       │
                                 (Listens to Event)    │
┌─────────────────┐◄───────────────────────────────────┘
│ System/Screen B │
└─────────────────┘

Example:
[HealthComponent] --(emits: unit_damaged)--> [SignalBus] --(triggers)--> [FXManager (Spawns text)]
```

---

## 3. Developer Guidance: Navigating & Updating the Game

If you are new to this project, this guiding tutorial will show you where to look when you want to update or expand the game. The golden rule is: **Separate Logic from Presentation.**

### Modifying or Adding Game Data (Units, Items, Weapons)
The game uses a **Data-Driven Workflow**. You do not need to open GDScript files to add a new knight or sword.
* **Where to go:** `res://data/` (JSON files) and `res://scripts/resources/` (Custom Resources).
* **How it works:** The `DataManager` autoload reads files like `units.json` and caches them as `UnitData.tres` resources.
* **To update:** Simply edit the JSON arrays to balance HP, adjust weapon damage, or add a completely new entity.

### Adjusting UI and Screen Flow
UI screens never hard-load other screens (e.g., `MainMenu` doesn't load `WarDesk`).
* **Where to go:** `res://Scenes/UI/Screens/`
* **How it works:** UI components only pass state variables to the `GameState` Autoload, then ask the `SceneManager` to switch scenes.
* **To update:** To add a new screen (e.g., a "Merchant" screen), build your standard Godot `Control` node, and navigate to it via `SceneManager.goto_scene("res://Scenes/UI/Screens/MerchantScreen.tscn")`. Route any purchased items into `GameState`.

### Modifying the Combat Simulation
The core auto-battler is highly segmented. Units are merely containers for standalone logic components.
* **Where to go:**
  * WEGO Flow: `res://Managers/PhaseManager.gd`
  * Math/Physics: `res://Managers/CombatManager.gd`
  * Unit Logic: `res://Entities/Unit/Components/`
* **How it works:** During a battle, `CombatManager` handles math, `PhaseManager` handles time. A Unit's `HealthComponent` tracks HP and its `TargetingComponent` handles Line of Sight across `GridManager`'s Z-levels.
* **To update:** If you want to add a new damage type (e.g., "Fire"), you would update the logic within `CombatManager.gd` and the data schema in `rules.json`, without needing to change how units move or how the UI renders.

### Adding Polish (Audio & Visuals)
"Juice" (particles, floating text, screen shakes) is entirely decoupled from the simulation.
* **Where to go:** `res://Managers/FXManager.gd` and `res://Managers/AudioManager.gd`
* **How it works:** The `FXManager` is simply a listener. It waits for the `SignalBus` to shout that something happened (like `unit_health_changed`), and then it instantiates a visual effect at those coordinates.
* **To update:** Want to add a new blood splatter effect? Create the particle scene in `res://Assets/VisualEffects/`, then open `FXManager.gd` and have it spawn your particle whenever it hears a specific combat signal. You don't need to touch the combat logic at all.

---

## Conclusion
By keeping data separated from logic, and logic separated from visual presentation, this project provides a safe, scalable sandbox. Explore the manager autoloads, understand the event-driven `SignalBus`, and you will find it remarkably easy to grow this MVP into a massive strategy title.