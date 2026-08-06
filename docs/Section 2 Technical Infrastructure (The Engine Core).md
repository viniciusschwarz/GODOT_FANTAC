# Section 2: Technical Infrastructure (The Engine Core)

Welcome to **Section 2: Technical Infrastructure (The Engine Core)** of our Master Architectural Blueprint!

While Section 1 defined how the player moves between screens, the **Technical Infrastructure** acts as the silent backbone of your game. It handles persistent data storage, file parsing, audio routing, and system settings.

By building these systems as decoupled **Autoloads** and **Custom Resources**, we ensure that your game logic (like combat or UI) never has to deal with low-level disk operations or audio pooling directly.

---

## 1. Core Technical Infrastructure Architecture

To keep our architecture clean and modular, all technical infrastructure components operate as central services accessible across the entire project via event signals or clean API functions.

```
                             ┌────────────────────────┐
                             │  SignalBus (Autoload)  │
                             └───────────┬────────────┘
                                         │
       ┌──────────────────┬──────────────┴──────────────┬──────────────────┐
       │                  │                             │                  │
       ▼                  ▼                             ▼                  ▼
┌──────────────┐   ┌──────────────┐              ┌──────────────┐   ┌──────────────┐
│ DataManager  │   │ SaveManager  │              │ AudioManager │   │SettingsMgr   │
│ (JSON/Res)   │   │ (user://)    │              │ (Buses/Pool) │   │(ConfigFile)  │
└──────────────┘   └──────────────┘              └──────────────┘   └──────────────┘

```

---

## 2. Detailed Technical System Specifications

### System 1: Data Management System (`DataManager`)

* **File Path:** `res://scripts/autoloads/data_manager.gd`
* **Storage Location:** `res://data/` (Consolidated JSON files and `.tres` Resources)

#### Purpose

The `DataManager` is responsible for reading external data files—such as units, weapons, and rules—and storing them in memory as accessible dictionaries or custom resources. Instead of one file per item, data is grouped into consolidated JSON files (e.g., `units.json` contains all units).

#### Key Functions & Responsibilities

* **JSON Parser & Validator:** Loads raw `.json` files from `res://data/` at game launch, verifying that all required keys exist before registering them.
* **Resource Caching:** Preloads `CustomResource` templates for quick instantiation during combat (e.g., creating a unit from a `UnitData` resource).
* **Data Access API:** Exposes simple read-only queries like `DataManager.get_unit_data("knight")` or `DataManager.get_weapon_data("iron_sword")`.

#### Why This Design?

By separating game data from script logic, you can rebalance unit health, weapon damage, or weather effects simply by editing a JSON file without opening Godot or recompiling scripts. Consolidating into fewer files like `units.json` makes data management more scalable and easier to load in bulk.

---

### System 2: Save & Load System (`SaveManager`)

* **File Path:** `res://scripts/autoloads/save_manager.gd`
* **Storage Location:** `user://saves/` (e.g., `user://saves/save_slot_1.json`)

#### Purpose

Handles serializing and deserializing the state of the player's campaign—including battalion roster, territory control, story progression, and resources—to local disk storage.

#### Key Functions & Responsibilities

* **Save State Serialization:** Gathers state data from `GameState` and converts active unit stats, roster lists, and campaign variables into a structured JSON string.
* **File Writing & Encryption:** Writes data to the operating system's designated application folder (`user://`). Optionally supports checksum verification to prevent file tampering.
* **Slot Management:** Provides functions to list available save slots, query save metadata (date, play time, territory progress), and delete save files.

#### Save State Data Schema Example

```json
{
  "save_version": "1.0.0",
  "timestamp": "2026-08-05T14:30:00",
  "campaign": {
    "act": 1,
    "territory_control": 0.65,
    "total_casualties": 14
  },
  "player_roster": [
    {
      "id": "unit_001",
      "type_id": "knight",
      "name": "Sir Elden",
      "current_hp": 120,
      "max_hp": 120,
      "assigned_ai_preset": "frontline_defender",
      "equipped_weapon": "iron_sword"
    }
  ]
}

```

---

### System 3: Audio Engine & Mixer (`AudioManager`)

* **File Path:** `res://scripts/autoloads/audio_manager.gd`
* **Audio Bus Layout:** `res://assets/audio/default_bus_layout.tres`

#### Purpose

Manages all game audio, background music (BGM), environmental ambience, and combat sound effects (SFX) through an automated bus network and sound pooler.

#### Key Audio Buses

1. **Master:** Global volume control.
2. **Music (BGM):** Handles crossfading between main menu, campaign map, and active battle music.
3. **SFX:** Manages combat impacts, sword clashes, UI clicks, and unit voices.
4. **Ambient:** Environmental loops like rain, wind, or battlefield roaring.

#### Object Pooling for Sound Effects

To prevent performance hitches during intense battles with hundreds of simultaneous attacks, `AudioManager` uses a **Sound Pooler**:

* Pre-allocates a pool of 16-32 `AudioStreamPlayer2D` nodes on startup.
* When a unit attacks, it calls `AudioManager.play_sfx("sword_hit", position)`.
* The manager assigns the sound to an idle pooled player instead of instantiating a new node, returning the player to the pool when finished.

---

### System 4: Settings & Configuration System (`SettingsManager`)

* **File Path:** `res://scripts/autoloads/settings_manager.gd`
* **Storage Location:** `user://settings.cfg`

#### Purpose

Stores user preferences independently of gameplay saves using Godot's built-in `ConfigFile` class.

#### Managed Parameters

* **Display Settings:** Window Mode (Fullscreen / Windowed / Borderless), Screen Resolution, V-Sync, Max FPS Cap.
* **Audio Volumes:** Linear-to-Decibel volume mappings for `Master`, `Music`, `SFX`, and `Ambient` buses.
* **Control Bindings:** Custom key bindings saved as InputEvent strings and re-applied to Godot's `InputMap` at launch.

---

## 3. Directory & File Structure for Infrastructure

Below is the file layout dedicated to Section 2 in your Godot project, using snake_case conventions and consolidated data files:

```text
res://
├── scripts/
│   ├── autoloads/
│   │   ├── data_manager.gd         # JSON parsing and data access API
│   │   ├── save_manager.gd         # Save file serialization & user:// I/O
│   │   ├── audio_manager.gd        # Audio stream player pooling & bus control
│   │   └── settings_manager.gd     # ConfigFile parser for user preferences
│   └── resources/
│       ├── unit_data.gd            # Custom Resource for unit data
│       └── weapon_data.gd          # Custom Resource for weapon data
│
├── data/                           # Raw game data files
│   ├── units.json                  # All unit data
│   ├── weapons.json                # All weapon data
│   └── rules.json                  # Physics, weather, and other rules
│
└── assets/
    └── audio/
        ├── default_bus_layout.tres
        ├── music/
        ├── sfx/
        └── ambience/
```

---
