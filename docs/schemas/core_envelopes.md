# Specification: Core Envelopes and Domain Payloads

* **Document Path:** `/docs/schemas/core_envelopes.md`
* **Layer:** Layer 1 (Universal Infrastructure Envelopes) & Layer 2 (Agnostic Domain Payloads)
* **Status:** Immutable Contract
* **Engine Compatibility:** Godot 4 (GDScript / C# Headless)

---

## 1. Architectural Invariants

1. **Flat Primitives Only:** All fields within envelopes and payloads must consist exclusively of standard primitives (`int`, `float`, `bool`, `StringName`, `Vector2i`, `Rect2i`) or contiguous flat arrays of primitives (`PackedInt32Array`, `PackedFloat32Array`).
2. **Zero Object References:** Passing object instances (`Object`, `Node`, `RefCounted`, `Resource`) across boundary interfaces via these payloads is strictly prohibited. Identity must be communicated through integer handles (`actor_id`, `entity_id`, `container_id`).
3. **Immutability After Construction:** Once instantiated and placed on an execution or broadcast queue, payloads must not be mutated. Handlers and workers must treat payload parameters as read-only.
4. **Deterministic Serialization:** Every envelope and payload defined in this specification must be natively serializable into a flat dictionary or binary blob without custom reflection or dynamic traversal.
5. **Static Core / Dynamic Extension Law:** Enums in this document are strictly for engine infrastructure and universal mechanics. Specific games or genres must not alter this file; domain-specific categories (e.g., Damage Types, Factions, Work Types) are registered at runtime via `StringName` tokens.

---

## 2. Core Enumerations Specification

Enums are split into two architectural tiers: Layer 1 (Universal System Primitives) and Layer 2 (Agnostic Domain Computation Types).

### Tier 1: Universal System Primitives (Layer 1)

```gdscript
## Standardized status codes returned by command validation and execution pipelines.
enum ExecutionStatusCode {
	# 0-9: Success States
	SUCCESS = 0,
	SUCCESS_NOOP = 1,                 ## Validated and executed, but resulted in zero state changes

	# 10-19: Framing & Protocol Failures
	REJECTED_INVALID_ENVELOPE = 10,   ## Malformed packet, illegal types, or schema mismatch
	REJECTED_STALE_TICK = 11,         ## Packet arrived after its scheduled execution tick
	REJECTED_RATE_LIMITED = 12,       ## Issuer exceeded maximum command throughput quota

	# 20-39: Domain Preconditions & Availability
	REJECTED_PRECONDITION = 20,       ## Custom domain assertion failed
	REJECTED_UNAUTHORIZED = 21,       ## Issuer lacks permissions to modify target state
	REJECTED_OUT_OF_BOUNDS = 22,      ## Coordinates or indices fall outside spatial partitions
	REJECTED_OUT_OF_RANGE = 23,       ## Metric distance check failed
	REJECTED_INSUFFICIENT_FUNDS = 24,  ## Lacks required numeric balance, stamina, or materials
	REJECTED_CAPACITY_FULL = 25,      ## Target container or cell cannot accept more items

	# 40-59: Concurrency, Locks & Identity
	REJECTED_TARGET_LOCKED = 40,      ## Target is held under an incompatible reservation claim
	ABORTED_TARGET_INVALID = 41,      ## Target handle or coordinate does not exist
	ABORTED_TARGET_DISPOSED = 42,     ## Target was destroyed or despawned during this tick
	ABORTED_ACTOR_INCAPACITATED = 43, ## Submitting actor is stunned, inactive, or dead

	# 60+: Catastrophic Engine Failures
	FAILED_INTERNAL_ERROR = 60        ## Unhandled algorithmic or engine-level exception
}

## Scheduling and arbitration priority for command queue processing.
enum ExecutionPriority {
	CRITICAL_SYSTEM = 0,   ## Engine kernel, clock synch, desync recovery
	STATE_CORRECTION = 1,  ## Rollback verification, forced server authority updates
	INPUT_DIRECT = 2,      ## Direct human player intent
	AGENT_DECISION = 3,    ## Autonomous AI agent choices
	DEFERRED_CLEANUP = 4   ## Garbage collection, buffer flushes, despawn passes
}

## Formal lifecycle states of entities in memory and simulation loops.
enum EntityLifecycleState {
	UNINITIALIZED = 0,     ## Allocated in memory pool; not active in world
	SPAWNING = 1,          ## State defined; waiting for tick start to enter world
	ACTIVE = 2,            ## Full participation in simulation ticks
	SUSPENDED = 3,         ## Hibernating (excluded from tick loops, retained in memory)
	DISPOSED = 4           ## Slated for destruction or returned to object pool
}

## Transactional mutation classification for replication, delta capture, and saves.
enum StateMutationType {
	CREATE = 0,            ## New entity or record instantiated
	UPDATE = 1,            ## Existing record completely replaced
	DELETE = 2,            ## Record destroyed or removed
	PATCH = 3              ## Partial delta applied to specific fields
}

```

---

### Tier 2: Agnostic Domain Computation Types (Layer 2)

```gdscript
## Mathematical formulas for applying numeric modifications to attributes.
enum AttributeOperationType {
	FLAT_ADDITION = 0,             ## current + delta
	PERCENTAGE_ADDITIVE = 1,       ## base * (1.0 + sum(additive_modifiers))
	PERCENTAGE_MULTIPLICATIVE = 2, ## current * delta_factor
	SET_OVERRIDE = 3,              ## Force-assigns absolute value, bypassing modifiers
	CLAMP_MIN_MAX = 4              ## Directly mutates lower or upper attribute bounds
}

## Mathematical distance formulas for spatial calculation and range queries.
enum SpatialDistanceMetric {
	MANHATTAN = 0,                 ## 4-directional grid: |dx| + |dy|
	CHEBYSHEV = 1,                 ## 8-directional grid with diagonals: max(|dx|, |dy|)
	EUCLIDEAN = 2,                 ## Continuous metric: sqrt(dx^2 + dy^2)
	HEXAGONAL = 3                  ## Axial/cube coordinate distance
}

## Mechanisms for spatial translation across cells or collections.
enum TraversalMode {
	DISCRETE_STEP = 0,             ## Single-cell transition adhering to SpatialDistanceMetric
	CONTINUOUS_VECTOR = 1,         ## Continuous directional vector movement over time
	INSTANT_TELEPORT = 2,          ## Immediate discontinuous spatial translation
	CONTAINER_TRANSFER = 3         ## Shift between logical collections (e.g., Deck to Hand)
}

## Access locks for entities, spatial cells, or workstations.
enum ReservationClaimType {
	EXCLUSIVE_WRITE = 0,           ## Exactly 1 actor; forbids all other reads and writes
	SHARED_READ = 1,               ## Multiple actors can read/interact; blocks EXCLUSIVE_WRITE
	PRIORITY_PREEMPT = 2           ## Forces cancellation and release of existing lower claims
}

## Explicit targeting shapes for actions, capabilities, and abilities.
enum TargetSelectionType {
	NONE = 0,                      ## Self-contained action requiring no target
	ENTITY = 1,                    ## Targets a specific entity handle
	COORDINATE = 2,                ## Targets a discrete 2D spatial coordinate
	VOLUME = 3,                    ## Targets an axis-aligned bounding area (Rect2i)
	CONTAINER = 4                  ## Targets a storage pool or inventory container
}

```

---

## 3. Universal Transport Envelopes (Layer 1)

### Envelope 1: `CommandPacket`

Encapsulates an unvalidated intent emitted by the presentation layer, input hardware, or agent AI.

| Field Name | Type | Description | Invariants |
| --- | --- | --- | --- |
| `command_id` | `int` | Sequential 64-bit transaction identifier. | $\ge 1$. Monotonically increasing. |
| `priority` | `ExecutionPriority` | Queue arbitration priority. | Valid `ExecutionPriority` enum value. |
| `command_type` | `StringName` | Explicit token for the destination domain pipeline. | Must match a registered validator hook. |
| `issuer_id` | `int` | Handle of the submitting actor, agent, or system. | `0` reserved for System / Engine Kernel. |
| `target_tick` | `int` | Simulation tick during which execution is requested. | Must be $\ge \text{current\_tick}$. |
| `payload` | `Dictionary` | Serialized domain payload struct. | Must conform to one of the 5 Domain Payloads. |

```gdscript
# Canonical Structure: CommandPacket
{
	"command_id": 1048576,
	"priority": ExecutionPriority.INPUT_DIRECT,
	"command_type": &"EXECUTE_INTERACTION",
	"issuer_id": 12,
	"target_tick": 450,
	"payload": {} # Concrete Domain Payload
}

```

---

### Envelope 2: `ExecutionResult`

The mandatory return contract produced by any command validation and execution pipeline.

| Field Name | Type | Description | Invariants |
| --- | --- | --- | --- |
| `command_id` | `int` | Echoes the `command_id` of the evaluated packet. | Must match source `CommandPacket.command_id`. |
| `status_code` | `ExecutionStatusCode` | Numeric outcome state of the transaction. | Valid `ExecutionStatusCode` enum value. |
| `reason_code` | `StringName` | Machine-readable identifier for diagnostics. | Must be `&"NONE"` on `SUCCESS` or `SUCCESS_NOOP`. |
| `mutated_entity_ids` | `PackedInt32Array` | Array of entity handles modified by this run. | Empty on rejection; populated on mutation. |

```gdscript
# Canonical Structure: ExecutionResult
{
	"command_id": 1048576,
	"status_code": ExecutionStatusCode.REJECTED_INSUFFICIENT_FUNDS,
	"reason_code": &"RESOURCE_SHORTAGE_WOOD",
	"mutated_entity_ids": PackedInt32Array()
}

```

---

### Envelope 3: `EventPayload`

An immutable notification emitted by a Single Authority *after* state mutation has officially committed.

| Field Name | Type | Description | Invariants |
| --- | --- | --- | --- |
| `event_type` | `StringName` | Canonical event name denoting what occurred. | Must be past-tense (e.g., `&"ENTITY_DAMAGED"`). |
| `mutation_type` | `StateMutationType` | Classification of the underlying mutation. | Valid `StateMutationType` enum value. |
| `tick_timestamp` | `int` | Simulation tick when mutation committed. | Must equal the emitting tick. |
| `source_entity_id` | `int` | Entity directly causing the event. | `0` if caused by environment/kernel. |
| `target_entity_id` | `int` | Entity directly impacted by the event. | `0` if not entity-specific (e.g., cell change). |
| `event_data` | `Dictionary` | Plain dictionary containing context details. | Flat types only. No class instances. |

```gdscript
# Canonical Structure: EventPayload
{
	"event_type": &"ATTRIBUTE_VALUE_COMMITTED",
	"mutation_type": StateMutationType.PATCH,
	"tick_timestamp": 450,
	"source_entity_id": 4,
	"target_entity_id": 12,
	"event_data": {
		"attribute_id": &"HEALTH",
		"previous_value": 100.0,
		"current_value": 85.0
	}
}

```

---

### Envelope 4: `StateSnapshotDelta`

The read-only update emitted from Layer 3 (Simulation) down to Layer 2 (View) at the end of each tick.

| Field Name | Type | Description | Invariants |
| --- | --- | --- | --- |
| `tick_id` | `int` | Simulation tick corresponding to this slice. | Must strictly equal `current_tick`. |
| `entity_transforms` | `Array[Dictionary]` | Visual transform records for entities. | Max 1 entry per active entity. |
| `dirty_cells` | `Array[Dictionary]` | Cell coordinate records changed this tick. | Contains only cells marked dirty this tick. |
| `visual_cues` | `Array[Dictionary]` | Ephemeral triggers (audio, particle hits). | Cleared immediately after render consumption. |

```gdscript
# Canonical Structure: StateSnapshotDelta
{
	"tick_id": 450,
	"entity_transforms": [
		{
			"entity_id": 12,
			"world_coord": Vector2i(14, 28),
			"visual_state_id": 1, # 0=Idle, 1=Walk, 2=Work, etc.
			"orientation_degrees": 90.0
		}
	],
	"dirty_cells": [
		{
			"cell_coord": Vector2i(14, 28),
			"terrain_id": 3,
			"occupant_id": 12
		}
	],
	"visual_cues": [
		{
			"cue_type": &"AUDIO_ONE_SHOT_PLAY",
			"cue_id": &"STEP_GRASS",
			"cell_coord": Vector2i(14, 28)
		}
	]
}

```

---

## 4. Agnostic Domain Payloads (Layer 2)

### Payload 1: `SpatialRelocationPayload`

Used for spatial path steps, zone shifting, or moving entities between cells and containers.

```gdscript
{
	"entity_id": 12,                   # int: Handle of moving entity
	"origin_coord": Vector2i(14, 27),  # Vector2i: Starting cell position
	"destination_coord": Vector2i(14, 28), # Vector2i: Destination cell position
	"traversal_mode": TraversalMode.DISCRETE_STEP, # TraversalMode enum
	"metric": SpatialDistanceMetric.CHEBYSHEV      # SpatialDistanceMetric enum
}

```

* **Invariants:**
* If `traversal_mode == TraversalMode.DISCRETE_STEP`:
* If `metric == SpatialDistanceMetric.MANHATTAN`: $\vert{}x_1 - x_0\vert{} + \vert{}y_1 - y_0\vert{} \le 1$.
* If `metric == SpatialDistanceMetric.CHEBYSHEV`: $\max(\vert{}x_1 - x_0\vert{}, \vert{}y_1 - y_0\vert{}) \le 1$.


* `origin_coord` cannot equal `destination_coord` unless `traversal_mode == TraversalMode.CONTAINER_TRANSFER`.



---

### Payload 2: `AttributeDeltaPayload`

Used for numeric state adjustments (damage, stamina spend, resource decay, durability loss).

```gdscript
{
	"target_entity_id": 12,            # int: Target entity handle
	"attribute_id": &"HEALTH",         # StringName: Canonical attribute key
	"delta_value": -15.0,              # float: Raw signed adjustment
	"operation_type": AttributeOperationType.FLAT_ADDITION, # AttributeOperationType enum
	"source_cause_id": &"FIRE_EXPOSURE" # StringName: System tag denoting etiology
}

```

* **Invariants:**
* `delta_value` cannot be `NaN` or `INF`.
* If `operation_type == AttributeOperationType.PERCENTAGE_MULTIPLICATIVE`, `delta_value` must be $\ge 0.0$.



---

### Payload 3: `ResourceTransferPayload`

Used for atomic quantity transfers between containers, stockpiles, or inventory slots.

```gdscript
{
	"source_container_id": 8,          # int: Source storage entity handle
	"target_container_id": 12,         # int: Destination storage entity handle
	"resource_type_id": &"RAW_TIMBER", # StringName: Canonical item or resource key
	"quantity": 25                     # int: Number of units to shift
}

```

* **Invariants:**
* `quantity` must be $> 0$.
* `source_container_id` cannot equal `target_container_id`.



---

### Payload 4: `ReservationClaimPayload`

Used to claim temporary or persistent exclusivity locks over a cell, entity, or workstation.

```gdscript
{
	"claimant_id": 12,                 # int: Entity claiming the lock
	"target_resource_id": 104,         # int: Entity or Cell handle being locked
	"claim_type": ReservationClaimType.EXCLUSIVE_WRITE, # ReservationClaimType enum
	"expected_duration_ticks": 120     # int: Lifespan of lock in simulation ticks
}

```

* **Invariants:**
* `expected_duration_ticks` must be $> 0$.
* If `claim_type == ReservationClaimType.EXCLUSIVE_WRITE`, rejection occurs automatically if any other claim is active on `target_resource_id`.



---

### Payload 5: `ActionTriggerPayload`

Used to initiate an interaction, ability, spell, or manual state driver.

```gdscript
{
	"actor_id": 12,                    # int: Entity executing the action
	"action_definition_id": &"MINE_ORE", # StringName: Canonical ability/job token
	"target_type": TargetSelectionType.ENTITY, # TargetSelectionType enum
	"target_entity_id": 88,            # int: Target entity handle (if target_type == ENTITY)
	"target_coord": Vector2i(-1, -1),  # Vector2i: Target coordinate (if target_type == COORDINATE)
	"target_volume": Rect2i(0, 0, 0, 0), # Rect2i: Target area (if target_type == VOLUME)
	"target_container_id": 0           # int: Target storage handle (if target_type == CONTAINER)
}

```

* **Invariants:**
* Target data must align strictly with `target_type`:
* `ENTITY`: `target_entity_id > 0`.
* `COORDINATE`: `target_coord != Vector2i(-1, -1)`.
* `VOLUME`: `target_volume.size.x > 0` and `target_volume.size.y > 0`.
* `CONTAINER`: `target_container_id > 0`.
* `NONE`: all target parameters must remain zero/default.


* `actor_id` cannot equal `target_entity_id` unless the capability is explicitly flagged as self-targetable in static configuration.