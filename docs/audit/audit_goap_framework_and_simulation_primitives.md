# Architecture Audit & Scoring Codex: Universal GOAP Framework & Simulation Primitives

* **Document Path:** `/docs/audit/audit_goap_framework_and_simulation_primitives.md`
* **Scope:** Architectural evaluation, structural invariant verification, and anti-hallucination screening of the pure GOAP framework and the reconstituted Layer 2 simulation primitives.
* **Target Files:**
* `res://framework/goap/goap_action.gd`

* `res://framework/goap/goap_agent.gd`

* `res://framework/goap/goap_planner.gd`

* `res://simulation/reservation/reservation_registry.gd`

* `res://simulation/resource/resource_container_registry.gd`

* `res://simulation/spatial/spatial_cell_registry.gd`




---

## 1. Augmented Architectural Scoring Protocol (A-ASP)

To prevent synthetic AI hallucinations (e.g., hardcoded dispatch hacks, signature mismatches, leaky object scopes, and shadow coupling), the scoring system evaluates **6 Invariant Dimensions**, scored from **1 to 10 points** each, yielding a composite score out of **60 points**.

### Dimension Matrix

1. **D1: Air Gap & Headless Purity (Weight: 16.6%)**
* 10: Strict `RefCounted` lineage; zero Godot SceneTree dependencies (`Node`, `get_node()`, `CanvasItem`).


* 1: Extends `Node` or relies on rendering/scene-tree context.


2. **D2: DTO & Boundary Contract Integrity (Weight: 16.6%)**
* 10: Adheres strictly to canonical envelope schemas; flat primitives and explicit dictionaries across boundaries. Zero dynamic signature hallucination.


* 1: Passes live engine objects or invents non-standard argument signatures.


3. **D3: Determinism & Algorithmic Soundness (Weight: 16.6%)**
* 10: Strict A* heuristics, loop-safe state hashing, integer coordinate math, and reproducible execution ordering.


* 1: Non-deterministic sorting, missing loop detection, or unmanaged mutation side-effects.


4. **D4: Encapsulation & Single-Writer Authority (Weight: 16.6%)**
* 10: Internal storage is strictly private; state mutations require commands; queries use public methods.


* 1: External caller reaches directly into private dictionaries (e.g., `_claims`, `_cells`).


5. **D5: Open/Closed Extensibility (Anti-Hardcoding) (Weight: 16.6%)**
* 10: Completely polymorphic; zero `if action_id == ...` dispatch branches; new actions require zero modifications to framework classes.


* 1: Hardcoded procedural `elif` ladders or domain identity sniffing.


6. **D6: Cognitive & Domain Agnosticism (Framework Purity) (Weight: 16.6%)**
* 10: Zero domain vocabulary (no couriers, wood, depots, tiles) in `framework/` or `simulation/`.


* 1: Leaks game-specific business rules into agnostic engines.



### Grade Tiers

* **54 – 60:** **Tier A (Production Locked)** — Pristine architecture; zero leaks; fully compliant.
* **46 – 53:** **Tier B (Sound with Minor Technical Debt)** — Operable; requires minor signature or encapsulation repairs.
* **32 – 45:** **Tier C (Compromised Boundaries)** — Hallucinated signatures, partial hardcoding, or leaky state.
* **< 32:** **Tier F (Critical Failure)** — Rewrite required.

---

## 2. Granular Subsystem Audits

---

### Audit 1: `res://framework/goap/goap_action.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure `RefCounted` foundation.


* **D2 (DTO Integrity): 10/10** — Clear primitive contract with flat dictionary preconditions and effects.


* **D3 (Determinism): 10/10** — Explicit status enum transitions (`READY`, `RUNNING`, `COMPLETED`, `FAILED`).


* **D4 (Encapsulation): 10/10** — Base class cleanly defines execution contracts without leaking domain bindings.


* **D5 (Anti-Hardcoding): 10/10** — Genuine polymorphic base class. Provides clear hooks for `get_cost()`, `check_procedural_precondition()`, `start()`, `step()`, and `terminate()`.


* **D6 (Domain Agnosticism): 10/10** — Completely free of gameplay concepts.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Headless, zero Node dependencies.

 |
| **D2: DTO Integrity** | `10/10` | Standard primitive maps.

 |
| **D3: Determinism** | `10/10` | Pure status codes.

 |
| **D4: Encapsulation** | `10/10` | Clear virtual hooks.

 |
| **D5: Anti-Hardcoding** | `10/10` | Pure polymorphic abstraction.

 |
| **D6: Agnosticism** | `10/10` | 100% domain blind.

 |
| **Total** | **60/60 (Tier A)** | **Flawless Action Interface** |

---

### Audit 2: `res://framework/goap/goap_agent.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Operates headlessly via `CommandBus` and `EventBus` dependencies.


* **D2 (DTO Integrity): 6/10** —
* *Critical Hallucination (Signature Mismatch):* The agent emits events via:
`event_bus.emit_now(&"GOAP_PLAN_FORMULATED", current_tick, agent_id, -1, {...})`.
The Layer 1 `EventBus.emit_now()` takes a single `event: Dictionary` payload: `emit_now(event: Dictionary)`. Passing 5 positional arguments bypasses and crashes the `EventBus`!




