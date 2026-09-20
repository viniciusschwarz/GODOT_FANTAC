# Specification: Universal Data Transfer Objects & Domain Payloads

* **Document Path:** `/docs/specs/spec_dtos_and_payloads.md`
* **Architectural Layer:** Layer 1 (Universal Infrastructure) & Layer 2 (Agnostic Domain Payloads)
* **Status:** Locked Technical Specification
* **Target Runtimes:** Godot 4 (GDScript / C# Headless)

---

## 1. Scope & Architectural Mandate

This specification formalizes the exact data schemas, serialization contracts, and structural invariants for every Data Transfer Object (DTO) crossing system boundaries in the engine.

### Strict Enforcement Rules

1. **Zero Class/Node Instances:** Envelopes and payloads must never contain instances of `Node`, `Object`, `Resource`, or `RefCounted`. Identity must be expressed exclusively via integer handles (`int`) or canonical tokens (`StringName`).
2. **Immutable Boundary Crossing:** Once constructed and pushed to a buffer, dispatcher, or pipeline, an envelope is read-only. No system may alter parameters in-flight.
3. **Deterministic Memory Footprint:** All fields must map cleanly to flat primitives (`int`, `float`, `bool`, `StringName`, `Vector2i`, `Rect2i`) or contiguous flat arrays (`PackedInt32Array`, `PackedFloat32Array`).
4. **Execution Order Invariant:** Command submission, validation, execution, and state emission must execute as discrete, non-overlapping phases.

---

## 2. Core Enumerations Specification

Your intuition is spot-on. The list is **not enough** to serve as the global enum specification for an entire game engine.

However, the problem isn’t just that items are missing; it's a structural category error. The spec combined **Layer 1 universal transmission primitives** with **Layer 2 domain concepts**, while completely omitting several foundational lifecycle and transaction states that *every* system needs.

To make this axiomatic and complete, enums must be divided into **two distinct tiers**:

1. **Layer 1 Axiomatic Enums:** Structural primitives that govern execution flow, transactions, entity lifecycles, and serialization across *any* system.
2. **Layer 2 Agnostic Domain Enums:** Standard computational shapes (spatial, mathematical, resources, locks) that have room for extension.

Here is the complete, production-grade review and the expanded enumeration architecture.

---

### What Was Missing in the Previous List?

1. **Transaction & Lifecycle States:** How does the engine know if an entity is alive, dead, despawned, suspended, or uninitialized?
2. **Spatial Topology & Geometry:** Real 2D games use grids, hexes, or continuous points. The engine needs to know the coordinate metric (Manhattan, Chebyshev, Euclidean).
3. **Execution Priority & Ordering:** How does the `CommandBus` or scheduler decide which command runs first if two actions arrive on the same tick?
4. **Data Persistence & Mutation Modes:** How does the save/load system or state broker know whether an event is an insert, an update, a patch, or a hard deletion?

---

### Revised & Expanded Enumerations Specification

Here is the comprehensive specification, split cleanly into **Universal System Primitives** and **Domain Computation Types**.

---

### Tier 1: Universal System Primitives (Layer 1 - Absolute Axioms)

These never change, regardless of whether you're building a card game, a platformer, or a 4X strategy game.

#### 1. `ExecutionStatusCode` (Granular Pipeline Outcomes)

The previous 7 codes were too coarse. A command pipeline needs to distinguish between validation, capacity, permissions, and network/simulation desyncs:

```gdscript
enum ExecutionStatusCode {
    # 0-9: Success States
    SUCCESS = 0,
    SUCCESS_NOOP = 1,                 # Evaluated successfully, but resulted in zero state mutation

    # 10-19: Pipeline & Framing Errors
    REJECTED_INVALID_ENVELOPE = 10,   # Malformed packet, illegal types, or schema mismatch
    REJECTED_STALE_TICK = 11,         # Packet arrived too late for scheduled tick
    REJECTED_RATE_LIMITED = 12,       # Issuer exceeded transaction budget for tick

    # 20-39: Domain Preconditions & Availability
    REJECTED_PRECONDITION = 20,       # Custom domain rule failed
    REJECTED_UNAUTHORIZED = 21,       # Issuer lacks permission/authority to alter target
    REJECTED_OUT_OF_BOUNDS = 22,      # Coordinates or index fall outside defined space
    REJECTED_OUT_OF_RANGE = 23,       # Distance check failed
    REJECTED_INSUFFICIENT_FUNDS = 24,  # Lacks numeric balance, mana, or inventory count
    REJECTED_CAPACITY_FULL = 25,      # Container or grid cell cannot accept more items

    # 40-59: Concurrency & Identity
    REJECTED_TARGET_LOCKED = 40,      # Target resource held under incompatible reservation
    ABORTED_TARGET_INVALID = 41,      # Target ID does not exist
    ABORTED_TARGET_DISPOSED = 42,     # Target was killed, deleted, or despawned this tick
    ABORTED_ACTOR_INCAPACITATED = 43, # Submitting actor is stunned, dead, or inactive

    # 60+: Catastrophic
    FAILED_INTERNAL_ERROR = 60        # Uncaught exception or algorithmic assertion failure
}

```

#### 2. `ExecutionPriority` (Scheduler & Queue Arbitration)

When 20 commands arrive on tick 450, order matters. Determinism requires an explicit execution hierarchy:

```gdscript
enum ExecutionPriority {
    CRITICAL_SYSTEM = 0,   # Engine kernel, clock synch, disconnects
    STATE_CORRECTION = 1,  # Rollback frames, forced resets
    INPUT_DIRECT = 2,      # Player intent commands
    AGENT_DECISION = 3,    # Autonomous AI think choices
    DEFERRED_CLEANUP = 4   # Ephemeral despawns, corpse cleanup, buffer flushes
}

```

#### 3. `EntityLifecycleState` (State Existence Machine)

Replaces ad-hoc booleans like `is_dead` or `is_spawned`:

```gdscript
enum EntityLifecycleState {
    UNINITIALIZED = 0, # Allocated in memory pool, not yet active in simulation
    SPAWNING = 1,      # State initialized, waiting for tick start to enter world
    ACTIVE = 2,        # Full participation in simulation
    SUSPENDED = 3,     # Sleeping/hibernating (omitted from tick loops, preserved in memory)
    DISPOSED = 4       # Marked for destruction or return to memory pool
}

```

#### 4. `StateMutationType` (For Save/Load, Delta Snapshots & Sync)

Tells the save system, observer views, and network replication what kind of mutation occurred:

```gdscript
enum StateMutationType {
    CREATE = 0,  # New record or entity instantiated
    UPDATE = 1,  # Existing record modified
    DELETE = 2,  # Record removed
    PATCH = 3    # Partial field update (delta)
}

```

---

### Tier 2: Domain Computation Types (Layer 2 - Cross-Genre Agnostic)

These govern math, geometry, and resource mechanics.

#### 5. `AttributeOperationType` (Numeric Pipeline)

Expanded to cover caps and absolute assignments:

```gdscript
enum AttributeOperationType {
    FLAT_ADDITION = 0,             # current + delta
    PERCENTAGE_ADDITIVE = 1,       # base * (1.0 + sum(modifiers))
    PERCENTAGE_MULTIPLICATIVE = 2, # current * factor
    SET_OVERRIDE = 3,              # Force set absolute value (ignoring modifiers)
    CLAMP_MIN_MAX = 4              # Modifies lower or upper bounds of the attribute
}

```

#### 6. `SpatialDistanceMetric` (Geometry & Adjacency)

Decouples pathfinding and spatial rules from hardcoded tile logic:

```gdscript
enum SpatialDistanceMetric {
    MANHATTAN = 0,  # 4-directional grid: |dx| + |dy|
    CHEBYSHEV = 1,  # 8-directional grid (with diagonals): max(|dx|, |dy|)
    EUCLIDEAN = 2,  # Free continuous space: sqrt(dx^2 + dy^2)
    HEXAGONAL = 3   # Axial/cube hex grid coordinates
}

```

#### 7. `TraversalMode` (Spatial Relocation Mechanics)

```gdscript
enum TraversalMode {
    DISCRETE_STEP = 0,      # Single cell transition following current DistanceMetric
    CONTINUOUS_VECTOR = 1,  # Continuous sub-pixel/sub-unit movement over time
    INSTANT_TELEPORT = 2,   # Discontinuous spatial displacement
    CONTAINER_TRANSFER = 3  # Shift between non-spatial collections (Deck, Bag, Slot)
}

```

#### 8. `ReservationClaimType` (Concurrency Control)

```gdscript
enum ReservationClaimType {
    EXCLUSIVE_WRITE = 0, # Exactly 1 actor; forbids all other reads and writes
    SHARED_READ = 1,     # Multiple actors can read/interact; blocks EXCLUSIVE_WRITE
    PRIORITY_PREEMPT = 2 # High-priority claim that forces cancellation of existing claims
}

```

#### 9. `TargetSelectionType` (Addressing Shape)

Eliminates the hack of checking `target_entity_id > 0` vs `target_cell != Vector2i(-1, -1)`:

```gdscript
enum TargetSelectionType {
    NONE = 0,        # Self-contained action (no target)
    ENTITY = 1,      # Targets a specific entity handle
    COORDINATE = 2,  # Targets a discrete spatial point (Vector2i)
    VOLUME = 3,      # Targets an area/bounding box (Rect2i)
    CONTAINER = 4    # Targets an inventory or storage pool ID
}

```

---

### Architectural Rule for Extensibility

To ensure these enums never strangle a future game with unexpected mechanics, adopt this core rule:

> **The Static Core / Dynamic Extension Law:**
> * Enums defined in `core_enums.gd` are strictly for **engine infrastructure and universal mechanics**.
> * Specific games or genres **never add new entries to `core_enums.gd**`.
> * Domain-specific variants (e.g., Damage Types, Faction IDs, Recipe Types) are represented as runtime-registered **`StringName` tokens** or modular sub-framework enums declared in `domain_*/`.
> 
>
---

## 3. Universal Transport Envelopes (Layer 1)

Universal envelopes are domain-blind data frames that wrap all state transactions.

### 3.1 `CommandPacket` (State Mutation Intent)

Constructed by Presentation views, user input adapters, or autonomous agents to request a world mutation.

```
+-------------------------------------------------------------------------+
|                              CommandPacket                              |
+-------------------------------------------------------------------------+
| - command_id: int            (Unique monotonic 64-bit integer, >= 1)   |
| - command_type: StringName   (Explicit action key, e.g., &"EXECUTE")    |
| - issuer_id: int             (Entity/Player handle, 0 = System/Kernel)  |
| - target_tick: int           (Tick execution requested, >= current)     |
| - payload: Dictionary        (Domain Payload conforming to Section 4)   |
+-------------------------------------------------------------------------+

```

* **Validation Invariants:**
* `command_id` must monotonically increment; packets with duplicate IDs must be dropped.
* `target_tick` cannot be less than `SimClock.current_tick`.
* `payload` must contain only primitives. Any occurrence of `Object` causes instant envelope rejection.



### 3.2 `ExecutionResult` (Authoritative Outcome)

Generated by domain pipelines and returned to the caller or logging buffer upon command completion.

```
+-------------------------------------------------------------------------+
|                             ExecutionResult                             |
+-------------------------------------------------------------------------+
| - command_id: int                    (Matches triggering CommandPacket) |
| - status_code: ExecutionStatusCode   (0 to 6)                          |
| - reason_code: StringName            (&"NONE" if SUCCESS, else token)   |
| - mutated_entity_ids: PackedInt32Array (Handles of modified entities)  |
+-------------------------------------------------------------------------+

```

* **Validation Invariants:**
* If `status_code == ExecutionStatusCode.SUCCESS`, `reason_code` MUST equal `&"NONE"`.
* If `status_code != ExecutionStatusCode.SUCCESS`, `mutated_entity_ids.size()` MUST equal $0$.



### 3.3 `EventPayload` (State Modification Broadcast)

Emitted by the authoritative mutating domain via `EventBus` *after* state commit.

```
+-------------------------------------------------------------------------+
|                               EventPayload                              |
+-------------------------------------------------------------------------+
| - event_type: StringName      (Past-tense identifier, e.g., &"DAMAGED")|
| - tick_timestamp: int         (Simulation tick when mutation committed) |
| - source_entity_id: int       (Initiating entity handle, 0 = System)    |
| - target_entity_id: int       (Impacted entity handle, 0 = Global/None) |
| - event_data: Dictionary      (Flat context details: previous/new vals) |
+-------------------------------------------------------------------------+

```

* **Validation Invariants:**
* Must be dispatched strictly post-commit. Observers must never receive an event for a command that rolled back or failed.
* `event_data` must not contain mutable state pointers.



### 3.4 `StateSnapshotDelta` (Render/Sync Snapshot)

Emitted once per tick by Layer 3 down to Layer 2 (Godot Presentation).

```
+-------------------------------------------------------------------------+
|                            StateSnapshotDelta                           |
+-------------------------------------------------------------------------+
| - tick_id: int                         (Simulation tick of the slice)   |
| - entity_transforms: Array[Dictionary] (Array of TransformEntry)        |
| - dirty_cells: Array[Dictionary]       (Array of CellVisualEntry)       |
| - visual_cues: Array[Dictionary]       (Array of CueEntry)              |
+-------------------------------------------------------------------------+

```

* **Data Slices Definition:**
* `TransformEntry`: `{"entity_id": int, "world_coord": Vector2i, "visual_state_id": int, "orientation_degrees": float}`
* `CellVisualEntry`: `{"cell_coord": Vector2i, "terrain_id": int, "occupant_id": int}`
* `CueEntry`: `{"cue_type": StringName, "cue_id": StringName, "cell_coord": Vector2i}`



---

## 4. Agnostic Domain Payloads (Layer 2)

These five payloads are placed inside `CommandPacket.payload`. They describe the computational shapes of all game interactions across genres.

### 4.1 `SpatialRelocationPayload`

Models movement between coordinates or zones.

```gdscript
{
    "entity_id": int,                 # >= 1: Entity moving
    "origin_coord": Vector2i,         # Source cell coordinates
    "destination_coord": Vector2i,    # Target cell coordinates
    "traversal_mode": int             # 0=DISCRETE_STEP, 1=INSTANT_TELEPORT, 2=CONTAINER_TRANSFER
}

```

* **Boundary Invariants:**
* When `traversal_mode == 0 (DISCRETE_STEP)`:

$$\max(\vert{}x_{\text{dest}} - x_{\text{orig}}\vert{}, \vert{}y_{\text{dest}} - y_{\text{orig}}\vert{}) \le 1$$


* `origin_coord` cannot equal `destination_coord` unless `traversal_mode == 2`.



### 4.2 `AttributeDeltaPayload`

Models changes to numeric resources (e.g., durability, energy, health, points).

```gdscript
{
    "target_entity_id": int,          # >= 1: Entity receiving delta
    "attribute_id": StringName,       # Explicit token (e.g., &"HEALTH", &"STAMINA")
    "delta_value": float,             # Raw float adjustment (+ or -)
    "operation_type": int,            # 0=FLAT_ADDITION, 1=PERCENTAGE_ADDITIVE, 2=PERCENTAGE_MULTIPLICATIVE
    "source_cause_id": StringName     # Context tag (e.g., &"FIRE", &"FATIGUE")
}

```

* **Boundary Invariants:**
* `delta_value` must be a finite numerical value. `is_nan(delta_value)` and `is_inf(delta_value)` must evaluate to `false`.
* If `operation_type == 2 (MULTIPLICATIVE)`, `delta_value` must be $\ge 0.0$.



### 4.3 `ResourceTransferPayload`

Models atomic item, material, or token exchanges between storage pools.

```gdscript
{
    "source_container_id": int,       # >= 1: Source storage handle
    "target_container_id": int,       # >= 1: Destination storage handle
    "resource_type_id": StringName,   # Explicit token (e.g., &"WOOD", &"CARD_ID")
    "quantity": int                   # Number of units to transfer
}

```

* **Boundary Invariants:**
* `quantity` must be $> 0$. Zero or negative values are strictly prohibited.
* `source_container_id` cannot equal `target_container_id` (no identity transfers).



### 4.4 `ReservationClaimPayload`

Models temporal exclusive or shared access locks on entities, cells, or jobs.

```gdscript
{
    "claimant_id": int,               # >= 1: Entity asserting the lock
    "target_resource_id": int,        # >= 1: Entity or Cell handle being locked
    "claim_type": int,                # 0=EXCLUSIVE_WRITE, 1=SHARED_READ
    "expected_duration_ticks": int    # Lifespan of lock in ticks
}

```

* **Boundary Invariants:**
* `expected_duration_ticks` must be $> 0$.
* If a target resource holds an active `EXCLUSIVE_WRITE` claim, any incoming claim request on that target must be rejected automatically.



### 4.5 `ActionTriggerPayload`

Models invoking discrete skills, capabilities, or manual actions.

```gdscript
{
    "actor_id": int,                  # >= 1: Entity performing action
    "action_definition_id": StringName,# Capability identifier (e.g., &"HARVEST", &"STRIKE")
    "target_entity_id": int,          # Target entity handle (0 if cell-targeted)
    "target_cell": Vector2i           # Target cell (Vector2i(-1, -1) if entity-targeted)
}

```

* **Boundary Invariants:**
* **Strict Target Exclusivity:** Either `target_entity_id > 0` OR `target_cell != Vector2i(-1, -1)`. Supplying both or neither is an invalid state and must be rejected.
* `actor_id` cannot equal `target_entity_id` unless the capability is explicitly flagged as self-targetable in its static definition.



---

## 5. Direct Implementation Order for the Coding AI

To implement these DTOs cleanly without introducing architectural rot, the AI coder must follow this phased build sequence:

### Phase 1: Shared Enums Header

* **Path:** `res://core/schemas/core_enums.gd`
* **Content:** Pure enums definition file (`ExecutionStatusCode`, `AttributeOperationType`, `TraversalMode`, `ReservationClaimType`).
* **Constraints:** No class logic. No node inheritance. Pure `enum` declarations only.

### Phase 2: Static Envelope Factory & DTO Class

* **Path:** `res://core/schemas/core_envelopes.gd`
* **Content:** Typed factory methods that assemble valid dictionaries:
* `static func create_command_packet(...) -> Dictionary`
* `static func create_execution_result(...) -> Dictionary`
* `static func create_event_payload(...) -> Dictionary`
* `static func create_state_snapshot(...) -> Dictionary`


* **Constraints:** Methods take explicit typed arguments and return validated, standard dictionaries.

### Phase 3: Production Envelope Validator

* **Path:** `res://core/schemas/envelope_validator.gd`
* **Content:** Static, boolean validation methods with diagnostic output:
* `static func is_valid_command(packet: Dictionary) -> bool`
* `static func is_valid_payload(payload_type: StringName, payload: Dictionary) -> bool`


* **Constraints:** Pure functional methods. No persistent state. No dependencies outside `res://core/schemas/`.

### Phase 4: Integration Gate at `CommandBus`

* **Path:** `res://core/command/command_bus.gd`
* **Rule:** Inject `EnvelopeValidator.is_valid_command()` as Step 1 of `CommandBus.submit()`. Reject invalid envelopes before any domain logic evaluates.