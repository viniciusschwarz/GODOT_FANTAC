# Architecture Audit & Scoring Codex: Layer 1 Core Implementation

* **Document Path:** `/docs/audit/audit_layer1_core_scripts.md`
* **Scope:** Complete architectural evaluation of Layer 1 infrastructure scripts against locked specifications.
* **Target Files:**
* `res://core/schemas/core_enums.gd`

* `res://core/schemas/envelope_validator.gd`

* `res://core/time/sim_clock.gd`

* `res://core/command/command_bus.gd`

* `res://core/event/event_bus.gd`

* `res://core/save/save_registry.gd`




---

## 1. Architectural Scoring Protocol (ASP)

Each script is evaluated against **5 Invariant Dimensions**, scored from **1 to 10 points** each, yielding a composite score out of **50 points**.

### Dimension Matrix

1. **D1: Air Gap & Headless Independence (Weight: 20%)**
* 10: Zero SceneTree/Node types, zero engine lifecycle assumptions, completely runnable via `--headless` in pure memory.
* 1: Extends `Node`, uses `get_node()`, `get_tree()`, or interacts with visual presentation.


2. **D2: Structural Type Safety & DTO Integrity (Weight: 20%)**
* 10: Explicit scalar types, primitives only, zero live object leaks (`Object`, `RefCounted`, `Node`), pure dictionaries/packed arrays across boundaries.
* 1: Passes raw object references, loose untyped Variants, or dynamic reflection hacks.


3. **D3: Determinism & Execution Purity (Weight: 20%)**
* 10: Integer time/ticks, reproducible priority ordering, zero floating-point accumulation drift, single-writer authority.
* 1: Relies on non-deterministic iteration, wall-clock time in logic, or arbitrary state mutation.


4. **D4: Blast-Radius Containment & Opaque Payloads (Weight: 20%)**
* 10: Infrastructure handles envelopes without inspecting domain payloads; contracts extend additively.
* 1: Infrastructure inspects domain keys, causing system-wide cascading breakage upon domain changes.


5. **D5: Lexicon & Boundary Compliance (Weight: 20%)**
* 10: Strict adherence to approved suffixes, zero enterprise naming rot, complete adherence to schema contracts.
* 1: Introduces arbitrary manager/handler antipatterns or deviates from formal contracts.



### Grade Tiers

* **45 – 50:** **Tier A (Production Locked)** — Implements spec faithfully; zero leaks.
* **38 – 44:** **Tier B (Architecturally Sound with Minor Technical Debt)** — Fully functional; minor divergences in enum mappings or validation depth.
* **25 – 37:** **Tier C (Fragile / Compromised Boundary)** — Violates isolation or passes illegal references.
* **< 25:** **Tier F (Spaghetti Failure)** — Must be purged and rewritten.

---

## 2. Script-by-Script Detailed Audit

---

### Audit 1: `res://core/schemas/core_enums.gd`

#### Code Evaluation

* **D1 (Air Gap):** **10/10** — Pure `RefCounted` container containing only static enums. Zero engine dependencies.


* **D2 (Type Safety):** **9/10** — Enums map to contiguous integer values. Fully serializable across languages.


* **D3 (Determinism):** **10/10** — Values are explicit and fixed.


* **D4 (Containment):** **8/10** — Separates Tier 1 primitives from Tier 2 domain types cleanly.


* **D5 (Lexicon):** **8/10** — Class naming is clean.


* *Discrepancy:* In `ExecutionStatusCode`, Jules introduced non-standard values (`ACCEPTED = 1`, `REJECTED_STATE_MISMATCH = 23`, `ERROR_DOMAIN_CRASH = 43`) that deviated slightly from the exact mapping specified in `core_envelopes.md`.





#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Completely headless; zero node references.

 |
| **D2: Type Safety** | `9/10` | Static integers, safe for binary/json buffers.

 |
| **D3: Determinism** | `10/10` | Contiguous, zero ambiguity.

 |
| **D4: Blast-Radius** | `8/10` | Comprehensive coverage; two-tier architecture maintained.

 |
| **D5: Lexicon** | `8/10` | Minor deviation in `ExecutionStatusCode` names compared to spec.

 |
| **Total** | **45/50 (Tier A)** | **Clean Foundation** |

---

### Audit 2: `res://core/schemas/envelope_validator.gd`

#### Code Evaluation

* **D1 (Air Gap):** **10/10** — Operates headlessly using static functions and native Variant type inspection.


* **D2 (Type Safety):** **10/10** — Deep validation logic via `_contains_object()` scans nested arrays and dictionaries, mathematically ensuring zero `TYPE_OBJECT` instances leak into payloads.