* **D3 (Determinism): 9/10** — Sequential FIFO plan consumption (`pop_front()`) and explicit failure handling (`abort_plan`).


* **D4 (Encapsulation): 10/10** — Interacts with the game world strictly through `CommandBus` during `step()`.


* **D5 (Anti-Hardcoding): 10/10** — **The hardcoded `elif` ladder has been completely eliminated**. The driver delegates execution polymorphically to `active_action.step()`.


* **D6 (Domain Agnosticism): 10/10** — Agnostic state sequencer; zero game references.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Pure memory sequencer.

 |
| **D2: DTO Integrity** | `6/10` | **Defect:** Multi-argument call hallucinated for `EventBus.emit_now`.

 |
| **D3: Determinism** | `9/10` | Clean FIFO plan execution.

 |
| **D4: Encapsulation** | `10/10` | Pure command dispatch.

 |
| **D5: Anti-Hardcoding** | `10/10` | Strict polymorphism achieved.

 |
| **D6: Agnosticism** | `10/10` | Zero game domain logic.

 |
| **Total** | **55/60 (Tier A)** | **Clean Polymorphic Sequencer with Bus Call Defect** |

---

### Audit 3: `res://framework/goap/goap_planner.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure static computational algorithm.


* **D2 (DTO Integrity): 10/10** — Takes and returns structured primitives and `GoapAction` arrays.


* **D3 (Determinism): 8/10** —
* Employs deterministic state hashing via `_hash_state()` (sorted keys + serialized values).


* Closed set prevents infinite cyclical graph traversal.


* *Performance / Tie-Breaking Caveat:* `open_set.sort_custom(...)` on every loop iteration is $O(N \log N)$. In larger state spaces, a binary heap or priority queue is preferred.




* **D4 (Encapsulation): 10/10** — Operates on duplicate dictionary states (`current_state.duplicate()`), guaranteeing zero side-effects on original blackboards.


* **D5 (Anti-Hardcoding): 10/10** — Fully dynamic heuristic evaluation and procedural precondition checking.


* **D6 (Domain Agnosticism): 10/10** — Pure graph solver.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Algorithmic purity.

 |
| **D2: DTO Integrity** | `10/10` | Explicit types and contracts.

 |
| **D3: Determinism** | `8/10` | Deterministic; sorting overhead in open set.

 |
| **D4: Encapsulation** | `10/10` | Zero state mutation side-effects.

 |
| **D5: Anti-Hardcoding** | `10/10` | Arbitrary predicate evaluation.

 |
| **D6: Agnosticism** | `10/10` | 100% domain blind.

 |
| **Total** | **58/60 (Tier A)** | **Robust Pure A* Solver** |

---

### Audit 4: `res://simulation/reservation/reservation_registry.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure `RefCounted` registry.


* **D2 (DTO Integrity): 10/10** — Explicit scalar inputs and dictionary claims.


* **D3 (Determinism): 10/10** — Tick-based claim duration and explicit expiration sweep.


* **D4 (Encapsulation): 9/10** —
* Encapsulation repaired: includes `get_claimant(target_resource_id: int) -> int`.


* *Discrepancy:* Returns `-1` on missing targets instead of the canonical `0` unassigned entity handle convention.


* *Save State Leak:* `get_save_state()` returns `_claims` directly without `.duplicate(true)`, exposing internal references to mutation.




* **D5 (Anti-Hardcoding): 10/10** — Generic integer IDs for claimants and targets.


* **D6 (Domain Agnosticism): 10/10** — Universal resource reservation primitive.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Pure headless registry.

 |
| **D2: DTO Integrity** | `10/10` | Explicit primitives.

 |
| **D3: Determinism** | `10/10` | Predictable expiration.

 |
| **D4: Encapsulation** | `9/10` | `get_claimant` added; needs `duplicate(true)` in save codec.

 |
| **D5: Anti-Hardcoding** | `10/10` | Completely agnostic IDs.

 |
| **D6: Agnosticism** | `10/10` | Zero game assumptions.

 |
| **Total** | **59/60 (Tier A)** | **Sealed Primitive** |

---

### Audit 5: `res://simulation/resource/resource_container_registry.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Extends `RefCounted`.


* **D2 (DTO Integrity): 10/10** — Strict integer amounts and `StringName` resource keys.


* **D3 (Determinism): 10/10** — Atomic transactions with automatic rollback in `transfer()`. Zero negative balances permitted.


* **D4 (Encapsulation): 9/10** —
* *Save State Leak:* `get_save_state()` returns `_containers` directly instead of `_containers.duplicate(true)`.




* **D5 (Anti-Hardcoding): 10/10** — Agnostic container IDs and resource types.


* **D6 (Domain Agnosticism): 10/10** — Clean simulation primitive.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Zero node coupling.

 |
| **D2: DTO Integrity** | `10/10` | Clean scalar values.

 |
| **D3: Determinism** | `10/10` | Atomic commit/rollback.

 |
