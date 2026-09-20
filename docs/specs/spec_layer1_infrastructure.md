# Specification Codex: Layer 1 Universal Infrastructure

* **Document Path:** `/docs/specs/spec_layer1_infrastructure.md`
* **Architectural Layer:** Layer 1 (Universal Agnostic Plumbing)
* **Status:** Locked Technical Specification
* **Engine Compatibility:** Godot 4 (Headless / Zero Node Dependencies)

---

## 1. System Invariants & Scope

1. **Zero SceneTree Dependencies:** No class in Layer 1 extends `Node`, `Node2D`, or `Control`. All classes inherit from `RefCounted` or run as plain objects.
2. **Deterministic Discrete Time:** All simulation operations run on fixed integer ticks. Continuous time (`delta: float`) is isolated to visual interpolation in the Presentation layer.
3. **Opaque Payload Isolation:** Layer 1 systems manage transport, validation, scheduling, and serialization of envelopes without inspecting the contents of domain payloads.
4. **Direct Dependency Prohibition:** Layer 1 systems must never import or reference Layers 2, 3, or 4.

---

## 2. `SimClock` (Deterministic Temporal Sequencing)

* **Class Identity:** `SimClock` (`res://core/time/sim_clock.gd`)
* **Archetype:** `Driver` / `Sequencer`
* **Responsibility:** Manages discrete tick progression, fixed-rate accumulator loops, execution speeds ($1\times, 2\times, 5\times$), and pause states.

### State Layout

```gdscript
var current_tick: int = 0
var tick_rate_hz: int = 30                 # Logical steps per second
var tick_step_usec: int = 33333            # Precalculated: 1_000_000 / tick_rate_hz
var speed_multiplier: int = 1              # [0=Paused, 1=1x, 2=2x, 5=5x]
var accumulated_usec: int = 0
var is_locked: bool = false                # True during mid-tick pipeline resolution

```

### Public API Contract

```gdscript
## Advances the real-time microsecond accumulator. 
## Returns the exact number of logical ticks the simulation must execute this frame.
func advance_accumulator(delta_usec: int) -> int:
    pass

## Increments current_tick by 1. Enforces tick boundaries.
## Must only be called by the master engine loop once per discrete step.
func step_tick() -> int:
    pass

## Sets execution multiplier. 0 pauses the clock without clearing accumulator.
func set_speed(multiplier: int) -> void:
    pass

## Returns true if simulation is paused (multiplier == 0).
func is_paused() -> bool:
    pass

```

### Invariants & Prohibitions

* Must not use floating-point math for tick advancement. All accumulation uses 64-bit integer microseconds (`int`).
* Cannot drop ticks during frame-rate dips; enforces a maximum catch-up clamp (e.g., max 10 ticks per frame) to prevent a death spiral.

---

## 3. `CommandBus` (Transactional Intent Ingestion)

* **Class Identity:** `CommandBus` (`res://core/command/command_bus.gd`)
* **Archetype:** `Buffer` / `Dispatcher`
* **Responsibility:** Ingests unvalidated `CommandPacket` envelopes, orders them by priority, submits them to domain validators, and dispatches them for authoritative mutation.

### State Layout

```gdscript
# Array of dictionaries adhering to CommandPacket schema
var _staged_buffer: Array[Dictionary] = []
# Map of StringName -> Callable: func(packet: Dictionary) -> ExecutionResult
var _validator_hooks: Dictionary = {}
# Map of StringName -> Callable: func(packet: Dictionary) -> ExecutionResult
var _execution_hooks: Dictionary = {}

```

### Public API Contract

```gdscript
## Registers a domain validation hook and execution hook for a specific command_type.
func register_command_type(command_type: StringName, validator: Callable, executor: Callable) -> void:
    pass

## Enqueues a CommandPacket into the staged buffer.
## Rejects immediately if envelope schema or envelope types are malformed.
func submit(packet: Dictionary) -> Dictionary:
    pass

## Flushes and executes all staged commands for the target_tick in priority order.
## Returns an array of ExecutionResult dictionaries.
func flush_tick(target_tick: int) -> Array[Dictionary]:
    pass

```

### Invariants & Prohibitions

* Commands are processed in strict `ExecutionPriority` order (`CRITICAL_SYSTEM` $\rightarrow$ `DEFERRED_CLEANUP`).
* If a validator hook returns any status other than `SUCCESS` (0), the executor is never called.
* `CommandBus` cannot mutate domain data directly; execution logic is fully delegated through registered `Callables`.

---

## 4. `EventBus` (Decoupled State Change Broadcast)

