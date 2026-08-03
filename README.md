
# ⚔️ Tactical 2D Auto-Battler MVP - Project Documentation

## 📖 Project Overview

This project is a minimum viable product (MVP) for a 2D tactical medieval fantasy auto-battler.
The core gameplay loop involves the player setting up units (Knights, Archers, Mages) on a grid-based board, assigning them specific AI behaviors ("Focus"), and watching them execute the battle automatically in a turn-based format.

## 🏗️ Architectural Philosophy

To ensure the project is scalable and beginner-friendly, it uses a **Decoupled Modular Architecture**.

* **No Spaghetti Code:** Modules (like the Board and the Units) do not directly speak to or depend on each other.


* **The Central Hub:** All data and communication flow through a central Autoload Singleton (`GameHub`).


* **Event Bus (Signals):** Actions are broadcasted to the game using Godot's Signal system, allowing any script to react without creating hard dependencies.


* **Data-Driven Design:** Unit stats and costs are stored externally in a JSON database, allowing for rapid balancing and scaling without editing GDScript code.

## 📂 Current Modules & Script Summaries

### 1. The Brain: `GameHub.gd` (Autoload / Singleton)

* **Purpose:** The central memory and event router of the game.


* **Key Responsibilities:** Holds Game State, maintains active units/grid positions, handles win detection, and routes all Signals.



### 2. The Map: `Board.gd` (Attached to `Board.tscn`)

* **Purpose:** Handles the mathematical grid and physical terrain.


* **Key Responsibilities:** Translates grid coordinates to pixels, draws the visual grid, and maintains terrain data (Grass, Mountain).



### 3. The Actor: `UnitBase.gd` (Attached to `UnitBase.tscn`)

* **Purpose:** The blueprint for every character on the board.


* **Key Responsibilities:** Reads its injected dictionary stats, executes AI logic (melee or ranged), manages its custom health bar, and handles click detection.



### 4. The Clock: `TurnManager.gd` (Attached to `TurnManager.tscn`)

* **Purpose:** Controls the flow of time and unit turns.



### 5. The Director: `Main.gd` (Attached to `Main.tscn`)

* **Purpose:** The main game table.


* **Key Responsibilities:** Dynamically generates the UI based on the JSON database, handles the Placement Point System, spawns units, and manages Tween animations.



### 6. The Visual Feedback: `FloatingText.gd` (Attached to `FloatingText.tscn`)

* **Purpose:** A self-deleting animated node that pops up to show damage numbers when a unit is hit.



### 7. The Navigator: `Pathfinder.gd` (Autoload / Singleton)

* **Purpose:** Handles all routing and obstacle avoidance.
* **Key Responsibilities:** Uses Godot's `AStarGrid2D` to calculate the shortest path around mountains and other units.

### 8. The Feeder: `UnitDatabase.gd` & `units_database.json` (Autoload / Singleton)

* **Purpose:** The central repository for all unit statistics.
* **Key Responsibilities:** Parses the JSON file at runtime and provides data dictionaries (HP, Attack, Range, Cost) to the Director for UI generation and Unit spawning.

## 🚀 Current Project Status

**Phase: Core Prototyping**

* [x] Establish Data Hub and Event Bus Architecture


* [x] Create Grid-to-Pixel math mapping (Board)


* [x] Implement Turn Manager logic (Rounds and Turns)


* [x] Implement basic AI (Find closest enemy, move, attack)


* [x] Add visual representation via sprite scaling and Tween animations


* [x] Visual Feedback (Custom Health Bars & Floating Damage Numbers)


* [x] Game Over Detection and Restart Logic


* [x] Terrain Obstacles and A* Pathfinding


* [x] Data-Driven Architecture (JSON Database integration)
* [x] Dynamic Placement UI and Point-based Spawning System
* [x] Advanced Combat: Ranged Attacks (Archer)



---

## 🔮 Future Next Steps (New Roadmap Plan)

Now that our core systems are highly robust and modular, we can focus on game feel and expanding mechanics. Here is a proposed plan for our next iterations:

**Phase 1: Projectiles and Visual Polish**
Currently, Archers deal damage instantly from across the board. We should create a `Projectile.tscn` module that spawns an arrow, animates it flying to the target, and only applies damage when the animation finishes.

**Phase 2: Complex Terrain Costs**
We have mountains that block movement, but we can expand the `Pathfinder` to understand terrain *weights*. For example, adding "Water" tiles that do not block movement, but cost 2 steps to walk through instead of 1.

**Phase 3: Area of Effect (AoE) Combat & Mages**
Expand the JSON database with an `attack_type` key. Implement a Mage unit that, instead of dealing single-target damage, asks the `GameHub` for all units within a 1-tile radius of the target and damages all of them simultaneously.

**Phase 4: Expanded AI Behaviors**
Flesh out the "Defend Position" (Unit holds ground and only attacks if an enemy enters their range) and "Hunt Weakest" (Unit asks `GameHub` for the enemy with the lowest HP instead of the closest) options we added to our dropdown menu.
