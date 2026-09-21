# Architectural Constitution & Implementation Lexicon

* **Document Path:** `res://docs/architecture_constitution.md`
* **Status:** **FROZEN / PRODUCTION-LOCKED** for Layers 1, 2, and the Framework GOAP engine. Active for Layer 3 (Game Features) and Presentation Harnesses.


* **Target Audience:** All AI agents, contributors, and human developers implementing or extending systems within this repository.

---

## 1. The Strict Directional Dependency Law (The One-Way Wall)

The codebase strictly adheres to an acyclic directed graph. Dependencies must point **downward** toward core infrastructure or inward toward data contracts:

```
┌─────────────────────────────────────────────────────────────┐
│ LAYER 4: STATIC DATA & SCHEMAS [FROZEN]                     │
│ res://docs/schemas/ (Event envelopes, Command packet shapes)│
└──────────────────────────────┬──────────────────────────────┘
                               │ Ingested by
┌──────────────────────────────▼──────────────────────────────┐
│ LAYER 3: GAME SIMULATION (Domain Rules & Concrete Logic)    │ [ACTIVE]
│ res://game/ (Actions, Resolvers, Evaluators, Goals)         │
└──────────────────────────────┬──────────────────────────────┘
                               │ Imports / Inherits
┌──────────────────────────────▼──────────────────────────────┐
│ LAYER 2: REUSABLE SUB-FRAMEWORKS & SIMULATION PRIMITIVES    │ [FROZEN]
│ res://framework/goap/ (Snapshots, Rules, Actions, Arbitrator,│
│                        Planner, Sequencer)                  │
│ res://simulation/ (spatial, resource, reservation)          │
└──────────────────────────────┬──────────────────────────────┘
                               │ Runs atop
┌──────────────────────────────▼──────────────────────────────┐
│ LAYER 1: ENGINE-AGNOSTIC CORE INFRASTRUCTURE [FROZEN]       │
│ res://core/ (SimClock, CommandBus, EventBus, RNG, Enums)    │
└──────────────────────────────┬──────────────────────────────┘
                               │ Read-Only Render Snapshot (Down)
                               ▲ Command Packet Ingestion (Up)
┌──────────────────────────────┴──────────────────────────────┐
│ PRESENTATION EXTENSION (The View / Godot Scene Tree)        │ [ACTIVE]
│ res://scenes/ (Test Views, Canvas Drawing, HUD Controls)    │
└─────────────────────────────────────────────────────────────┘

```

### Boundary Invariants

* **The Downward Rule:** Layer $N$ may import Layer $N-1$, but Layer $N-1$ can **never** import, reference, cast to, or know about Layer $N$.


* **The Sibling Isolation Rule:** Sub-modules within Layer 2 (e.g., `res://simulation/spatial/` and `res://simulation/resource/`) are strictly isolated and cannot import each other. Any inter-domain coordination must happen exclusively in Layer 3 game logic.


* **The View Air Gap:** Visual scripts in `res://scenes/` exist purely as peripheral presentation devices. Simulation code (Layers 1, 2, and 3) must never import view files, never call engine scene-tree methods, and never rely on visual node lifecycle hooks.



---

## 2. Universal Hard Constraints & Architectural Policies

### A. Core Immutability & The Reverse-Responsibility Law

* **Core Immutability:** Files in `res://core/` and `res://simulation/` are **frozen contracts**. Under no circumstances may core infrastructure (such as `CommandBus` or `SimClock`) be modified, patched, or injected with ad-hoc normalizations or alias mappings to accommodate domain-level variations.


* **Caller Responsibility:** High-level domain code (`res://game/`) is strictly responsible for constructing canonical, schema-compliant envelopes directly.



### B. Single-Writer Authority & CQS (Command-Query Separation)

* Every slice of simulation state in memory has exactly **one designated Writer class**.


* Direct mutations across module boundaries (e.g., `cell.occupant = id` or `depot.balance += 10`) are strictly banned.


* External changes are submitted exclusively via `command_bus.submit(packet)`.


* Evaluators, sensors, and state mappers access registries strictly in a **read-only** manner.



### C. Engine Purity & Headless Standard

* Any file in Layers 1, 2, or 3 must inherit from `RefCounted` or be a standalone script.


* **Strictly Blacklisted in Simulation Code:** `extends Node`, `Node2D`, `Control`, `CanvasItem`, `get_node()`, `get_tree()`, `$"..."`, `Input.*`, `position`, `rotation`, and `.tscn` preloads.


* **No `.tres` or Godot `Resource` files:** Everything in the framework and simulation layers must be pure code objects to guarantee full portability to C#/Unity.

### D. Canonical Null Standard

* The integer value `0` is the project-wide universal standard for empty cells, unassigned entities, system handles, and unreserved locks. Negative numbers or `null` must not be used as sentinel entity handles.



---

## 3. Communication Contracts & Envelopes

### A. The Canonical Command Envelope (`CommandBus`)

Actions and controllers must dispatch commands conforming strictly to `EnvelopeValidator.is_valid_command()`:

```gdscript
{
    "command_id": int,              # 0 for automatic sequential assignment
    "priority": int,                # CoreEnums.ExecutionPriority.INPUT_DIRECT
    "issuer_id": int,               # ID of the issuing pawn/entity
    "target_tick": int,             # Target simulation tick
    "payload": Dictionary           # Domain-specific parameters
}

```

#### Approved Command Payloads:

* **`&"SPATIAL_RELOCATION"`:**
```gdscript
"payload": { "from_coord": Vector2i, "to_coord": Vector2i }

```


* **`&"RESERVATION_CLAIM"`:**
```gdscript
"payload": { "claimant_id": int, "target_id": int, "claim_type": int, "duration": int }

```


