# Section 3: Combat Simulation Engine (The Core Gameplay)

Welcome to **Section 3: Combat Simulation Engine** of our Master Architectural Blueprint!

While Sections 1 and 2 established our screen flow and technical backbone, this section defines the **heart of your game**: the core 2D tactical auto-battler simulation.

Our core design relies on a **WEGO phase system** (simultaneous action execution), **multi-level elevation (Z-levels)**, **team-agnostic component-based units**, and **data-driven AI behavior trees**. Every component is fully decoupled and communicates through central hubs like the `SignalBus`.

---

## 1. Core Combat Engine Architecture

In this architecture, game logic is strictly separated from visual representation. Units do not decide when or how the turn progresses; instead, central manager nodes govern the rules, while units act as modular containers composed of independent, single-purpose component scripts.

```
                         ┌────────────────────────┐
                         │  SignalBus (Autoload)  │
                         └───────────┬────────────┘
                                     │
       ┌─────────────────┬───────────┴───────────┬─────────────────┐
       │                 │                       │                 │
       ▼                 ▼                       ▼                 ▼
┌──────────────┐  ┌──────────────┐       ┌──────────────┐   ┌──────────────┐
│ PhaseManager │  │ GridManager  │       │AIManager / BT│   │CombatManager │
│ (WEGO Loop)  │  │ (Z-Levels)   │       │ (Behavior)   │   │(Combat Math) │
└──────────────┘  └──────────────┘       └──────────────┘   └──────────────┘
       │                 │                       │                 │
       └─────────────────┴───────────┬───────────┴─────────────────┘
                                     │ Issues commands
                                     ▼
                        ┌────────────────────────┐
                        │ Unit Entity Container  │
                        │ ├── HealthComponent    │
                        │ ├── MovementComponent  │
                        │ ├── TargetingComponent │
                        │ └── AIComponent        │
                        └────────────────────────┘

```

---

## 2. Detailed System Specifications

### System 1: WEGO Phase Manager (`PhaseManager`)

* **File Path:** `res://Managers/PhaseManager.gd`

#### Purpose

Governs the flow of turn execution. Instead of traditional sequential "I-move, You-move" turns—which ruin cohesive tactical formations—the `PhaseManager` runs a **WEGO (Simultaneous Execution)** cycle divided into three distinct steps:

```
┌─────────────────────────────────────────────────────────┐
│ 1. PLANNING PHASE                                       │
│    - Game time is paused (Engine.time_scale = 0.0)      │
│    - AIManager builds Action Queues for all units       │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│ 2. SIMULTANEOUS EXECUTION PHASE                         │
│    - Time resumes (Engine.time_scale = 1.0)             │
│    - All units execute actions in real-time (~2 sec)    │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│ 3. RESOLUTION PHASE                                     │
│    - Damage, casualties, and morale states are applied  │
│    - Turn counter advances; returns to Planning Phase   │
└─────────────────────────────────────────────────────────┘

```

#### Key Functions & Responsibilities

* **`start_planning_phase()`:** Emits `SignalBus.wego_phase_started("planning")`. Signals the `AIManager` to calculate planned movements for every unit on the board.
* **`start_execution_phase()`:** Once all plans are locked, resumes time and notifies units to execute their queued `Command` objects simultaneously.
* **`end_turn()`:** Evaluates victory/defeat conditions and resets unit action states for the next turn.

---

### System 2: Multi-Level Grid & Elevation Manager (`GridManager`)

* **File Path:** `res://Managers/GridManager.gd`

#### Purpose

Handles the spatial calculations for a 2D battlefield featuring multi-floor structures (e.g., ground level `Z=0`, tower floor `Z=3`).

#### Key Features & Math Models

* **3D Coordinate Mapping in 2D Space:** Coordinates are stored as `Vector3i(x, y, elevation)`.
* **Elevation-Aware Line of Sight (LOS):** Calculates effective range and target visibility across Z-levels:

$$\text{Effective Distance} = \sqrt{\Delta X^2 + \Delta Y^2 + (\Delta Z \times \text{FloorHeightScale})^2}$$


* **Height Bonuses:** Units at higher $Z$ values receive automatic range extensions and hit bonuses against lower targets.
* **Z-Layer Visibility:** Manages roof/ceiling opacity (`modulate.a = 0.3`) when camera focus or units enter enclosed lower floors.

---

