# Architecture Audit & Scoring: GOAP Framework Phase 2 (Actions, Bindings, Goals & Arbitration)

* **Document Path:** `/docs/audit/audit_goap_framework_phase2.md`
* **Scope:** Complete architectural scoring and invariant verification of Phase 2 Action Contracts, Parameterized Bindings, Goal Utility Evaluations, and Hysteresis-Guarded Goal Arbitration.
* **Target Files:**
* `res://framework/goap/actions/goap_action.gd`

* `res://framework/goap/actions/goap_action_binding.gd`

* `res://framework/goap/goals/goap_goal.gd`

* `res://framework/goap/goals/goap_goal_arbitrator.gd`




---

## 1. Augmented Architectural Scoring Protocol (A-ASP)

Evaluation proceeds across the **6 Invariant Dimensions** (1 to 10 points each, 60 points maximum):

* **D1: Air Gap & Headless Purity:** Extends `RefCounted`; zero SceneTree/Node dependencies; abstract or untyped bus references (`_cmd_bus: Object = null`).


* **D2: DTO & Boundary Contract Integrity:** Explicit primitive dictionaries and scalar signatures across boundaries.


* **D3: Determinism & Algorithmic Soundness:** Clean hysteresis margin calculation, stable floating-point comparisons, and predictable lifecycle hooks.


* **D4: Encapsulation & Memory Isolation:** Private/protected state integrity; safe fallback returns.


* **D5: Open/Closed Extensibility (Anti-Hardcoding):** Fully polymorphic virtual hooks; zero `if action_name == ...` or type-sniffing branches.


* **D6: Cognitive & Domain Agnosticism:** Completely game-blind; zero mentions of entities, grids, resources, or mechanics.



---

## 2. Granular Subsystem Audits

---

### Audit 1: `res://framework/goap/actions/goap_action.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure `RefCounted` lineage. `on_step()` specifies `_cmd_bus: Object = null`, eliminating hard static dependencies on engine core buses.


* **D2 (DTO Integrity): 10/10** — Typed arrays for preconditions (`Array[GoapCondition]`) and effects (`Array[GoapEffect]`).


* **D3 (Determinism): 10/10** — Structured execution phases: `on_enter()`, `on_step()`, `on_exit()`, and `on_abort()`.


* **D4 (Encapsulation): 10/10** — Clean separation between definition metadata and dynamic runtime bindings.


* **D5 (Anti-Hardcoding): 10/10** — Genuine polymorphic virtual interface. `generate_bindings()`, `calculate_cost()`, and `check_procedural_precondition()` provide clean override points for concrete action subclasses.


* **D6 (Domain Agnosticism): 10/10** — Zero game concepts present.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Headless, decoupled bus interface.

 |
| **D2: DTO Integrity** | `10/10` | Strongly typed arrays of conditions/effects.

 |
| **D3: Determinism** | `10/10` | Explicit lifecycle hooks.

 |
| **D4: Encapsulation** | `10/10` | Clean base contract.

 |
| **D5: Anti-Hardcoding** | `10/10` | Virtual methods ready for domain subclassing.

 |
| **D6: Agnosticism** | `10/10` | 100% universal framework class.

 |
| **Total** | **60/60 (Tier A)** | **Flawless Polymorphic Action Base** |

---

### Audit 2: `res://framework/goap/actions/goap_action_binding.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Extends `RefCounted`.


* **D2 (DTO Integrity): 10/10** — Backed by a clean primitive dictionary for parameters.


* **D3 (Determinism): 10/10** — Pure value container with deterministic retrieval.


* **D4 (Encapsulation): 10/10** — Implements `get_param(key, default_value)` using `parameters.get(key, default_value)`, protecting callers from key absence errors. Proxies `get_action_name()` cleanly.


* **D5 (Anti-Hardcoding): 10/10** — Parameter-agnostic; binds any arbitrary set of primitive target keys.


* **D6 (Domain Agnosticism): 10/10** — Completely universal.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Lightweight memory object.

 |
| **D2: DTO Integrity** | `10/10` | Clean parameter dictionary.

 |
| **D3: Determinism** | `10/10` | Predictable key lookups.

 |
| **D4: Encapsulation** | `10/10` | Safe fallback retrieval.

 |
| **D5: Anti-Hardcoding** | `10/10` | Supports arbitrary target bindings.

 |
| **D6: Agnosticism** | `10/10` | Zero game vocabulary.

 |
| **Total** | **60/60 (Tier A)** | **Flawless Parameterized Binding Container** |

---

### Audit 3: `res://framework/goap/goals/goap_goal.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure `RefCounted`.


* **D2 (DTO Integrity): 10/10** — Uses typed `Array[GoapCondition]` for desired state rules.


