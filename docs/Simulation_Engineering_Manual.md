# FANTAC MVP - Simulation Engineering Manual

## 1. Introduction and Overview
FANTAC is built upon a deterministic WeGo (simultaneous execution) tactical engine. Unlike traditional turn-based games where units act sequentially, FANTAC executes player intents simultaneously in a controlled headless simulation loop before visualizing the outcome. The simulation is decoupled entirely from visual rendering and user interfaces, processing state mutations in memory to guarantee perfect determinism and prevent race conditions.

This document serves as an exhaustive, plain-text engineering book detailing the exact flow of the simulation, 3D traversal, combat, UI interactions, and telemetry logging.

## 2. The Micro-Tick Engine Architecture
The core of the simulation resolves a combat turn through a strictly governed loop of 100 discrete "micro-ticks". A micro-tick represents a tiny slice of time where physics, movement, and logic are evaluated. By breaking continuous action into micro-ticks, the engine eliminates the need for arbitrary turn orders.

During a single turn simulation, the headless server processes these micro-ticks from 0 to 99 in a single synchronous blocking loop. Each step of the micro-tick evaluates specific phases in a strict execution order:

1.  **Projectile Physics and Interception:** The engine advances active ranged projectiles in 3D space, checking for terrain blockages or unit collisions.
2.  **AI Tree Evaluation:** Units evaluate their behavior trees based on current spatial and status data, generating actionable intents such as moving, attacking, or falling back.
3.  **Movement Cooldowns:** The engine decrements internal movement cooldowns. Units cannot traverse spatial tiles instantly; they must wait out a cooldown defined by their encumbrance and speed parameters before advancing a tile.
4.  **Initiative Collision Resolution:** If multiple units attempt to step onto the same spatial coordinate within the same micro-tick, an Initiative Server mathematically resolves the collision. The winner claims the tile, while the loser is penalized with a path recalculation cooldown.
5.  **Combat and Morale Application:** Scheduled melee strikes or projectile hits apply damage. Stress accumulates based on damage taken, which is immediately checked against morale limits to trigger panic states (Order Fractures).
6.  **Snapshot Serialization:** The exact state of the board—including unit positions, health, morale, active projectiles, and telemetry logs—is serialized into a discrete "Snapshot" for the current tick.

The resulting 100 snapshots are bundled into a Turn Replay Buffer, which acts as the read-only blueprint that the visual layer scrubs through during the playback phase.

## 3. Spatial Mechanics and Z-Level Navigation

### The Battlefield Matrix
The battlefield is defined as a discrete 3D spatial grid where tiles are indexed by three-dimensional coordinates. In the current MVP, the grid features multiple vertical Z-levels (e.g., ground level at Z0, elevated ramparts at Z1).

### Line of Sight (LOS) and Targeting Across Z-Levels
When units engage targets (especially across varying elevations), the engine calculates a discrete 3D Line of Sight using a Digital Differential Analyzer (DDA) algorithm. This raycast does not use physics engine colliders; instead, it traces voxel-by-voxel from the attacker’s physical coordinate to the target's physical coordinate.

When a unit spots a target on a different Z-level:
*   The raycast accounts for the height offset of the respective Z-levels (e.g., Ground is 0.0 meters, Rampart is 3.0 meters).
*   A slight spatial offset (epsilon) is applied to prevent floating-point inaccuracies at exact grid boundaries.
*   The system checks every intermediate voxel for structural occlusions. If a high-wall prop exists on an intermediate tile, LOS is instantly blocked.
*   **Cover Masking:** If the target is on a higher elevation behind a solid parapet, the engine detects this spatial relationship. If the parapet specifically blocks the cardinal direction the attack originates from, the target benefits from significant damage mitigation or complete blockage.

### Traversing Z-Levels (Vertical Pathing)
Units navigate the 3D grid using A* Pathfinding strictly limited to four cardinal directions (North, South, East, West). Diagonal movement is forbidden.

Navigating between Z-levels requires dedicated vertical connectors, such as structural stairs.
*   When a unit's AI attempts to plot a route ascending or descending a Z-level, the pathfinding engine strictly queries the tile's connector type.
*   The traversal is only permitted if the unit's cardinal entry direction aligns perfectly with the orientation of the stairs. A unit cannot jump sideways off a stairwell; it must traverse it linearly.
*   Ascending stairs does not artificially inflate movement costs in a vacuum; instead, it is organically governed by the unit's internal tick-cost required to step between those two spatial vectors.