### System 3: Component-Based Unit Entity (`Unit.tscn`)

* **Scene Path:** `res://Entities/Unit/Unit.tscn`
* **Root Script:** `res://Entities/Unit/Unit.gd`

#### Purpose

A lightweight, team-agnostic root container node (`CharacterBody2D`). Units are never hardcoded as "PlayerKnight" or "EnemyKnight". A unit's allegiance, stats, and appearance are dynamically loaded from a `UnitData` resource at spawn.

#### Child Component Scripts (Single Responsibility)

To avoid monolithic code, unit functionality is broken into standalone child nodes:

1. **`HealthComponent.gd`:**
* Tracks current/max health and armor properties.
* Processes incoming damage and emits `SignalBus.unit_health_changed` and `SignalBus.unit_died`.


2. **`MovementComponent.gd`:**
* Handles path execution, movement speed, knockback physics, and tile transitions.


3. **`TargetingComponent.gd`:**
* Uses `RayCast2D` nodes to perform line-of-sight checks and target detection across Z-levels.


4. **`AIComponent.gd`:**
* Holds the unit's active Behavior Tree instance and converts AI decisions into executable command queues for the `PhaseManager`.



---

### System 4: AI Behavior Tree Engine (`AIManager` & BT Nodes)

* **File Path:** `res://Managers/AIManager.gd`
* **Directory:** `res://AI/`

#### Purpose

Executes auto-battler logic during the Planning Phase. Players configure unit behavior templates (e.g., *Defensive Shield Wall*, *Flank Ranged Units*, *Support Caster*) in the Barracks, which the AI engine parses into tactical decisions.

#### Behavior Node Hierarchy

```text
Selector (Fallthrough)
├── Sequence: Retreat if Morale Low
│   ├── Condition: Check Morale < 20%
│   └── Action: Queue Move to Exit Zone
│
├── Sequence: Protect Formation
│   ├── Condition: Allies nearby in Shield Wall
│   └── Action: Hold Position & Guard
│
└── Sequence: Attack Nearest Enemy
    ├── Action: Find Target in Line of Sight (via TargetingComponent)
    ├── Action: Queue Path to Range
    └── Action: Queue Attack

```

---

### System 5: Combat Physics & Math Processor (`CombatManager`)

* **File Path:** `res://Managers/CombatManager.gd`

#### Purpose

A pure logic/math service that calculates physical interaction results between units without modifying unit node states directly.

#### Key Mechanics & Combat Physics

* **Armor Types vs. Damage Types:**
* **Slashing (Swords):** High vs Unarmored; negated by Plate Armor.
* **Piercing (Arrows/Spears):** Bonus damage from higher elevation; mitigated by Shields.
* **Blunt (Maces/Hammers):** Bypasses heavy armor; applies stagger/knockback.


* **Directional Facing & Flanking:** Compares target `facing_vector` against attack vector. Attacks from the rear (+180°) bypass shield block chances entirely.
* **Physical Impact Vectors:** Applies velocity impulses to `MovementComponent` during heavy charges or blunt hits.

---

## 3. Directory & File Structure for Core Gameplay

Below is the directory layout for all core combat files in your Godot 4 project:

```text
res://
├── Managers/
│   ├── PhaseManager.gd          # WEGO turn state controller
│   ├── GridManager.gd           # Multi-level Z-grid, pathfinding & LOS
│   ├── CombatManager.gd         # Pure combat math (armor, facing, damage)
│   └── AIManager.gd             # Global AI evaluation processor
│
├── Entities/
│   └── Unit/
│       ├── Unit.tscn            # Main unit entity scene
│       ├── Unit.gd              # Root controller & allegiance holder
│       └── Components/
│           ├── HealthComponent.gd
│           ├── MovementComponent.gd
│           ├── TargetingComponent.gd
│           └── AIComponent.gd
│
├── AI/
│   ├── Framework/               # Core Behavior Tree nodes
│   │   ├── BTNode.gd
│   │   ├── BTSelector.gd
│   │   ├── BTSequence.gd
│   │   └── BTAction.gd
│   └── Presets/                 # Data-driven player-selectable AI scripts
│       ├── frontline_defender.tres
│       ├── flank_aggressor.tres
│       └── rear_support.tres
│
└── Data/
    └── Models/                  # Custom Resources
        ├── UnitData.gd
        ├── WeaponData.gd
        └── ArmorData.gd

```

---