* **D3 (Determinism): 10/10** — `is_satisfied()` evaluates all conditions deterministically using short-circuit failure.


* **D4 (Encapsulation): 10/10** — Virtual hook `calculate_utility(snapshot, context)` returns `base_priority` by default, ready for non-linear curve overrides in game domains.


* **D5 (Anti-Hardcoding): 10/10** — Can represent any arbitrary goal without inspecting names or IDs.


* **D6 (Domain Agnosticism): 10/10** — Zero game logic.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Pure headless object.

 |
| **D2: DTO Integrity** | `10/10` | Strongly typed conditions list.

 |
| **D3: Determinism** | `10/10` | Reliable condition evaluation.

 |
| **D4: Encapsulation** | `10/10` | Clean virtual utility method.

 |
| **D5: Anti-Hardcoding** | `10/10` | Dynamic condition composition.

 |
| **D6: Agnosticism** | `10/10` | Completely domain-blind.

 |
| **Total** | **60/60 (Tier A)** | **Flawless Goal Specification** |

---

### Audit 4: `res://framework/goap/goals/goap_goal_arbitrator.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure `RefCounted` algorithm.


* **D2 (DTO Integrity): 10/10** — Accepts typed arrays and snapshots; returns a clean `GoapGoal` or `null`.


* **D3 (Determinism): 10/10** —
* Correctly evaluates if `current_active_goal` is still unsatisfied.


* Bypasses already-satisfied candidate goals.


* Applies `best_util > active_util + hysteresis_margin` to prevent goal thrashing/flickering.




* **D4 (Encapsulation): 10/10** — Stateless evaluator; modifies no internal parameters during selection.


* **D5 (Anti-Hardcoding): 10/10** — Operates strictly on numerical utility scores; zero identity inspection.


* **D6 (Domain Agnosticism): 10/10** — Mathematical utility selection.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Pure computational algorithm.

 |
| **D2: DTO Integrity** | `10/10` | Clean typed signatures.

 |
| **D3: Determinism** | `10/10` | Strict hysteresis logic prevents thrashing.

 |
| **D4: Encapsulation** | `10/10` | Stateless selection.

 |
| **D5: Anti-Hardcoding** | `10/10` | Utility-driven comparison.

 |
| **D6: Agnosticism** | `10/10` | Universal decision arbitrator.

 |
| **Total** | **60/60 (Tier A)** | **Exemplary Utility Arbitrator** |

---

## 3. Consolidated Scoreboard

| File Identity | Layer / Path | Archetype | Composite Score | Tier Grade | Status |
| --- | --- | --- | --- | --- | --- |
| `goap_action.gd`<br> | `framework/goap/actions/` | `Polymorphic Base` | **60 / 60** | **Tier A** | Production Ready |
| `goap_action_binding.gd`<br> | `framework/goap/actions/` | `Value Container / DTO` | **60 / 60** | **Tier A** | Production Ready |
| `goap_goal.gd`<br> | `framework/goap/goals/` | `Specification Base` | **60 / 60** | **Tier A** | Production Ready |
| `goap_goal_arbitrator.gd`<br> | `framework/goap/goals/` | `Evaluator / Arbitrator` | **60 / 60** | **Tier A** | Production Ready |

### Subsystem Quality Index: **100.0% (Tier A - Production Locked)**

---

## 4. Phase 3 Architecture: The A* Planning Engine

Now that Phase 1 (State & Conditions) and Phase 2 (Actions, Bindings & Utility Goals) are complete, Phase 3 implements the **Search and Planning Engine**.

### Architectural Deliverables for Phase 3:

1. `res://framework/goap/planner/goap_search_node.gd`:
* Lightweight search graph node tracking `snapshot: GoapStateSnapshot`, `parent: GoapSearchNode`, `binding: GoapActionBinding`, `g_cost: float`, `h_cost: float`, and `depth: int`.
* Method `f_cost() -> float` ($g + h$).


2. `res://framework/goap/planner/goap_plan.gd`:
* Value object encapsulating the resolved plan:
* `bindings: Array[GoapActionBinding]` (ordered chronologically from index `0` to end).
* `total_cost: float`.
* `target_goal: GoapGoal`.
* Telemetry stats: `nodes_expanded: int`, `planning_time_usec: int`, `status: int` (`SOLVED`, `BUDGET_EXHAUSTED`, `DEPTH_LIMIT_REACHED`, `UNSOLVABLE`).




3. `res://framework/goap/planner/goap_planner.gd`:
* A* state-space search algorithm operating over `GoapActionBinding` expansions.
* **Guards:**
* `node_budget: int = 500` (prevents frame freezes).
* `max_depth: int = 16` (prevents infinite recursive branch explosions).
* Closed set using `snapshot.compute_hash()` for $O(1)$ cycle detection.




