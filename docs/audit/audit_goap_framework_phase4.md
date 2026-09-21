# Architecture Audit & Scoring: GOAP Framework Phase 4 (Sequencer & Execution Lifecycle)

* **Document Path:** `/docs/audit/audit_goap_framework_phase4.md`
* **Scope:** Execution lifecycle, dynamic preemption, multi-tick action stepping, untyped bus decoupling, and event payload conformance.
* **Target File:**
* `res://framework/goap/sequencer/goap_sequencer.gd`




---

## 1. Augmented Architectural Scoring Protocol (A-ASP)

Evaluation proceeds across the **6 Invariant Dimensions** (1 to 10 points each, 60 points maximum):

* **D1: Air Gap & Headless Purity:** Extends `RefCounted`; zero SceneTree/Node dependencies; untyped bus signatures (`command_bus: Object = null`, `event_bus: Object = null`).


* **D2: DTO & Boundary Contract Integrity:** Single canonical dictionary payload passed to `event_bus.emit_now()`; maps `target_id` safely into `target_entity_id` while isolating `event_data`.


* **D3: Determinism & Algorithmic Soundness:** Deterministic state machine ordering: Arbitration $\to$ Preemption $\to$ Formulation $\to$ Procedural Validation $\to$ Stepping $\to$ Goal Completion.


* **D4: Encapsulation & Memory Isolation:** Lifecycle hooks (`on_enter`, `on_step`, `on_exit`, `on_abort`) invoked strictly in respective transition phases; external state snapshots remain untouched.


* **D5: Open/Closed Extensibility (Anti-Hardcoding):** Completely polymorphic; zero `if action_name == ...` checks; arbitrary action sequences executed cleanly.


* **D6: Cognitive & Domain Agnosticism:** Completely game-blind; zero domain vocabulary.



---

## 2. Granular Code Audit: `goap_sequencer.gd`

* **D1 (Air Gap): 10/10** — Pure memory lifecycle driver extending `RefCounted`. Decoupled duck-typing for buses.


* **D2 (DTO Integrity): 10/10** — `_emit_event()` constructs the canonical 5-key `EventPayload` (`event_type`, `tick_timestamp`, `source_entity_id`, `target_entity_id`, `event_data`). Strips `target_id` from inner `event_data` to keep payloads clean.


* **D3 (Determinism): 10/10** —
* Correctly pre-empts active running actions with `on_abort()` when an arbitrator selects a higher utility goal.


* Respects multi-tick actions via `GoapTypes.ActionStatus.RUNNING`.


* Checks procedural preconditions right before action start, triggering immediate abort and replan on environmental drift.




* **D4 (Encapsulation): 10/10** — Manages internal plan pointers (`active_plan`, `active_binding`, `current_binding_index`) cleanly without exposing them to external mutation.


* **D5 (Anti-Hardcoding): 10/10** — Full polymorphic action stepping.


* **D6 (Domain Agnosticism): 10/10** — 100% domain-blind.



### Scorecard

| Dimension | Score | Finding |
| --- | --- | --- |
| **D1: Air Gap** | `10/10` | Decoupled headless execution.

 |
| **D2: DTO Integrity** | `10/10` | Strict single-envelope `EventBus` payloads.

 |
| **D3: Determinism** | `10/10` | Preemption, multi-tick stepping, and procedural guards verified.

 |
| **D4: Encapsulation** | `10/10` | Robust lifecycle transitions.

 |
| **D5: Anti-Hardcoding** | `10/10` | Pure polymorphic execution.

 |
| **D6: Agnosticism** | `10/10` | 100% engine/game-blind.

 |
| **Total** | **60/60 (Tier A)** | **Exemplary Sequencer Driver** |

---

## 3. Framework Completion Milestone

The agnostic framework in `res://framework/goap/` is complete and locked at Tier A compliance across all 4 phases:

1. **Phase 1:** `GoapTypes`, `GoapStateSnapshot`, `GoapNumericRule`, `GoapSymbolicRule`, `GoapNumericEffect`, `GoapSymbolicEffect`.


2. **Phase 2:** `GoapAction`, `GoapActionBinding`, `GoapGoal`, `GoapGoalArbitrator`.
3. **Phase 3:** `GoapSearchNode`, `GoapPlan`, `GoapPlanner`.


4. **Phase 4:** `GoapSequencer`.



`res://framework/goap/` is now frozen. We will not touch or modify this framework directory when implementing game features.

---

## 4. Next Phase: Concrete Game Domain & Logistics Feature

Now we move to `res://game/logistics/` to build the concrete feature logic for the Courier and Depots scenario.

### Architectural Structure for `res://game/logistics/`:

```text
res://game/logistics/
├── actions/
│   ├── action_navigate_to.gd       # Multi-tick grid traversal using SPATIAL_RELOCATION
│   ├── action_claim_depot.gd       # Reservation lock via RESERVATION_CLAIM
│   ├── action_withdraw_cargo.gd    # Depot-to-pawn cargo transfer via RESOURCE_TRANSFER
│   ├── action_deposit_cargo.gd     # Pawn-to-depot cargo transfer via RESOURCE_TRANSFER
│   └── action_release_depot.gd     # Unlocks depot via RESERVATION_RELEASE
│
├── evaluators/
│   ├── logistics_state_mapper.gd   # Reads simulation registries -> builds GoapStateSnapshot
│   └── target_depot_resolver.gd    # Resolves best supply and demand depots based on distance & stock
│
└── goals/
    ├── goal_deliver_cargo.gd       # Goal: cargo delivered to demand depot
    └── goal_restock_cargo.gd       # Goal: pawn restocked with cargo

```

Once these domain classes exist, we will wire them into `res://scenes/tests/logistics/logistics_test_view.tscn` to observe the courier executing autonomous GOAP plans.