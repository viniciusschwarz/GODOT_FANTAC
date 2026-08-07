You are an expert Godot 4 & GDScript Software Architect. I am building a 2D tactical auto-battler. We need to validate and fix the complete end-to-end gameplay loop to ensure the game is fully playable. 

The intended gameplay flow is:
1. Boot -> See Start Screen
2. Start Game -> Campaign Screen appears with available missions
3. Player selects a mission -> Mission starts
4. Map is generated
5. Deployment Phase -> Player places units on the board
6. Behavior Setup -> Player sets up unit AI behaviors
7. Player starts battle -> Enemy AI places its units
8. Battle starts -> Auto-battle simulation runs
9. End of battle -> Show results screen
10. Return to Campaign screen -> Repeat cycle.

I will provide my scripts and scenes in phases. For each phase, you must perform TWO tasks:

TASK 1: PLAYABILITY VALIDATION & REFACTORING
Review the files and determine if the flow can transition perfectly from start to finish. If anything is broken, missing, or poorly connected, write the code to fix it based on these strict rules:
1. Manager-Driven Flow: The UI must NOT contain core game logic. UI scripts should only emit signals or read data. State changes (like changing phases) must be handled by Central Hubs (e.g., `game_state.gd`, `phase_manager.gd`).
2. Zero Coupling: Scene transitions and data passing must use Autoloads or Signals, not hardcoded paths or direct script-to-script injections.
3. Scalable Logic: Ensure prefabs and dynamic containers are used for UI lists (like mission selection or unit deployment) rather than hardcoded UI elements.
4. Clean Code: Maintain GDScript strict typing and the DRY principle.

TASK 2: GAMEPLAY FLOW DOCUMENTATION
Generate and update a document named "Gameplay_Flow_Validation.md" in the docs folder. For each phase, document:
- Flow Step: Which part of the gameplay loop we are on.
- Current Status: Playable, Broken, or Missing.
- Architectural Fixes: Exactly what you changed to connect the systems properly without coupling.
- Required Signals/Variables: The data moving between the UI and the Managers for this step.

EXECUTION PLAN (Work on one phase per time and ask as many questions as needed to understand the flow):
- Phase 1: The Out-of-Battle Loop (Start Screen, Campaign Screen, Mission Selection, Return to Campaign).
- Phase 2: Pre-Battle Setup (Map Generation, Player Deployment, AI Behavior Setup).
- Phase 3: The Combat Loop (Enemy Deployment, Battle Start, Auto-Battler Execution, End/Results Screen)."