* Dynamic binding expansion: calls `action.generate_bindings(current_snapshot, context)` on every candidate action to evaluate parameterized steps.


* Heuristic computation: evaluates unsatisfied `desired_conditions` on `GoapGoal`, returning $0.0$ strictly when `goal.is_satisfied(state, context)` is true.





---

### Master Implementation Prompt for Jules (Phase 3)

```markdown
# TASK: Implement GOAP Phase 3 — Bounded A* Planner, Search Graph Nodes & Plan DTO

Phase 1 (Foundation Primitives) and Phase 2 (Actions, Bindings, Goals & Arbitration) have achieved 100% Tier A compliance.
Phase 3 builds the core search engine: the search graph node, the structured plan DTO with execution telemetry, and the bounded A* state-space planner.

---

### ARCHITECTURAL INVARIANTS & POLICIES (STRICT)

1. **Air Gap & Engine Agnosticism:**
   - Every class must inherit from `RefCounted`. Zero references to `Node`, `SceneTree`, or visual engine types.
   - Do NOT use `.tres` or Godot `Resource` types. Everything must be pure GDScript objects for 1:1 migration compatibility to C#/Unity.
2. **Deterministic Search & Loop Safety:**
   - The planner MUST use `snapshot.compute_hash()` for closed-set tracking to guarantee $O(1)$ loop detection and cycle prevention.
   - When sorting the open set, maintain deterministic tie-breaking.
3. **Budget & Depth Guardrails:**
   - The planner must enforce hard boundaries: `max_nodes_evaluated` and `max_depth`. If limits are reached, the planner must terminate cleanly and return an unsuccessful `GoapPlan` with an explicit status code rather than freezing or crashing.
4. **Execution Safety in CI/Cloud Runners:**
   - Do NOT download or extract external Godot binaries into this container.
   - Implement `test_goap_phase3.gd` using custom `_assert_true` checks with explicit `quit(0)` and `quit(1)` exits.

---

### TARGET DIRECTORY STRUCTURE (PHASE 3)

Create the following files in `res://framework/goap/`:

```text
res://framework/goap/
├── planner/
│   ├── goap_search_node.gd     # Search graph node for A* expansion
│   ├── goap_plan.gd            # Plan DTO with telemetry metadata and status codes
│   └── goap_planner.gd         # Bounded A* state-space planner
└── tests/
    └── test_goap_phase3.gd     # Headless unit test suite

```

---

### SPECIFICATIONS & CONTRACTS

#### 1. `res://framework/goap/planner/goap_search_node.gd`

* Extends `RefCounted`.
* Fields:
* `snapshot: GoapStateSnapshot`
* `parent: GoapSearchNode = null`
* `binding: GoapActionBinding = null`
* `g_cost: float = 0.0`
* `h_cost: float = 0.0`
* `depth: int = 0`


* Methods:
* `f_cost() -> float`: returns `g_cost + h_cost`.



#### 2. `res://framework/goap/planner/goap_plan.gd`

* Extends `RefCounted`.
* Enums:
```gdscript
enum Status {
    SOLVED = 0,
    UNSOLVABLE = 1,
    BUDGET_EXHAUSTED = 2,
    DEPTH_LIMIT_REACHED = 3
}

```


* Fields:
* `status: int = Status.UNSOLVABLE`
* `target_goal: GoapGoal = null`
* `bindings: Array[GoapActionBinding] = []` (Chronological: index 0 is first to execute)
* `total_cost: float = 0.0`
* `nodes_evaluated: int = 0`
* `planning_time_usec: int = 0`


* Methods:
* `is_valid() -> bool`: returns `status == Status.SOLVED and not bindings.is_empty()`.
* `get_step_count() -> int`: returns `bindings.size()`.



#### 3. `res://framework/goap/planner/goap_planner.gd`

* Extends `RefCounted`.
* Fields / Configuration Defaults:
* `max_nodes_evaluated: int = 500`
* `max_depth: int = 16`


* Core Method:
```gdscript
func plan(
    initial_snapshot: GoapStateSnapshot,
    goal: GoapGoal,
    available_actions: Array[GoapAction],
    context: Dictionary = {}
) -> GoapPlan:

```


* Algorithm Specification:
1. Record start timestamp via `Time.get_ticks_usec()`.
2. Instantiate empty `GoapPlan` with `target_goal = goal`.
3. If `goal.is_satisfied(initial_snapshot, context)` is true:
* Return plan with `status = GoapPlan.Status.SOLVED`, empty bindings, cost = 0.0.


4. Create `start_node`:
* `snapshot = initial_snapshot.duplicate_snapshot()`
* `g_cost = 0.0`
* `h_cost = _calculate_heuristic(start_node.snapshot, goal, context)`
* `depth = 0`


