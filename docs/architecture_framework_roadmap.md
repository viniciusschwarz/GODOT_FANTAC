# Simulation Frameworks Roadmap & Integration Blueprint

* **Document Path:** `res://docs/architecture_framework_roadmap.md`
* **Target Audience:** Core contributors, maintainers, and autonomous AI agents working in this repository.
* **Architectural Reference:** `res://docs/architecture_constitution.md` (Constitutional Invariants & Lexicon).



---

## 1. Architectural Invariant Preamble

All frameworks specified in this document are **Layer 2 Domain Sub-Frameworks**. When implementing them, the following non-negotiable boundaries from the Architectural Constitution apply:

1. **Engine-Agnostic Purity:** Every class must inherit from `RefCounted` or be a plain GDScript object. Visual classes (`Node`, `Node2D`, `Control`, `CanvasItem`), scene trees (`get_node()`, `get_tree()`), engine input handlers, and `.tres` Resource assets are strictly prohibited.


2. **Single-Writer Authority & CQS:** Every state domain has exactly one authoritative registry. External systems cannot mutate fields directly; all mutations occur via `CommandBus.submit()` executing against registered validators and executors.


3. **Stateless Evaluators & Pure Queries:** Mappers, heuristic calculators, and target resolvers must declare their methods as `static func` and operate strictly on read-only snapshots and input parameters.


4. **Canonical Null Standard:** Integer `0` is the invariant standard for unassigned entities, empty cells, and unreserved locks.


5. **Frozen Layer Immutability:** `res://core/` (SimClock, CommandBus, EventBus, Enums), `res://simulation/` (primitives), and `res://framework/goap/` (Phases 1–4) are **frozen at Tier A**. They must not be modified to accommodate new frameworks.



---

## 2. Sequencing Logic & Dependency Graph

Adding mechanics without clear topological sequencing causes architectural drift. The frameworks must be implemented in the following order:

```
[Phase 1 Complete: Core & GOAP Engine]
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. SPATIAL TOPOLOGY & PATHFINDING GRAPH                     │
│    (res://framework/pathfinding/)                           │
│    Provides realistic navigation costs & obstacle traversal │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. ATTRIBUTE & NEEDS MODIFIER PIPELINE                      │
│    (res://framework/attributes/)                            │
│    Introduces pawn internal state, hunger, rest, and fatigue│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. JOB BOARD & TASK ALLOCATION BROKER                       │
│    (res://framework/jobs/)                                  │
│    Decouples individual agent goals from world-level tasks  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. MULTI-TIER PRODUCTION & TRANSFORMATION ENGINE            │
│    (res://framework/production/)                            │
│    Adds recipe execution, processing times, and workbenches │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. TURN-BASED TACTICAL COMBAT RESOLVER                      │
│    (res://framework/combat/)                                │
│    Introduces Action Points, line-of-sight, and mitigation   │
└─────────────────────────────────────────────────────────────┘

```

### Rationale for this Sequence

1. **Pathfinding before Attributes:** `ActionNavigateTo` currently relies on Manhattan math on an empty grid. Accurate path distance and terrain cost must exist before energy decay and movement fatigue can be calculated mathematically.


2. **Attributes before Jobs:** Before a job board can assign work, pawns must have internal constraints (energy, health, hunger) to evaluate whether they can accept or must reject/preempt a job in favor of survival.


3. **Jobs before Production:** Production recipes require workstations, material delivery, and labor. A job broker is required to broadcast tasks like "Bring 10 Wood to Sawmill" or "Operate Loom" to available agents.


4. **Combat Last:** Combat adds adversarial goal interruption, hostile targeting, and dynamic survival states, all of which depend on pathing, physical attributes (health, stamina), and equipment.



---

## 3. Detailed Framework Specifications

---

### Framework 1: Spatial Topology & Cost Navigation Graph (`res://framework/pathfinding/`)

#### Purpose & Scope

Replaces simple Manhattan delta movement with a headless weighted graph navigation engine. Supports dynamic cell passability, terrain transit costs (e.g., roads vs. rough mud), static obstacles, and door/portal states.

#### Domain Components & Single Authority

* **Registry:** `PathfindingGraphRegistry` (Single Authority over cell edge weights and traversal masks).


* Internal data: Flat 1D packed array storing transit weights ($1.0 = \text{standard}$, $2.0 = \text{rough}$, $\infty = \text{blocked}$).




* **Solver:** `Pathfinder2D` (Headless $A^*$ solver operating on discrete cell coordinates).
* Method: `static func find_path(start: Vector2i, destination: Vector2i, graph: PathfindingGraphRegistry, mask: int) -> PackedVector2Array`.



#### Command & Event Contracts

* Commands submitted to `CommandBus`:
* `&"SET_CELL_TRAVERSAL_COST"`: `payload: {"coord": Vector2i, "cost_multiplier": float}`.


* `&"SET_CELL_BLOCKED"`: `payload: {"coord": Vector2i, "is_blocked": bool}`.




