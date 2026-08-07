The Prototype Plan
Step 1: Core Foundation (The Event Bus)

We will set up a simple Singleton to handle game-wide signals (e.g., z_level_changed, simulation_started, unit_moved).

Step 2: The Map Architecture & Z-Level Manager

We will use Godot's TileMap system (or TileMapLayer nodes) stacked on top of each other to represent Floor -1 (Basement), Floor 0 (Ground), and Floor 1 (Upper House).

We will plan a script that listens to the Event Bus and visually manages these layers (e.g., hiding Floor 1 when viewing Floor 0, and darkening Floor 0 so it looks like it's "below" when viewing Floor 1).

Step 3: The Camera Controller

A modular camera script that moves in XY space (WASD/Arrows) and can shift its current Z-level focus up and down.

Step 4: The Unit (Player)

A simple circle Sprite2D with a modular movement component. It will snap to the grid.

We will implement "Stairs" logic: specific grid coordinates that, when stepped on, tell the unit to change its Z-level.

Step 5: UI & Game State

A simple CanvasLayer with a "Start Simulation" button that broadcasts to the Event Bus, shifting the game from "Deployment Mode" to "Active Mode".