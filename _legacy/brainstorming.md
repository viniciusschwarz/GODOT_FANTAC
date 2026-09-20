Here is a comprehensive summary of the architecture, workflow, and engineering strategies discussed, structured directly for you to copy and paste into a `README.md` or design document.

---

# Architecture & AI Development Strategy: Modular Simulation Engine

## 1. Core Problem Statement & Post-Mortem

* **The "Inner-Platform" Trap:** Building an engine agnostic enough to run generic JSON scenarios turns the configuration into an ad-hoc, untyped, bug-prone programming language (Greenspun’s Tenth Rule). JSON must hold static data, never execution logic or control flow.
* **The AI Failure Mode:** When relying heavily on AI coders with minimal manual line-by-line review, LLMs exhibit two fatal flaws:
1. *Locality Bias:* They patch bugs by taking the shortest path—reaching across system fences, coupling classes, and introducing ad-hoc singletons.
2. *Context Drift:* Over 50+ scripts, the AI loses track of cross-system contracts and invents "pseudo-fixes" that silently break downstream code.


* **The Core Thesis:** You cannot make an AI disciplined through conversational prompts alone. You must place the AI inside a **machine-enforced structural cage** where it is physically and contextually impossible to write coupled code.

---

## 2. The 4-Layer Architecture Model

A strict one-way dependency model. Lower layers never reference upper layers.

```
[Layer 4: Content & Schemas]      (Pure data: JSON/Resources, balance tables, item specs)
             ↓
[Layer 3: Simulation Core]        (Headless domain logic: 1D grid arrays, jobs, needs, combat)
             ↓
[Layer 2: Presentation Layer]     (Godot View: MultiMeshInstance2D, UI HUD, camera, audio)
             ↓
[Layer 1: Universal Plumbing]     (SimClock, CommandBus, EventBus, SaveRegistry, RNGService)

```

* **The Air Gap:** The simulation (Layer 3) has zero awareness of the Godot SceneTree (`Node2D`, `CanvasItem`, `get_node()`, etc.). It runs purely on mathematical arrays and data structures on a discrete, deterministic tick.
* **Fast-Forwarding (1x, 3x, 5x):** Ticking is decoupled from visual frame rates. The engine runs the simulation tick loop multiple times per visual frame, avoiding visual jitter or desyncs.
* **Communication Boundary:**
* **Input (Upwards):** View emits a `CommandPacket` (intent) to the Core.
* **Output (Downwards):** Simulation publishes a read-only `StateSnapshot` (or delta chunks) that the View renders.



---

## 3. The 6 Universal Game-Agnostic Systems (Layer 1)

These form the foundational infrastructure and are reusable across any 2D genre:

1. **SimClock:** Deterministic tick runner that manages logical fixed deltas, speed multipliers, and pause states.
2. **CommandBus:** Ingests plain data command packets (`{ type, actor_id, payload }`), validates them, and executes them in sequence. Enables Undo/Redo and replays.
3. **EventBus:** Pub/sub notification network for fire-and-forget state changes without coupling sender to receiver.
4. **RNGService:** Manages isolated, seedable pseudo-random streams to guarantee reproducibility between generation and gameplay loops.
5. **SaveRegistry:** Collects key-value state dictionaries from registered components, versions them, and serializes/deserializes them without knowing their contents.
6. **ScreenRouter:** Stack-based view and modal coordinator that manages UI lifecycle and focus traps independently of game logic.

---

## 4. Semantic Lexicon & Naming Governance

To prevent the AI from generating vague, tangled enterprise code, enforce explicit naming conventions:

* **Blacklisted Suffixes:** `Manager`, `Handler`, `Processor`, `Controller`, `Helper`, `Util`, `Data`, `Info`.
* **Allowed Functional Archetypes (Every class must end in one of these):**
* `*Registry`: Stores, retrieves, and indexes records (Read/Write data store).
* `*Driver`: Executes an active, multi-tick lifecycle from start to finish.
* `*Evaluator`: Pure function/logic that takes state, runs math, and outputs a score or decision.
* `*Buffer`: Queues, batches, or holds pending changes until an execution tick.
* `*Resolver`: Calculates the interaction between entities and outputs the result.


* **Ubiquitous Grammar:**
* Booleans: Must assert state (`is_drafted`, `has_reservation`, `can_harvest`).
* Numbers: Must specify physical units (`tick_interval`, `distance_in_cells`, `duration_seconds`).
* Functions: Strictly `Verb + Target + Modifier` or query assertions (`has_available_food()`, `claim_first_available_job()`).
* Domain Glossary: Explicit naming across the project (e.g., exclusively use `Pawn`, never mix with `Unit`, `Agent`, or `Character`; use `Cell`, never `Tile` or `Position`).



---

## 5. Specification & Documentation Strategy: The 3-Tier Model

Avoid creating an unmaintainable `.md` file for every single script. Use a 3-tier approach:

* **Tier 1: Domain Specs (4 to 6 documents total across the entire game):**
* High-level architectural specs per bounded context (e.g., `spec_grid_and_environment.md`, `spec_jobs_and_reservations.md`, `spec_pawn_lifecycle.md`, `spec_combat.md`).
* Contains only: Data schemas (DTOs), mutation permissions (who is allowed to write vs. read), and the execution pipeline order.


* **Tier 2: Code Stubs as Machine Contracts:**
* Empty GDScript/C# class files containing only typed method signatures, return types, and docstrings with negative constraints (e.g., *"DO NOT mutate health; return only damage values"*).
* Serves as the immutable interface that the AI is forbidden from altering.


* **Tier 3: Executable Contract Tests:**
* Headless test scripts asserting expected behavior, edge cases, and failure modes against the empty stubs.



---

## 6. The Day-to-Day AI Development Workflow

For every subsystem, follow a strict 4-step assembly pipeline:

1. **Isolate Context:** Provide the AI with only the specific Domain Spec and the target stub file. Never supply files from other domains or the Godot SceneTree.
2. **Generate Test Harness (Prompt 1):** Have the AI write headless unit tests against the empty contract stub covering normal use and edge cases.
3. **Implement Internals (Prompt 2):** Instruct the AI to write the internal logic of the stub to pass the unit tests. Forbid it from modifying method signatures or adding imports.
4. **Machine-Enforced Bouncer (Static Lint / CI):** Run an automated boundary check (via script/pre-commit):
* Rejects any forbidden imports (`get_node()`, `get_parent()`, `Owner`, etc.) inside `sim/`.
* Rejects any invented keys not declared in the domain schema.
* Runs tests headlessly via CLI.
* If a check or test fails, paste the error directly back to the AI for self-correction.