## 4. Combat, Destructible Terrain, and Morale

### Melee and Ranged Dynamics
*   **Melee Combat:** Triggered by cardinal adjacency on matching Z-levels. If units are adjacent, melee strikes execute immediately without ballistic travel time, factoring in weapon hardness and base damage.
*   **Ranged Combat:** Fully simulated via projectiles. Projectiles travel along spatial velocity vectors per micro-tick. They physically drop or rise based on targeting. A projectile can intercept unintended targets if another unit crosses its trajectory mid-flight, or it can be blocked by structural elements based on physical Z-height boundaries.

### Destructible Tactical Props
Props such as wooden gates are physical entities within the matrix. When attacked, a material hardness check occurs.
*   If the attacker’s weapon hardness surpasses the prop's material threshold, structural damage is applied.
*   If the prop is destroyed, it crumbles into a rubble state. This dynamically alters the battlefield: it increases traversal costs over that tile, removes visual and LOS occlusions, and collapses any elevated tiles structurally attached to it, forcing dynamic path recalculations for any AI intending to traverse the fallen route.

### Morale and Order Fracturing
Every instance of damage generates stress. If a unit's internal stress pool exceeds a critical threshold (calculated by bravery and loyalty ratings), the unit suffers a morale fracture.
*   A fractured unit immediately drops all active directives and player intents.
*   Their AI tree forces an "uncontrolled fallback", ignoring standard engagement rules and fleeing toward safety.
*   If a unit is killed outright, it generates a massive passive stress shockwave to nearby allies, potentially causing a chain-reaction rout.

## 5. AI Tree Evaluation and Intent Generation
AI templates govern unit behaviors (e.g., Aggressive Assault, Cautious Overwatch, Point Guard). The evaluator processes logic branches conditionally.
*   It operates as a decentralized authority for intent generation. Player inputs (UI Directives) temporarily override or guide the AI's fallback behaviors.
*   The system includes hysteresis timers—if an AI decides to fall back to cover, it is locked into that behavioral branch for a set duration of ticks. This prevents rapid flickering between "fleeing" and "attacking" decisions when health or stress fluctuates slightly.
*   If a ranged attack is evaluated, a modular helper checks for 3D LOS and range constraints. If blocked, the AI gracefully degrades its decision back to movement, plotting a path to gain a better vantage point.

## 6. Telemetry, Logging, and Debug Dumps
Because the simulation server is entirely headless and instantaneous, it behaves as a "black box" until the visual playback phase. To ensure traceability and mechanical transparency:
*   **Telemetry Badges:** The engine generates string-based telemetry events dynamically during the micro-ticks (e.g., noting when a unit's morale fractures or when they execute a major AI decision). These strings are serialized directly into the snapshot buffer.
*   **Console Dumps:** Once a simulation turn completes, the Main Game Manager generates a strict differential state dump in the backend console. This explicitly compares the start and end states of every unit (Start Coordinates vs. End Coordinates, Start HP vs. End HP, and Active AI States). This guarantees mathematical proof that the AI evaluated and moved correctly without relying purely on visual debugging.

## 7. UI Constraints and Visual Playback

### The Render Pipeline
The visual and user interface systems are strictly confined to an observer pattern. They are forbidden from calculating game logic or mutating grid state.
*   During playback, a global scrubber translates real-time delta time into micro-tick indices.
*   The visual tokens (representing units) read their respective coordinates from the Turn Replay Buffer at that specific tick. They move by interpolating or snapping between these recorded discrete positions.
*   The 2D camera translates the 3D logical coordinates into screen space formulas to simulate depth and orthographic perspective.

### Commander Interface and UI Directives
The User Interface adheres to a strict single-prefab dynamic design.
*   Instead of rendering complex UI trees for every entity on the board, the system instantiates a single Inspector interface.
*   When a unit is selected, this single UI block intercepts the signal, queries the static data dictionaries, and redraws itself to reflect the selected unit.
*   Players issue intents (like selecting a target tile for movement). The UI intercepts these clicks, draws visual intent lines to the center of the target tile (ignoring actual pathfinding constraints to simply display raw intent), and stores the coordinate in a draft dictionary.
*   If a unit is currently suffering from a morale fracture, the UI directly disables all command inputs for that entity and overrides their status panel to read "UNCONTROLLED", enforcing the mechanical consequence at the interaction level.
*   Once the turn is submitted, the UI sends this draft dictionary payload to the Simulation Server, clears its local cache, and locks all inputs to prevent state bleeding while the simulation resolves.