* Events emitted to `EventBus`:
* `&"TOPOLOGY_COST_MODIFIED"`: `event_data: {"coord": Vector2i, "cost": float}`.





#### GOAP & Simulation Integration

* **`ActionNavigateTo` Upgrade:** Replaces linear stepping with precomputed waypoints stored in the action's execution context.


* **Dynamic Action Cost:** `Action.calculate_cost()` calls `Pathfinder2D` to return the real path distance, allowing `GoapPlanner` to naturally prioritize depots with shorter, cheaper paths.



---

### Framework 2: Attribute & Needs Modifier Pipeline (`res://framework/attributes/`)

#### Purpose & Scope

Provides pawns with internal biological, psychological, or mechanical parameters (e.g., `hunger`, `energy`, `health`, `morale`, `carry_capacity`) that decay over simulation ticks and are altered by stacking modifiers.

#### Domain Components & Single Authority

* **Registry:** `AttributeRegistry` (Single Authority over pawn attribute records).


* Internal storage: Dictionaries indexed by `pawn_id: int` storing base values, current values, and active modifiers.




* **Pipeline Evaluator:** `AttributePipeline`
* Pure calculation: $\text{Current} = (\text{Base} + \sum \text{FlatModifiers}) \times (1.0 + \sum \text{PercentModifiers})$.
* Implements `tick_decay(current_tick)` to decrement needs over time (e.g., hunger decays by $0.05$ per tick).





#### Command & Event Contracts

* Commands submitted to `CommandBus`:
* `&"APPLY_ATTRIBUTE_MODIFIER"`: `payload: {"pawn_id": int, "attribute": StringName, "modifier_id": StringName, "type": int, "value": float, "duration_ticks": int}`.


* `&"CONSUME_NEED_RESOURCE"`: `payload: {"pawn_id": int, "need": StringName, "replenish_amount": float}`.




* Events emitted to `EventBus`:
* `&"ATTRIBUTE_THRESHOLD_REACHED"`: `event_data: {"pawn_id": int, "attribute": StringName, "level": float, "severity": int}`.





#### GOAP & Simulation Integration

* **Perception Mapping:** `LogisticsStateMapper` queries `AttributeRegistry.get_value(pawn_id, &"energy")` and maps it into `GoapStateSnapshot.set_number(&"energy", value)`.


* **Survival Goals & Preemption:** `GoalSleep` or `GoalEat` monitors these numbers. When `energy < 15.0`, `GoalSleep`'s dynamic utility spikes, triggering `GoapGoalArbitrator` to preempt active work and dispatch the pawn to rest.



---

### Framework 3: Job Board & Task Allocation Broker (`res://framework/jobs/`)

#### Purpose & Scope

Decouples world-level operational demands from individual pawn AI. Instead of hardcoding which agent services which depot, the world issues job tickets (e.g., "Haul 20 Wood from (2,2) to (7,7)") and the broker matches jobs to eligible, idle agents based on proximity and capability.

#### Domain Components & Single Authority

* **Registry:** `JobBoardRegistry` (Single Authority over open, assigned, and completed jobs).


* Job Record: `job_id: int`, `job_type: StringName`, `priority: int`, `location: Vector2i`, `required_skills: Dictionary`, `claimant_id: int`.




* **Allocation Broker:** `JobBroker`
* Pure static matcher: `static func find_best_job(pawn_id: int, pawn_coord: Vector2i, traits: Dictionary, job_board: JobBoardRegistry, pathfinder: PathfindingGraphRegistry) -> int`.



#### Command & Event Contracts

* Commands submitted to `CommandBus`:
* `&"PUBLISH_JOB"`: `payload: {"job_type": StringName, "priority": int, "data": Dictionary}`.


* `&"CLAIM_JOB"`: `payload: {"job_id": int, "pawn_id": int}`.


* `&"COMPLETE_JOB"`: `payload: {"job_id": int, "pawn_id": int}`.


* `&"ABANDON_JOB"`: `payload: {"job_id": int, "pawn_id": int, "reason": StringName}`.




* Events emitted to `EventBus`:
* `&"JOB_CLAIMED"`, `&"JOB_COMPLETED"`, `&"JOB_ABANDONED"`.





#### GOAP & Simulation Integration

* **Generic GOAP Goal:** Replaces specific `GoalRestockCargo` with a dynamic `GoalExecuteJob`.
* **Dynamic Action Binding:** The agent polls the broker when idle, accepts a `job_id`, unpacks the job payload into its context, and the GOAP planner automatically resolves the required steps to complete the ticket.



---

### Framework 4: Multi-Tier Production & Transformation Engine (`res://framework/production/`)

#### Purpose & Scope

Enables multi-step transformation of raw resources into refined goods (e.g., `Wood` $\to$ `Planks` $\to$ `Furniture`). Manages recipe registries, workstation occupancy, progress ticking, and worker crafting interactions.

#### Domain Components & Single Authority

* **Registry:** `ProductionRegistry` (Single Authority tracking active workbench operations, progress bars, and batch queues).


