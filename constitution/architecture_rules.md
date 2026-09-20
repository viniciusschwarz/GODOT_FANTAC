To prevent an AI coder from entangling systems as the codebase scales, architectural rules cannot be high-level philosophical suggestions. They must be **deterministic boundary constraints** that define who owns memory, who can alter state, how data traverses system lines, and what code is physically permitted to import.

Here is the exhaustive expansion of the architectural rules, categorized into five non-negotiable enforcement pillars.

---

### 1. The Strict Directional Dependency Law (The One-Way Wall)

The engine follows an absolute acyclic directed graph. Dependencies may only point **downward** toward infrastructure or inward toward data contracts.

```
┌─────────────────────────────────────────────────────────────┐
│ LAYER 4: DEFINITIONS & SCHEMAS (Static Config)              │
│ (.json, .tres, static resource registries)                  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Ingested by
┌──────────────────────────────▼──────────────────────────────┐
│ LAYER 3: GAME SIMULATION (Domain Rules & Concrete Logic)    │
│ (Custom mechanics, turn loops, combat resolution, AI trees) │
└──────────────────────────────┬──────────────────────────────┘
                               │ Imports / Inherits
┌──────────────────────────────▼──────────────────────────────┐
│ LAYER 2: REUSABLE DOMAIN SUB-FRAMEWORKS                     │
│ (Spatial grids, attribute modifier pipelines, item slots)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Runs atop
┌──────────────────────────────▼──────────────────────────────┐
│ LAYER 1: ENGINE-AGNOSTIC INFRASTRUCTURE                     │
│ (SimClock, CommandBus, EventBus, SaveRegistry, RNGStream)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Read-Only Render Snapshot (Down)
                               ▲ Command Packet Ingestion (Up)
┌──────────────────────────────┴──────────────────────────────┐
│ PRESENTATION EXTENSION (The View / Godot Scene Tree)        │
│ (Node2D, MultiMeshInstance2D, Control, UI, Audio, Shaders)  │
└─────────────────────────────────────────────────────────────┘

```

#### Boundary Invariants:

* **The Downward Rule:** Layer $N$ may import Layer $N-1$, but Layer $N-1$ can **never** import, reference, cast to, or know about Layer $N$.
* **The Sibling Isolation Rule:** Within Layer 2, modular sub-frameworks (e.g., `domain_spatial_grid` and `domain_attribute_pipeline`) are strictly isolated. They cannot import each other. If a game needs an entity's attribute to affect its spatial movement speed, that coordination happens **exclusively in Layer 3** (the game logic layer).
* **The View Air Gap:** The Godot Scene Tree (`view_*`) exists purely as a peripheral device. It depends on Layers 1 and 4, and observes Layer 3 via read-only data snapshots. **Simulation code (Layers 1, 2, and 3) must never import `view_*` files or call engine scene-tree methods.**

---

### 2. State Mutation & Ownership (The Single-Writer Principle)

LLM-generated codebases disintegrate when multiple systems mutate the same shared state dictionary or object fields directly.

#### A. Single Authority (One Writer per Domain)

* Every slice of state in memory has exactly **one designated Writer class**.
* All other classes have **Read-Only access** (via immutable return values or copies).

| State Domain | Authorized Writer (Single Authority) | Permitted Readers | Strictly Forbidden Writers |
| --- | --- | --- | --- |
| **Grid Cell Contents** | `SpatialCellRegistry` | Pathfinders, Sensors, View Renderers | AI Agents, Combat Resolvers, UI |
| **Entity Attributes** | `AttributeModifierPipeline` | Needs Evaluators, Damage Resolvers, UI | Inventory, Input Handlers, Direct Scripts |
| **Resource Reservations** | `ReservationRegistry` | Job Drivers, Worker Schedulers | Pawns/Agents directly, Pathfinders |
| **Active Simulation Time** | `SimClock` | All systems (queries `current_tick`) | Any gameplay script, UI buttons |

#### B. Command-Driven Mutations

No game state can be altered by directly setting fields across module boundaries (e.g., forbidding `target_entity.current_health -= 10` or `cell.is_occupied = true`).

* **External intents must be submitted as Commands:** A caller creates a `CommandPacket` and submits it to the `CommandBus`.
* **Validation Phase:** The targeted domain’s `Validator` tests whether the command is legal given the current tick's state.
* **Commit Phase:** Only upon successful validation does the Single Authority mutate the state and emit a domain event.

#### C. Temporal Boundaries (The Phase Lock)

A tick is not a continuous, free-for-all execution. It executes in explicit, sequential phases to eliminate order-of-execution bugs:

```
[Phase 1: Ingestion]    Flushes incoming CommandPackets from UI/Input buffer.
        ↓
[Phase 2: Sensory]      Sensors query world state; update Blackboards (Read-Only).
        ↓
[Phase 3: Evaluation]   AI/Rules evaluate Blackboards and queue actions (No world mutation).
        ↓
[Phase 4: Resolution]   Atomic execution of actions via single-writer domain authorities.
        ↓
[Phase 5: Commit/Emit]  SimClock increments tick counter; emits StateSnapshot to View.

```

---

### 3. Engine Import & Syntax Sanity Bouncers

To guarantee that the simulation core remains 100% headless, testable, and immune to Godot-specific scene-tree bugs, the codebase enforces structural import rules.

#### A. The Blacklisted Symbols in Simulation Layers (Layers 1, 2, 3)

If any file outside of `view/` contains these keywords, it is rejected by the static boundary checker:

* `extends Node2D`, `extends Control`, `extends Node3D`, `extends CanvasItem`.
* `get_node()`, `get_parent()`, `get_tree()`, `Owner`, `$"..."`.
* `Input.is_action_pressed()`, `InputEvent`.
* `position`, `global_position`, `rotation` (Spatial logic must use discrete `Vector2i` cells or abstract math coordinates).
* `load()`, `preload()` of `.tscn` scene files.

#### B. Permitted Types in Simulation

Simulation code is strictly restricted to:

* Primitives: `int`, `float`, `bool`, `StringName`, `Vector2i`, `Rect2i`.
* Native Data Structures: `Array`, `PackedInt32Array`, `PackedFloat32Array`, `Dictionary`.
* Engine Math: `Mathf`, `Vector2` (pure arithmetic only), `AStar2D` (headless).
* Abstract Core Classes: Inheriting from `RefCounted` or standalone plain GDScript/C# objects.

---

### 4. Data Transfer Protocols: DTOs vs. Live References

An AI will naturally pass live object instances into methods, allowing functions to poke at internal variables. This is banned.

#### A. The "Data Transfer Object" (DTO) Mandate

Communication across layer boundaries must use **flat, serialized-safe data shapes** (Dictionaries or flat Structs):

* **No Class Reference Leaking:** A combat calculation does not accept a `PlayerCharacter` or `Monster` instance. It accepts an `AttackContext` dictionary containing only the necessary scalar values (`base_damage: float`, `penetration: float`, `target_armor: float`).
* **Stateless Calculations:** When passing data to an `*Evaluator` or `*Resolver`, the method must be pure: inputs go in, a result dictionary comes out, with zero mutation of the input parameters.

#### B. Handle-Based Identity

Entities and cells never store direct pointers to other entities:

* Entities are referenced across systems solely by integer handles (`actor_id: int`, `item_id: int`, `cell_coord: Vector2i`).
* If a system needs to know about an actor, it passes the `actor_id` to the appropriate `Registry` to query a read-only snapshot.
* **Why this is critical:** When an entity is destroyed or deleted, there are no dangling object references in other systems to cause memory leaks or `null instance` crashes.

---

### 5. Memory Allocation & Performance Boundaries

Because the engine must support high-speed simulation ($1\times, 3\times, 5\times$) with thousands of entities, the AI must not generate memory-churning code.

1. **Zero Allocations Inside Ticks:**
* Methods that run every tick (`tick_*`, `evaluate_*`, `resolve_*`) cannot call `.new()` or dynamically allocate large arrays.
* Collections that receive temporary calculations must be pre-allocated buffers or reused scratchpads cleared via `.clear()`.


2. **Contiguous Flat Arrays Over Deep Trees:**
* World grids are stored as flat 1D packed arrays (`width * height`), never as nested arrays of arrays (`grid[x][y]`).
* Cell coordinates are mapped using integer indices: `cell_index = (coord.y * grid_width) + coord.x`.


3. **Dirty-Flag State Propagation:**
* The simulation must not emit full state dumps to the presentation layer every tick.
* Domains maintain a `dirty_mask` or `dirty_indices_buffer`. Only the cells, entities, or stats that mutated during the current tick are copied into the delta snapshot for rendering.



---

### Summary of Architectural Invariants

| Category | The Rule | Machine Verification Method |
| --- | --- | --- |
| **Dependencies** | Strict one-way downward flow; no upward or sibling imports. | Static linter checks import paths in file headers. |
| **Mutation** | Only the registered Authority can write to its domain state. | Write methods restricted to package-private access or assertion guards. |
| **Engine Isolation** | No SceneTree or Node2D references in Layers 1, 2, or 3. | RegEx scanner rejects `get_node`, `Node2D`, `$"`, etc. |
| **Data Flow** | Cross-boundary communication uses flat DTOs and integer IDs. | Linter flags passing object instances into public API signatures. |
| **Lifecycle** | Discrete 5-phase tick execution; zero memory allocation in ticks. | Performance profiler and allocation tests in headless test runner. |