* **D3 (Determinism):** **10/10** — Pure deterministic input validation.


* **D4 (Containment):** **9/10** — Focuses solely on the 6 universal envelope keys (`command_id`, `priority`, `command_type`, `issuer_id`, `target_tick`, `payload`) without peeking inside payload mechanics.


* **D5 (Lexicon):** **9/10** — Adheres to the approved kernel exceptions; single-responsibility verifier.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Zero SceneTree leakage.

 |
| **D2: Type Safety** | `10/10` | Recursive `_contains_object()` enforces the Air Gap at runtime.

 |
| **D3: Determinism** | `10/10` | Functional, zero side-effects.

 |
| **D4: Blast-Radius** | `9/10` | Validates envelope headers while keeping payload opaque.

 |
| **D5: Lexicon** | `9/10` | Follows standard naming exceptions cleanly.

 |
| **Total** | **48/50 (Tier A)** | **Exemplary Gatekeeper** |

---

### Audit 3: `res://core/time/sim_clock.gd`

#### Code Evaluation

* **D1 (Air Gap):** **10/10** — Contains no Godot timer nodes, frame delta callbacks, or engine lifecycle dependencies.


* **D2 (Type Safety):** **10/10** — All parameters, variables, and return values use explicit 64-bit integers (`int`).


* **D3 (Determinism):** **9/10** — Uses discrete integer microsecond accumulation (`accumulated_usec += delta_usec * speed_multiplier`). Includes a 10-tick clamp limit to prevent the "spiral of death" during frame rate drops.


* *Subtle Defect in `step_tick()`:* Calling `step_tick()` directly deducts `tick_step_usec` even if `advance_accumulator()` was not called or accumulated time was less than a full tick. In manual-step mode, `accumulated_usec` can drop into negative numbers.




* **D4 (Containment):** **10/10** — Completely oblivious to simulation content or domains.


* **D5 (Lexicon):** **9/10** — Simple, direct temporal sequencing driver.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Pure calculation; zero engine hooks.

 |
| **D2: Type Safety** | `10/10` | Completely typed with 64-bit integer values.

 |
| **D3: Determinism** | `9/10` | Minor accumulator underflow hazard if stepped manually.

 |
| **D4: Blast-Radius** | `10/10` | Universal time abstraction.

 |
| **D5: Lexicon** | `9/10` | Complies with core infrastructure rules.

 |
| **Total** | **48/50 (Tier A)** | **Robust Driver** |

---

### Audit 4: `res://core/command/command_bus.gd`

#### Code Evaluation

* **D1 (Air Gap):** **10/10** — Pure queuing and execution orchestration.


* **D2 (Type Safety):** **9/10** — Validates incoming envelopes via `EnvelopeValidator.is_valid_command()`.


* *Discrepancy:* `submit()` returns `CoreEnums.ExecutionStatusCode.ACCEPTED`, which was not part of the locked `ExecutionStatusCode` specification (should evaluate to `SUCCESS = 0`).




* **D3 (Determinism):** **10/10** — Flushes strictly through priority queues `0` to `4` (`ExecutionPriority.CRITICAL_SYSTEM` to `DEFERRED_CLEANUP`). Guarantees execution order determinism.


* **D4 (Containment):** **9/10** — Decoupled dispatching via `_validators` and `_executors` Callables. The bus knows nothing about movement, resources, or combat.


* **D5 (Lexicon):** **9/10** — Clean command routing; adheres to naming rules.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Zero SceneTree interaction.

 |
| **D2: Type Safety** | `9/10` | Uses `EnvelopeValidator` at the front door; minor status enum drift.

 |
| **D3: Determinism** | `10/10` | Strict priority array sweep enforces reproducible ordering.

 |
| **D4: Blast-Radius** | `9/10` | Pure Callable delegation protects bus from domain drift.

 |
| **D5: Lexicon** | `9/10` | Clean Buffer/Dispatcher pattern.

 |
| **Total** | **47/50 (Tier A)** | **High-Fidelity Transaction Pipe** |

---

### Audit 5: `res://core/event/event_bus.gd`

#### Code Evaluation

* **D1 (Air Gap):** **10/10** — Runs purely via dictionaries and Callables.


* **D2 (Type Safety):** **7/10** —
* *Critical Omission:* `emit_now()` and `enqueue()` **do not validate** the incoming `event: Dictionary` against an envelope validator before broadcasting. If a domain author emits an `EventPayload` containing an illegal `Node` or raw class pointer, the `EventBus` broadcasts it without rejection.