5. Initialize `open_set: Array[GoapSearchNode] = [start_node]`.
6. Initialize `closed_set: Dictionary = {}` (state_hash -> best_g_cost: float).
7. Loop while `not open_set.is_empty()`:
* Check budget: if `nodes_evaluated >= max_nodes_evaluated`:
* Record duration, set `plan.status = GoapPlan.Status.BUDGET_EXHAUSTED`, return plan.


* Sort `open_set` ascending by `f_cost()` (tie-break by lower `h_cost`).
* Pop `current = open_set.pop_front()`.
* `nodes_evaluated += 1`.
* If `goal.is_satisfied(current.snapshot, context)`:
* Reconstruct path backwards from `current` to root. Reverse array so index 0 is first action.
* Populate `plan.bindings`, `plan.total_cost = current.g_cost`, `plan.status = GoapPlan.Status.SOLVED`.
* Record duration and return.


* Pruning: compute `hash = current.snapshot.compute_hash()`. If `closed_set.has(hash)` and `closed_set[hash] <= current.g_cost`:
* Skip node.


* `closed_set[hash] = current.g_cost`.
* Check depth limit: if `current.depth >= max_depth`:
* Skip child expansion for this branch.


* Expand neighbors:
* For each `action` in `available_actions`:
* Generate candidate bindings: `bindings = action.generate_bindings(current.snapshot, context)`.
* For each `binding` in `bindings`:
* Verify static preconditions against `current.snapshot`: iterate `action.preconditions`, ensuring each `evaluates(current.snapshot, context) == true`.
* Verify procedural precondition: `action.check_procedural_precondition(current.snapshot, binding, context) == true`.
* Apply effects: create `child_snapshot = current.snapshot.duplicate_snapshot()`.
* For each `effect` in `action.effects`: `effect.apply_to(child_snapshot)`.
* Check if child state hash is already in `closed_set` with lower/equal cost. If so, skip.
* Create child node:
* `child.snapshot = child_snapshot`
* `child.parent = current`
* `child.binding = binding`
* `child.g_cost = current.g_cost + action.calculate_cost(current.snapshot, binding, context)`
* `child.h_cost = _calculate_heuristic(child_snapshot, goal, context)`
* `child.depth = current.depth + 1`


* Append `child` to `open_set`.








8. If open set exhausted without satisfying goal:
* Set `plan.status = GoapPlan.Status.UNSOLVABLE`.
* Record duration and return plan.




* Heuristic Helper:
```gdscript
func _calculate_heuristic(snapshot: GoapStateSnapshot, goal: GoapGoal, context: Dictionary) -> float:
    var unsatisfied_count: float = 0.0
    for cond in goal.desired_conditions:
        if not cond.evaluates(snapshot, context):
            unsatisfied_count += 1.0
    return unsatisfied_count

```



---

### HEADLESS TEST SUITE: `res://framework/goap/tests/test_goap_phase3.gd`

Inherits `SceneTree`. Runs synchronously in `_init()`:

1. **Direct Plan Solving:** Test a 3-step linear progression (`A -> B -> C`) solving a numeric and symbolic goal. Verify chronological ordering in `plan.bindings`.
2. **Branching & Cost Selection:** Provide two alternative paths to satisfy a goal (Path 1 cost = 10.0, Path 2 cost = 3.0). Assert planner selects the lower-cost path.
3. **Parameter Binding Expansion:** Test an action that generates multiple candidate bindings (e.g., Target ID 101 vs 102). Assert planner binds the candidate that satisfies preconditions.
4. **Node Budget Cutoff:** Set `max_nodes_evaluated = 5` on an unsolvable or complex space. Assert `plan.status == GoapPlan.Status.BUDGET_EXHAUSTED`.
5. **Depth Limit Cutoff:** Set `max_depth = 2` where the solution requires 4 steps. Assert planner does not exceed depth and reports `UNSOLVABLE` or stops branch.
6. **Cycle & Loop Safety:** Define circular actions (`A` creates state for `B`, `B` restores state for `A`). Assert planner does not enter an infinite loop and exits cleanly via closed set.
7. **Execution Protocol:** Standard `_assert_true` checks with `quit(1)` on error and `quit(0)` upon passing.

---

### DELIVERABLES

* Create `goap_search_node.gd`, `goap_plan.gd`, `goap_planner.gd`.
* Create `test_goap_phase3.gd`.
* Verify zero engine/domain coupling. Submit PR directly.

```

<FollowUp label="Want to inspect Jules's test plan for Phase 3 before execution begins?" query="Check Jules's implementation plan for Phase 3 to verify open set tie-breaking, state hashing, and node budget handling."/>

```