# ⚔️ Tactical 2D Auto-Battler MVP - Project Documentation

## 📖 Project Overview

This project is a minimum viable product (MVP) for a 2D tactical medieval fantasy auto-battler.
The core gameplay loop involves the player setting up units (Knights, Archers, Mages) on a grid-based board, assigning them specific AI behaviors ("Focus"), and watching them execute the battle automatically in a turn-based format.

## 🏗️ Architectural Philosophy

To ensure the project is scalable and beginner-friendly, it uses a Decoupled Modular Architecture.

No Spaghettti Code: Modules (like the Board and the Units) do not directly speak to or depend on each other.

The Central Hub: All data and communication flow through a central Autoload Singleton (GameHub).

Event Bus (Signals): Actions are broadcasted to the game using Godot's Signal system, allowing any script to react without creating hard dependencies.

## 📂 Current Modules & Script Summaries

This section serves as a quick reference for what each script does.

1. The Brain: GameHub.gd (Autoload / Singleton)
Purpose: The central memory and event router of the game.

Key Responsibilities:

Holds the Game State (SETUP, BATTLE, RESOLUTION).

Maintains dictionaries of all active units and their grid positions.

Holds all the custom Signals (turn_started, unit_moved, unit_died, etc.).

Provides mathematical helper functions, like get_closest_enemy(), so units don't have to search the board themselves.

2. The Map: Board.gd (Attached to Board.tscn)
Purpose: Handles the mathematical grid and physical terrain.

Key Responsibilities:

Translates logical grid coordinates (e.g., X:2, Y:4) into exact screen pixel coordinates (e.g., X:128, Y:256) for drawing sprites.

Maintains a dictionary of terrain types (Grass, Mountain, Water) for future movement cost calculations.

Note: Does not know what a "Unit" is. Purely mathematical.

3. The Actor: UnitBase.gd (Attached to UnitBase.tscn)
Purpose: The blueprint for every character on the board.

Key Responsibilities:

Stores stats (HP, Attack, Team, Movement Range) and the assigned AI behavior (current_focus).

Listens to the GameHub for its turn.

Executes AI logic (e.g., finding the target via the Hub, calculating Manhattan distance, attacking or stepping closer).

Handles visual setup (scaling AtlasTexture sprites dynamically to fit the 64x64 grid).

4. The Clock: TurnManager.gd (Attached to TurnManager.tscn)
Purpose: Controls the flow of time and unit turns.

Key Responsibilities:

Retrieves the list of living units from the GameHub at the start of every round.

Tells the Hub to broadcast whose turn it is.

Waits for the active unit to finish, then advances to the next unit, dynamically skipping units that died during the round.

5. The Director: Main.gd (Attached to Main.tscn)
Purpose: The main game table that holds all the visual pieces together.

Key Responsibilities:

Instantiates (spawns) the units at the start of the game and registers them with the Hub.

Contains the UI (Start Battle button) to trigger the state change.

Listens for logical movement (unit_moved) from the Hub and uses Godot Tween nodes to smoothly animate the unit's sprite gliding across the screen.

## 🚀 Current Project Status
### Phase: Core Prototyping

[x] Establish Data Hub and Event Bus Architecture

[x] Create Grid-to-Pixel math mapping (Board)

[x] Create self-contained Unit state machine (UnitBase)

[x] Implement Turn Manager logic (Rounds and Turns)

[x] Implement basic AI (Find closest enemy via Manhattan distance, step forward, and attack)

[x] Add visual representation via sprite scaling and Tween animations.

## 🔮 Future Next Steps (Roadmap)

Visual Feedback (Health Bars & Damage Numbers): Add UI elements to the UnitBase so the player can visually see HP dropping without looking at the console.

Expanded AI Behaviors: Implement the logic for other focuses (e.g., "Defend Position" or "Hunt Weakest").

Terrain Effects: Update the movement logic so mountains block movement or cost double the movement range.

Game Over Detection: Make the GameHub or TurnManager recognize when all units on one team are defeated and trigger the RESOLUTION state to show a victory screen.

Pre-Battle Setup UI: Allow the player to click on units before pressing "Start" to select their behavior from a dropdown menu.