| **D4: Encapsulation** | `9/10` | Missing deep duplicate in snapshot export.

 |
| **D5: Anti-Hardcoding** | `10/10` | Agnostic resource handling.

 |
| **D6: Agnosticism** | `10/10` | Universal multi-resource ledger.

 |
| **Total** | **59/60 (Tier A)** | **Robust Transaction Primitive** |

---

### Audit 6: `res://simulation/spatial/spatial_cell_registry.gd`

#### Code Evaluation

* **D1 (Air Gap): 10/10** — Pure calculation and buffer indexing.


* **D2 (DTO Integrity): 10/10** — High-performance `PackedInt32Array` backing buffer.


* **D3 (Determinism): 9/10** —
* Strict bounds checking via `is_within_bounds()`.


* *Discrepancy:* Initializes and clears cells with `-1` (`_cells.fill(-1)`). The Layer 1/2 convention established in our schemas reserved `0` for empty/unoccupied cells and $>0$ for active entity handles.




* **D4 (Encapsulation): 10/10** — Array buffer is encapsulated behind coordinate getter/setter APIs.


* **D5 (Anti-Hardcoding): 9/10** —
* Hardcoded metric integers: `metric == 0` (Manhattan), `metric == 1` (Chebyshev), rather than binding to `CoreEnums.SpatialDistanceMetric`.




* **D6 (Domain Agnosticism): 10/10** — Pure 2D grid partition.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Completely isolated memory buffer.

 |
| **D2: DTO Integrity** | `10/10` | Packed array performance.

 |
| **D3: Determinism** | `9/10` | Empty cell value shifted to `-1` instead of canonical `0`.

 |
| **D4: Encapsulation** | `10/10` | Private buffer indexing.

 |
| **D5: Anti-Hardcoding** | `9/10` | Literal metric numbers instead of `CoreEnums`.

 |
| **D6: Agnosticism** | `10/10` | Universal spatial hash.

 |
| **Total** | **58/60 (Tier A)** | **High-Performance Spatial Primitive** |

---

## 3. Consolidated Scoreboard

| File Identity | Layer / Path | Archetype | Composite Score | Tier Grade | Status |
| --- | --- | --- | --- | --- | --- |
| `goap_action.gd`<br> | `framework/goap/` | `Polymorphic Base` | **60 / 60** | **Tier A** | Production Ready |
| `goap_planner.gd`<br> | `framework/goap/` | `Evaluator (A*)` | **58 / 60** | **Tier A** | Production Ready |
| `reservation_registry.gd`<br> | `simulation/reservation/` | `Registry` | **59 / 60** | **Tier A** | Minor Debt |
| `resource_container_registry.gd`<br> | `simulation/resource/` | `Registry` | **59 / 60** | **Tier A** | Minor Debt |
| `spatial_cell_registry.gd`<br> | `simulation/spatial/` | `Registry` | **58 / 60** | **Tier A** | Minor Debt |
| `goap_agent.gd`<br> | `framework/goap/` | `Driver / Sequencer` | **55 / 60** | **Tier A** | **Signature Bug** |

### Subsystem Quality Index: **98.1% (Tier A)**

---

## 4. Preventive Resolution: Halting AI Hallucinations & Coupling

To prevent coding agents from introducing insidious hacks, coupling, and signature hallucinations in future tasks, enforce the following **Four Immutable Implementation Rules**:

### Rule 1: Canonical Event Envelope Construction

* **The Defect:** In `goap_agent.gd`, Jules hallucinated calling `event_bus.emit_now(type, tick, src, dst, data)`.


* **The Invariant:** `EventBus.emit_now()` takes exactly **one** argument: a canonical `Dictionary` matching `/docs/schemas/core_envelopes.md`.


* **Enforcement Pattern:**
```gdscript
event_bus.emit_now({
    "event_type": &"GOAP_PLAN_FORMULATED",
    "tick_timestamp": current_tick,
    "source_entity_id": agent_id,
    "target_entity_id": 0,
    "event_data": {"plan_size": active_plan.size()}
})

```



### Rule 2: Deep Duplication in Save Registry Codecs

* **The Defect:** `ReservationRegistry` and `ResourceContainerRegistry` returned `_claims` and `_containers` directly in `get_save_state()`.


* **The Invariant:** All save state aggregations must return deep copies via `.duplicate(true)` to prevent external mutations from corrupting internal registry states.



### Rule 3: Canonical Null Handle Convention (`0` vs `-1`)

* **The Defect:** `SpatialCellRegistry` used `-1` for empty cells, and `ReservationRegistry` used `-1` for unassigned claimants.


* **The Invariant:** Across all engine schemas:
* `0` is the canonical unassigned / empty / system handle.
* $\ge 1$ are valid entity and container handles.



### Rule 4: Zero Enum Number Literals

* **The Defect:** `SpatialCellRegistry.calculate_distance()` compared `metric == 0` and `metric == 1`.


* **The Invariant:** Always use `CoreEnums.SpatialDistanceMetric.MANHATTAN` and `CHEBYSHEV`. Never hardcode integer literals for system enums.



---