* **`&"RESERVATION_RELEASE"`:**
```gdscript
"payload": { "claimant_id": int, "target_id": int }

```


* **`&"RESOURCE_TRANSFER"`:**
```gdscript
"payload": { "source_id": int, "destination_id": int, "resource_type": StringName, "amount": int }

```



### B. The Two-Stage CommandBus Contract

`CommandBus.register_command` enforces a two-stage pipeline:

```gdscript
command_bus.register_command(command_type: StringName, validator: Callable, executor: Callable) -> void

```

* **Validator:** Returns an `ExecutionResult` dictionary. For presentation testbeds, use a pass-through validator returning `ExecutionStatusCode.SUCCESS`.


* **Executor:** Mutates the underlying registry upon successful validation.



### C. The Canonical Event Envelope (`EventBus`)

Framework components (such as `GoapSequencer`) emit events as single dictionary payloads:

```gdscript
{
    "event_type": StringName,       # e.g., &"GOAP_ACTION_STARTED"
    "tick_timestamp": int,          # current tick
    "source_entity_id": int,        # agent/issuer ID
    "target_entity_id": int,        # target ID or 0
    "event_data": Dictionary        # context-specific telemetry
}

```

---

## 4. Hard-Learned Lessons & Anti-Patterns (Forensic Insights)

The following failure modes occurred during previous sprints and must be actively avoided:

1. **The Static Class Method Trap:**
* *Problem:* A class authored as an instance utility (no `static` keyword) cannot be called directly via `ClassName.method()` without triggering Godot parser errors.


* *Rule:* All stateless evaluators, target resolvers, and mappers (e.g., `LogisticsStateMapper`, `TargetDepotResolver`) **must** declare their methods as `static func`.




2. **The Missing Binding Parameter Trap:**
* *Problem:* Inheriting `GoapAction` without overriding `generate_bindings()` produces empty binding parameters (`{}`). When `action.on_step()` calls `binding.get_param(...)`, it returns `null`, silently breaking arithmetic or coordinate progression.


* *Rule:* Actions must always implement defensive parameter resolution with fallback to the execution `context`:


```gdscript
var target_coord = binding.get_param(&"target_coord", Vector2i(-1, -1))
if target_coord == Vector2i(-1, -1) and context.has("target_depot"):
    target_coord = context["target_depot"].get("coord", Vector2i(-1, -1))

```




3. **Untyped Duck-Typing at Framework Boundaries:**
* *Problem:* Typing `command_bus` or `event_bus` with concrete classes inside `res://framework/` couples the framework to specific project implementations.
* *Rule:* Framework classes (like `GoapSequencer`) must type bus parameters as `Object = null` and invoke methods using duck-typing checks.




4. **Discrete State Synchronization (Instant Snapping):**
* *Problem:* Attempting to visually tween or lerp pawns across discrete simulation grids creates frame latency that desynchronizes visual presentation from underlying registry states.
* *Rule:* Test presentation harnesses must **snap immediately** to discrete cell coordinates on each tick without continuous interpolation.




5. **`SimClock` Contract Adherence:**
* *Problem:* Calling non-existent methods like `advance()` or `get_tick()` on `SimClock` causes runtime crashes.


* *Rule:* Use `sim_clock.step_tick() -> int` to atomically advance the clock and read `sim_clock.current_tick`.





---

## 5. System Milestone & Status Ledger

| Layer / Subsystem | Folder Path | Archetype | Status | Audit Score |
| --- | --- | --- | --- | --- |
| **Core Infrastructure** | `res://core/` | Time, Event, Command, RNG | **FROZEN**<br> | **Tier A (100%)** |
| **Simulation Primitives** | `res://simulation/` | Spatial, Resource, Reservation | **FROZEN**<br> | **Tier A (100%)** |
| **GOAP Phase 1** | `res://framework/goap/common/` | StateSnapshot, Rules, Effects | **FROZEN**<br> | **Tier A (100%)** |
| **GOAP Phase 2** | `res://framework/goap/goals/` | Actions, Bindings, Arbitrator | **FROZEN**<br> | **Tier A (100%)** |
| **GOAP Phase 3** | `res://framework/goap/planner/` | Bounded A* Planner, Plan DTO | **FROZEN**<br> | **Tier A (99.7%)** |
| **GOAP Phase 4** | `res://framework/goap/sequencer/` | Runtime Sequencer & Preemption | **FROZEN**<br> | **Tier A (100%)** |
| **Logistics Domain** | `res://game/logistics/` | Actions, Evaluators, Goals | **COMPLETE** | **Tier A (100%)** |
| **Logistics Test View** | `res://scenes/tests/logistics/` | Presentation Canvas & Harness | **OPERATIONAL** | **Tier A (100%)** |

---

## 6. Mandatory AI Context Reminder Prompt Snippet

When initiating new tasks or prompts for AI collaborators (such as Jules), **always prepend or include this directive**:

```markdown
IMPORTANT CONTEXT & INVARIANTS:
1. Review and adhere strictly to `res://docs/architecture_constitution.md`.
2. Core and Framework Immutability: Do NOT modify any file under `res://core/`, `res://simulation/`, or `res://framework/goap/`. These layers are FROZEN at Tier A.
3. CQS & Envelopes: All state changes must be submitted as canonical CommandPacket dictionaries (`command_id`, `priority`, `issuer_id`, `target_tick`, `payload`) to CommandBus. Never mutate registries directly.
4. Evaluator Purity: All standalone evaluators and mappers must declare their methods as `static func`.
5. Canonical Null Standard: Always use integer `0` for unassigned entities, unreserved locks, or empty cells.

```