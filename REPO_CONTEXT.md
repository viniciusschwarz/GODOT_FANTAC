# 1. HIGH-LEVEL ARCHITECTURE

## The WeGo Core Loop
The game relies on a strict turn-based WeGo core loop divided into distinct operational phases:
1. **Planning Phase:** The user interface accepts inputs, assigning behaviors, directives, and waypoints to units.
2. **Headless Simulation Execution Phase:** A localized, headless simulation server computes the outcomes of the planned actions strictly via mathematical evaluation without visual or physics node overhead.
3. **Visual Playback Phase:** The pre-calculated outcome (a timeline of micro-ticks) is fed back to the view layer for visual rendering, playback, and player review.

## Strict Separation of Concerns
The architectural structure is completely decoupled across domains:
- **The Model (Simulation):** Calculates mathematically. It computes rules, interactions, spatial data, and final states without ever touching a Node2D, Node3D, or UI element.
- **The View (Rendering):** Renders states from a pre-calculated buffer. It does not calculate collisions, distances, or AI logic; it purely reflects the state provided to it.
- **The Controller / UI:** Solely catches inputs, packages them into data payloads, and emits them. It contains zero game logic or state calculation.

# 2. DIRECTORY STRUCTURE

The repository is rigidly structured to enforce domain separation. The file tree below highlights the key directories that house our decoupled logic and data:

```text
res://
├── data/
│   ├── ai_templates/
│   ├── props/
│   └── units/
├── scenes/
│   ├── props/
│   ├── ui/
│   └── view/
└── scripts/
    ├── core/        # Phase managers and root scenario loaders
    ├── resources/   # Pure data structures (Custom Resources)
    ├── sim/         # Headless combat, movement, and pathfinding math
    └── ui/          # View-agnostic UI input handlers and payload dispatchers
```

# 3. DATA LAYER (RESOURCES)

## Core Custom Resources
Data definition and runtime states are handled strictly through Godot Custom Resources. Key resources include:
- `UnitDataResource`
- `TileSpatialNodeResource`
- `TurnReplayBufferResource`
- `UIDirectivePayload`

## Strict Data Rule
**Data is NEVER hardcoded within Node scripts.** All persistent values, unit stats, behaviors, and environmental definitions must stem from externalized Custom Resources (`.tres` files) initialized and duplicated via `scenario_loader`. The Node scripts are merely operators acting upon these pure data containers.

# 4. GLOBAL SYSTEMS & EVENT BUS

## The EventBus Autoload
The project relies on a single, lightweight global signal broker: the `EventBus`.

## Cross-Domain Communication
Nodes communicate across architectural domains **ONLY** via the `EventBus`.
Direct node-pathing logic (e.g., `get_node("../..")` or direct parent-child signal hooking between vastly different domains) is strictly forbidden. The UI emits payloads to the EventBus; the Core Managers listen to the EventBus; the View listens to the EventBus for timeline scrubber updates.

# 5. UI ARCHITECTURE RULES (CRITICAL)

To prevent the generation of coupled, fragile, or over-engineered code, the following strict UI rules MUST be adhered to:

## "Dumb" UI Components
User Interface elements (buttons, labels, panels, slots) contain **NO game logic**. They strictly capture user input and trigger visual updates.

## Managers Handle Logic
Any logical state resolution (e.g., an item swap, validation, or stat calculation) must be handled exclusively by the parent UI Manager (e.g., an InventoryManager resolving an on-drop event), never by the UI interface elements or individual child slots themselves.

## Centralized Drag-and-Drop
Drag logic is handled entirely by the parent UI layer (e.g., Trader UI or Guild Manager). It must not be duplicated or nested inside individual item slot scripts.

## Absolute Modularity via Dynamic Instantiation
Do not overcomplicate the interface system with multiple separate UI scripts or nested scene dependencies. Use a **single manager UI** (e.g., `ResearchUI`) containing a panel and a container, and use a **single reusable prefab** (e.g., `researchNodePrefab`) to dynamically instantiate elements as needed.

# 6. SIMULATION & MOVEMENT

## Headless Execution
During the micro-tick evaluation of the turn simulation, spatial calculation occurs strictly via math. The `BattlefieldMatrix` utilizes **discrete `Vector3i` grid coordinates** (representing X, Y, and Z/height).

## No Visual Dependencies
The simulation strictly forbids the use of `Node2D`, `Node3D`, Godot Physics bodies, or visual raycasts to compute movement, line-of-sight, or combat outcomes. It resolves everything headlessly in memory, resulting in deterministic logic that allows instantaneous simulation resolution before the View layer renders anything.