* **Class Identity:** `EventBus` (`res://core/event/event_bus.gd`)
* **Archetype:** `Dispatcher`
* **Responsibility:** Point-to-multipoint notification hub. Ingests immutable `EventPayload` envelopes from Domain Authorities and delivers them to observers without caller/receiver coupling.

### State Layout

```gdscript
# Map of StringName (event_type) -> Array[Callable]
var _listeners: Dictionary = {}
# Ephemeral queue for deferred event delivery
var _queued_events: Array[Dictionary] = []

```

### Public API Contract

```gdscript
## Subscribes a listener to an event_type.
func subscribe(event_type: StringName, listener: Callable) -> void:
    pass

## Unsubscribes an existing listener from an event_type.
func unsubscribe(event_type: StringName, listener: Callable) -> void:
    pass

## Immediate synchronous broadcast of an EventPayload to all registered listeners.
func emit_now(event: Dictionary) -> void:
    pass

## Queues an EventPayload to be flushed at the end of the current simulation phase.
func enqueue(event: Dictionary) -> void:
    pass

## Flushes and dispatches all queued events, clearing the internal buffer.
func flush_queue() -> void:
    pass

```

### Invariants & Prohibitions

* Observers are strictly forbidden from mutating world state inside an event listener callback (events are historical notifications, not triggers).
* Events must pass verification: `event_data` must contain only flat primitives and arrays.
* Exceptions or errors in one subscriber must not halt dispatching to remaining subscribers.

---

## 5. `SaveRegistry` (Modular State Capture & Recovery)

* **Class Identity:** `SaveRegistry` (`res://core/save/save_registry.gd`)
* **Archetype:** `Registry` / `Codec`
* **Responsibility:** Aggregates, versions, serializes, and deserializes world state slices from registered domain providers without knowing domain contents.

### State Layout

```gdscript
# Map of StringName (domain_key) -> Callable providing state
var _save_providers: Dictionary = {}
# Map of StringName (domain_key) -> Callable accepting state
var _load_consumers: Dictionary = {}
var schema_version: int = 1

```

### Public API Contract

```gdscript
## Registers a domain provider for serialization and restoration.
## provider_save must return a flat, JSON-safe Dictionary.
## provider_load accepts that exact Dictionary for state population.
func register_domain(domain_key: StringName, provider_save: Callable, provider_load: Callable) -> void:
    pass

## Unregisters a domain from the save pipeline.
func unregister_domain(domain_key: StringName) -> void:
    pass

## Collects state slices from all domains into a unified SaveSnapshot dictionary.
func capture_snapshot(current_tick: int) -> Dictionary:
    pass

## Distributes state slices from a SaveSnapshot dictionary to all matching domains.
func restore_snapshot(snapshot: Dictionary) -> bool:
    pass

```

### Canonical `SaveSnapshot` Data Contract

```gdscript
{
    "schema_version": 1,
    "timestamp_utc": 1774028400,
    "current_tick": 45000,
    "domains": {
        "spatial_grid": {},   # Opaque domain data dictionary
        "attributes": {},     # Opaque domain data dictionary
        "reservations": {}    # Opaque domain data dictionary
    }
}

```

### Invariants & Prohibitions

* `SaveRegistry` never validates or inspects keys inside `domains[key]`.
* If a restored snapshot contains a `schema_version` mismatched with current definitions, restoration halts before applying to consumers unless an upgrade migration pipeline is explicitly provided.
* State payloads returned by `provider_save` must not contain raw `Object` references.

---

## 6. Execution Lifecycle Phase Protocol

Every complete discrete tick follows an invariable 5-phase execution loop orchestrated by the Engine Kernel:

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: COMMAND FLUSH                                      │
│ SimClock triggers step -> CommandBus flushes scheduled      │
│ packets for current_tick in ExecutionPriority order.        │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ PHASE 2: SENSORY EVALUATION                                 │
│ Sensors inspect read-only domain state -> Update blackboards.│
│ (Zero state mutations permitted in this phase).             │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ PHASE 3: AGENT DECISION                                     │
│ AI / Planners query blackboards -> Queue CommandPackets      │
│ onto CommandBus for NEXT tick (or immediate resolution).    │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ PHASE 4: DOMAIN COMMIT & STATE MUTATION                     │
│ Validated commands alter local records -> Single Authorities│
│ commit state and enqueue EventPayloads into EventBus.       │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ PHASE 5: EVENT DISPATCH & SNAPSHOT EMISSION                 │
│ EventBus flushes notifications -> Engine compiles and       │
│ emits StateSnapshotDelta downward to the Presentation layer.│
└─────────────────────────────────────────────────────────────┘

```