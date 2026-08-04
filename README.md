# ⚔️ Tactical 2D Auto-Battler MVP - Project Documentation

## 📖 Project Overview

This project is a fully realized minimum viable product (MVP) for a 2D tactical medieval fantasy auto-battler.
The core gameplay loop involves the player setting up units (Knights, Archers, Goblins, Mages) on a grid-based board, assigning them specific AI behaviors, and watching them execute the battle automatically in a turn-based format.

## 🏗️ Architectural Philosophy

To ensure the project is scalable and beginner-friendly, it uses a **Decoupled Modular Architecture**.

* **No Spaghetti Code:** Modules (like the Board and Units) do not directly speak to or depend on each other.
* **The Central Hub:** All data and communication flow through a central Autoload Singleton (`GameHub`).
* **Event Bus (Signals):** Actions are broadcasted to the game using Godot's Signal system, allowing any script to react without creating hard dependencies.
* **Data-Driven Design:** Unit stats, terrain properties, and AI behaviors are stored externally in JSON databases, allowing for rapid balancing without editing GDScript code.

## ✨ Core Features & Mechanics

* **Dynamic Placement System:** Spend points to spawn units on valid grid cells during the Setup Phase.
* **Data-Driven Entities:** Distinct unit types (Knight, Goblin, Archer, Mage) with configurable stats (HP, attack power, movement range) driven by JSON.
* **Diverse Combat Styles:** 
  * **Melee:** Up-close engagement.
  * **Ranged:** Archers fire traveling projectiles from afar.
  * **Area of Effect (AoE):** Mages cast spells that visually expand and damage all enemies within a radius.
* **Advanced AI Behaviors:** Units can be configured with specific tactical focuses:
  * *Attack Nearest:* Default aggressive behavior.
  * *Defend Position:* Unit holds ground and only attacks enemies that enter its range.
  * *Hunt Weakest:* Unit seeks out the enemy with the lowest HP across the board.
* **Complex Terrain & Pathfinding:** Procedurally generated maps featuring Grass (normal), Water (high movement cost), and Mountains (impassable). Units dynamically navigate obstacles using A* pathfinding.
* **Visual Polish:** Tween-based animations for unit bumps/movement, traveling projectiles, scaling AoE effects, and floating damage numbers.

## 📂 Modules & Script Summaries

### 1. The Brain: `GameHub.gd` (Autoload)
* **Purpose:** The central memory and event router.
* **Key Responsibilities:** Holds Game State, maintains active units and grid positions, handles win detection, provides AI helper queries (like finding the weakest enemy or units in a radius), and routes all Signals.

### 2. The Director: `Main.gd` (Attached to `Main.tscn`)
* **Purpose:** The main game loop controller and UI manager.
* **Key Responsibilities:** Dynamically generates the UI based on JSON data, handles the Placement Point System, spawns units, and manages Tween animations for path-based unit movement.

### 3. The Map: `Board.gd` & `MapGenerator.gd`
* **Purpose:** Handles the mathematical grid, physical terrain, and procedural generation.
* **Key Responsibilities:** Generates a randomized terrain layout (Grass, Water, Mountain), translates grid coordinates to pixels, and draws the visual grid.

### 4. The Actor: `UnitBase.gd` (Attached to `UnitBase.tscn`)
* **Purpose:** The blueprint for every character on the board.
* **Key Responsibilities:** Reads its injected dictionary stats, executes assigned AI behaviors, calculates distances, and performs combat logic (spawning projectiles for ranged/AoE or attacking instantly for melee).

### 5. Pathfinding & Navigation: `Pathfinder.gd` (Autoload)
* **Purpose:** Handles all routing and obstacle avoidance.
* **Key Responsibilities:** Uses Godot's `AStarGrid2D` to calculate the shortest paths, factoring in complex terrain weights (e.g., Water costing 2 movement points) and unit blockages.

### 6. The Clock: `TurnManager.gd` (Attached to `TurnManager.tscn`)
* **Purpose:** Controls the flow of time, sequencing rounds and individual unit turns.

### 7. Combat Visuals: `Projectile.gd` & `FloatingText.gd`
* **Purpose:** Visual feedback systems for combat impacts.
* **Key Responsibilities:** `Projectile.gd` manages the animated flight of ranged arrows and the scaling of AoE spells using Tweens. `FloatingText.gd` displays self-deleting pop-up damage numbers when units are hit.

### 8. Data Repositories: `UnitDatabase.gd`, `TerrainDatabase.gd`, `AIDatabase.gd` (Autoloads)
* **Purpose:** Central repositories for all game balance statistics.
* **Key Responsibilities:** Parse JSON files at runtime to provide data dictionaries for unit stats, terrain movement costs/colors, and AI behavior stat modifiers.
