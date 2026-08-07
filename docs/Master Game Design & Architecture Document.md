This is an excellent initiative, Commander. Establishing a Master Design and Architecture Document at this stage ensures that every system, script, and feature aligns with our core pillars. This document will serve as the single source of truth for your repository.

Here is the comprehensive markdown documentation ready to be committed to your repository.

---

# Master Game Design & Architecture Document

## 1. Core Game Pillars

* **The Role:** The player acts as a battalion commander in a medieval fantasy war. Gameplay is divided into managing the war camp (Macro) and executing tactical battles (Micro).
* **The Combat (WeGo System):** Battles occur in simultaneous phases. The player issues orders and configures AI logic trees during a paused **Planning Phase**. During the **Execution Phase**, both player and enemy actions resolve simultaneously in real-time.
* **The Engine:** Built in Godot 4.x using GDScript 2.0 with strict static typing.
* **The Perspective:** 2D top-down visual presentation powered by a 3D simulation layer to support verticality (Z-levels).

---

## 2. Gameplay Mechanics

### The Macro Loop (War Camp & Management)

* **Roster Management:** Recruiting, retiring, healing, and upgrading units.
* **Logistics & Loadouts:** Equipping gear that directly unlocks conditional actions in a unit's AI tree.
* **The Tactics Board:** A visual interface where the player builds AI behavior trees for units using programmable conditions and actions (e.g., `[Condition: Ally HP < 30%] -> [Action: Heal]`).
* **Event & Mission Dispatch:** Assigning units to specific battlefield maps or background tasks.

### The Micro Loop (WeGo Combat)

1. **Planning Phase (Paused):** The player evaluates the board, sets high-level overrides, and adjusts unit AI trees based on enemy positioning.
2. **Commit Phase:** The player locks in their turn. The CPU finalizes enemy AI logic.
3. **Execution Phase (Real-Time):** The game simulates for a set duration (e.g., 5 seconds). Units execute actions based on their AI trees. Action Points (AP) dictate how much a unit can do per phase.
4. **Conflict Resolution:** Attacks and damage occur simultaneously. If two units strike each other on the exact same simulation tick, both receive damage concurrently.

### 2.5D Tactical Verticality (Z-Levels)

* **Visuals vs. Simulation:** The game uses Godot's `TileMapLayer` nodes stacked to represent different elevations. The camera slices through these layers (e.g., lowering the camera to Z=0 fades out roofs at Z=1).
* **Movement & AStar3D:** Pathfinding is calculated using Godot's `AStar3D` grid. Ground, stairs, and ramps connect nodes across different Z-coordinates. Units move along this invisible 3D grid while their 2D sprites visually interpolate the height.
* **Line of Sight (LoS):** Ranged targeting uses true `Vector3i` coordinates. A 3D Bresenham line algorithm checks for intersections with walls or higher terrain to determine if a shot is blocked.

---

## 3. Strict Architectural Directives

To maintain a scalable, AAA-grade codebase, all development must adhere strictly to the following rules:

### A. Absolute Modularity & Loose Coupling

* **No Hardcoded Paths:** Never use `get_node("../..")` to reach outside a self-contained scene.
* **Event-Driven Communication:** Use a global `EventBus.gd` Autoload for cross-domain signaling (e.g., `EventBus.unit_died.emit(unit_id)`). The UI and Audio systems listen to these events; the simulation does not call them directly.
* **Dependency Injection:** Pass required references to nodes upon initialization.
* **External Data Access:** Any script accessing external data or singletons must include explicit comments documenting the dependency.

### B. Data-Driven Design (Resources)

* All static game data (Unit Stats, AI Behaviors, Actions, Weapons, Mission Data, Map Coordinates) MUST be structured as custom Godot `Resource` scripts.
* Never hardcode configuration variables into standard Node scripts. The simulation evaluates `.tres` files injected into the entities.

### C. Modern UI Architecture (The "No Logic" Rule)

* **Backend Resolution:** The UI acts exclusively as a visual representation and input catcher. The UI will **not** resolve logical changes. For example, item swapping in an interface must fire an event to an `InventoryManager` (or backend equivalent), which executes the `on_drop` logic and updates the data.
* **Centralized Drag/Drop:** Drag-and-drop mechanics are handled entirely by the parent UI manager (e.g., `TacticsBoardUIManager`, `GuildUIManager`). Child slot scripts must **not** duplicate or execute the parent UI's drag logic.
* **Dynamic Instantiation:** Do not overcomplicate interface systems with multiple separate UI scripts for layout elements. Use a single UI Manager (e.g., a `ResearchUI`), with a main panel and a defined container, and dynamically instantiate a single reusable Prefab (e.g., `ResearchNodePrefab.tscn`) to populate the interface.

---

## 4. Master Project Structure

```text
res://
├── Assets/                   
│   ├── Audio/
│   ├── Localization/         
│   └── Sprites/
├── Autoloads/                
│   ├── EventBus.gd           # ALL global signals
│   ├── GameState.gd          # Scene transitions & flow state
│   ├── SaveManager.gd        # Serializes/Deserializes Resource data
│   ├── AudioManager.gd       # Centralized audio playback
│   └── DatabaseManager.gd    # Preloads and caches Resource libraries
├── Core/                     
│   ├── Components/           # Modular logic blocks (Dependency Injected)
│   │   ├── CombatComponent.gd
│   │   ├── ElevationComponent.gd
│   │   ├── HealthComponent.gd
│   │   ├── LOSComponent.gd
│   │   └── MovementComponent.gd
│   ├── Entities/             
│   │   ├── Projectile/       
│   │   ├── Unit/             # The combat actor (holds components)
│   │   └── MapProp/          
│   └── Systems/              
│       ├── BattlefieldManager.gd 
│       ├── GridAStar3D.gd    # 3D Pathfinding logic
│       └── TurnManager.gd    # State Machine: Planning <-> Execution
├── Data/                     
│   ├── Player/               
│   │   └── CurrentCampaign.tres  
│   ├── Resources/            # Class definitions for data objects
│   │   ├── Actions/          
│   │   ├── AI_Conditions/    
│   │   ├── MapData.gd        
│   │   ├── MissionData.gd    
│   │   ├── UnitStats.gd      
│   │   └── WeaponData.gd     
│   └── Databases/            # Instantiated .tres files
├── Scenes/                   
│   ├── Boot/
│   │   ├── Splash.tscn
│   │   └── MainMenu.tscn
│   ├── Campaign/
│   │   ├── WorldMap.tscn     
│   │   └── WarCamp.tscn      
│   └── Tactical/
│       └── Battlefield.tscn  
├── UI/                       
│   ├── Components/           
│   │   ├── FloatingTextPrefab.tscn 
│   │   ├── TooltipPrefab.tscn
│   │   └── SlotPrefab.tscn   # Reusable UI slot (NO DRAG LOGIC HERE)
│   ├── Managers/             # The ONLY places UI logic/drag-and-drop live
│   │   ├── RosterUIManager.gd
│   │   ├── TacticsBoardUIManager.gd 
│   │   └── InventoryUIManager.gd    
│   └── Menus/
│       ├── PauseMenu.tscn
│       └── SettingsMenu.tscn
└── Utils/                    
    ├── DiceRoller.gd         
    └── StateMachine/         

```

---