* **Static Database:** `RecipeCatalog` (Static definitions mapping input items, quantities, processing ticks, and output items).

#### Command & Event Contracts

* Commands submitted to `CommandBus`:
* `&"START_RECIPE_PROCESS"`: `payload: {"workstation_id": int, "recipe_id": StringName, "pawn_id": int}`.


* `&"TICK_WORKSTATION_CRAFT"`: `payload: {"workstation_id": int, "labor_points": float}`.


* `&"COLLECT_RECIPE_OUTPUT"`: `payload: {"workstation_id": int, "destination_id": int}`.




* Events emitted to `EventBus`:
* `&"PRODUCTION_CYCLE_COMPLETED"`: `event_data: {"workstation_id": int, "output_resource": StringName, "amount": int}`.





#### GOAP & Simulation Integration

* **Actions:** `ActionOperateWorkstation` (a multi-tick action requiring pawn presence at the workstation while submitting labor ticks).


* **Chained Dependencies:** `GoapPlanner` can form plans like:
1. `NavigateTo(LumberDepot)` $\to$ 2. `WithdrawCargo(Wood)` $\to$ 3. `NavigateTo(Sawmill)` $\to$ 4. `DepositCargo(Wood)` $\to$ 5. `OperateWorkstation(Sawmill)` $\to$ 6. `WithdrawCargo(Planks)` $\to$ 7. `DeliverCargo(ConstructionSite)`.





---

### Framework 5: Turn-Based Tactical Combat Resolver (`res://framework/combat/`)

#### Purpose & Scope

Provides deterministic, command-driven combat resolution without real-time physics. Supports Action Point (AP) turns, discrete line-of-sight (Bresenham raycasts), cover modifiers, and hit/mitigation calculations.

#### Domain Components & Single Authority

* **Registry:** `CombatEncounterRegistry` (Single Authority managing turn queue, active initiative, combatant AP, and status effects).


* **Stateless Resolver:** `CombatResolver`
* Pure calculation: `static func resolve_attack(attacker_stats: Dictionary, defender_stats: Dictionary, distance: int, cover_type: int) -> AttackOutcomeDTO`.





#### Command & Event Contracts

* Commands submitted to `CommandBus`:
* `&"DISPATCH_TACTICAL_ATTACK"`: `payload: {"attacker_id": int, "target_id": int, "weapon_id": int, "ap_cost": int}`.


* `&"USE_TACTICAL_COVER"`: `payload: {"combatant_id": int, "cell_coord": Vector2i}`.


* `&"END_COMBATANT_TURN"`: `payload: {"combatant_id": int}`.




* Events emitted to `EventBus`:
* `&"TACTICAL_DAMAGE_APPLIED"`: `event_data: {"target_id": int, "damage": float, "is_critical": bool}`.


* `&"COMBATANT_INCAPACITATED"`: `event_data: {"entity_id": int}`.





#### GOAP & Simulation Integration

* **Combat Actions:** `ActionTakeCover`, `ActionRangedStrike`, `ActionRetreatToSafety`.
* **Dynamic Preemption:** Hostile detection immediately triggers high-utility defensive or offensive goals, aborting mundane hauling or crafting routines via `GoapSequencer.tick()`.



---

## 4. Implementation Protocol for Each New Framework

To maintain architectural standards across the project, each framework must be added using the following 4-step cadence:

```
[Step 1: Data Contracts & Single Authority Registry]
  ├── Define canonical command schemas in res://docs/schemas/
  └── Implement authoritative Registry in res://framework/<domain>/ extending RefCounted

[Step 2: Stateless Evaluators & Query Helpers]
  ├── Implement pure, static calculators and resolvers
  └── Write comprehensive unit tests verifying zero-mutation logic

[Step 3: Concrete GOAP Extensions & Actions]
  ├── Implement GoapAction subclasses wrapping domain commands
  └── Add domain rules and goal definitions

[Step 4: Headless Integration & Presentation Harness]
  ├── Author headless test suite running complete multi-tick scenario
  └── Bind to test canvas/view scene for runtime visual observability

```

---

## 5. Mandatory AI Context Reminder Prompt Snippet

When initiating new tasks or prompts for AI collaborators (such as Jules), **always prepend or include this directive**:

```markdown
IMPORTANT CONTEXT & INVARIANTS:
1. Review and adhere strictly to `res://docs/architecture_constitution.md` and `res://docs/architecture_framework_roadmap.md`.
2. Core and Framework Immutability: Do NOT modify any file under `res://core/`, `res://simulation/`, or `res://framework/goap/`. These layers are FROZEN at Tier A.
3. CQS & Envelopes: All state changes must be submitted as canonical CommandPacket dictionaries (`command_id`, `priority`, `issuer_id`, `target_tick`, `payload`) to CommandBus. Never mutate registries directly.
4. Evaluator Purity: All standalone evaluators and mappers must declare their methods as `static func`.
5. Canonical Null Standard: Always use integer `0` for unassigned entities, unreserved locks, or empty cells.

```