* **D3 (Determinism):** **9/10** — Duplicates the queue on `flush_queue()` to prevent mutation-during-iteration bugs.


* **D4 (Containment):** **10/10** — Pure point-to-multipoint publisher; zero awareness of domain identities.


* **D5 (Lexicon):** **9/10** — Adheres to Dispatcher archetype.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Clean, decoupled memory presence.

 |
| **D2: Type Safety** | `7/10` | Missing runtime envelope verification on emitted events.

 |
| **D3: Determinism** | `9/10` | Safe queue duplication pattern.

 |
| **D4: Blast-Radius** | `10/10` | Pure agnostic pub/sub.

 |
| **D5: Lexicon** | `9/10` | Follows kernel naming conventions.

 |
| **Total** | **45/50 (Tier A)** | **Solid Dispatcher with Validation Blindspot** |

---

### Audit 6: `res://core/save/save_registry.gd`

#### Code Evaluation

* **D1 (Air Gap):** **10/10** — No file system or node locks; produces and consumes pure dictionaries.


* **D2 (Type Safety):** **8/10** — Enforces `CURRENT_SCHEMA_VERSION` check on restoration. Does not scan returned domain dictionaries for live object references before bundling.


* **D3 (Determinism):** **9/10** — Iterates dictionaries cleanly; atomic rollback if a consumer returns `false` during restoration.


* **D4 (Containment):** **10/10** — The ultimate deep module. Agnostic domain provider callbacks ensure `SaveRegistry` never needs to know what a domain stores.


* **D5 (Lexicon):** **10/10** — Perfect match for the `Registry` archetype.



#### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Pure memory codec; zero node dependencies.

 |
| **D2: Type Safety** | `8/10` | Version checked; lacks deep object scan on domain return.

 |
| **D3: Determinism** | `9/10` | Safe restoration gating.

 |
| **D4: Blast-Radius** | `10/10` | Zero domain coupling; completely isolated by Callables.

 |
| **D5: Lexicon** | `10/10` | Impeccable Registry archetype.

 |
| **Total** | **47/50 (Tier A)** | **Ideal Aggregator Module** |

---

## 3. Consolidated Scoreboard & Ranking

| File Identity | Layer | Archetype | Composite Score | Tier Grade |
| --- | --- | --- | --- | --- |
| `envelope_validator.gd`<br> | Layer 1 | `Evaluator` | **48 / 50** | **Tier A** |
| `sim_clock.gd`<br> | Layer 1 | `Driver / Sequencer` | **48 / 50** | **Tier A** |
| `command_bus.gd`<br> | Layer 1 | `Buffer / Dispatcher` | **47 / 50** | **Tier A** |
| `save_registry.gd`<br> | Layer 1 | `Registry / Codec` | **47 / 50** | **Tier A** |
| `core_enums.gd`<br> | Layer 1/2 | `Specification` | **45 / 50** | **Tier A** |
| `event_bus.gd`<br> | Layer 1 | `Dispatcher` | **45 / 50** | **Tier A** |

### Overall Architecture Quality Index: **93.3% (Tier A)**

---

## 4. Architectural Synthesis & Direct Refactoring Orders

The Layer 1 infrastructure built by Jules achieved **Tier A across all systems**. The system executes headlessly without Godot SceneTree pollution, validates data packets dynamically, separates domain logic via opaque Callables, and serializes state without hardcoded schemas.

To maintain absolute structural purity before entering Layer 3 development, apply these **three targeted fixes**:

### Order 1: Add Event Envelope Validation to `EventBus`

* **Issue:** `EventBus.emit_now()` and `enqueue()` take arbitrary dictionaries without schema enforcement.


* **Correction:** Call `EnvelopeValidator.is_valid_event(event)` inside `emit_now()` and `enqueue()`. Reject malformed events or those containing `TYPE_OBJECT`.



### Order 2: Reconcile `ExecutionStatusCode` Enums

* **Issue:** `CommandBus.submit()` returns `CoreEnums.ExecutionStatusCode.ACCEPTED` (`1`), whereas the spec mandated `SUCCESS = 0` or `SUCCESS_NOOP = 1`.


* **Correction:** Align `core_enums.gd` and `command_bus.gd` back to the exact numerical mappings in `/docs/schemas/core_envelopes.md`.



### Order 3: Guard `SimClock.step_tick()` Underflow

* **Issue:** In manual stepping mode (e.g., debug step-by-step UI), calling `step_tick()` without prior accumulation drives `accumulated_usec` negative (`0 - 33333 = -33333`).


* **Correction:** Guard `accumulated_usec = maxi(0, accumulated_usec - tick_step_usec)`.