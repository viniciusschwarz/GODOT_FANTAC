A shallow 5-word whitelist (`Registry`, `Driver`, `Evaluator`, `Buffer`, `Resolver`) breaks down the moment you start building networking, physics spatial hashing, serialization codecs, behavioral trees, or UI presenters. Limiting the vocabulary too early simply forces the AI to misuse those five terms for concepts they don't fit.

A truly comprehensive lexicon is not an arbitrary list of keywords. It is a **deterministic taxonomy** that maps every mechanical responsibility in a software engine to an explicit naming pattern.

Here is the exhaustive, complete lexicon framework categorized by structural role, behavioral grammar, and architectural boundary.

---

### 0. The Headless Tests

# Use this command to run the headless tests:
 &"C:\Users\vinic\Documents\DEV\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe" --headless -s res://

### 1. The Exhaustive Functional Archetype Taxonomy (Class/Script Suffixes)

Every class, script, or structural component in the engine must terminate with an archetype that explicitly declares its computational behavior:

#### Group A: Data Stores, Collections & Lookups

* **`*Registry`**: Dynamic, key-indexed read/write storage for runtime entities or singletons (e.g., `EntityRegistry`, `CommandRegistry`).
* **`*Catalog` / `*Manifest**`: Static, read-only collection of definitions loaded from configuration at boot time (e.g., `ItemCatalog`, `BiomeManifest`).
* **`*Repository`**: Abstraction layer over persistent storage (disk, cloud, database) that reads and writes domain aggregates (e.g., `SaveRepository`, `ProfileRepository`).
* **`*Buffer`**: Temporary holding collection for data queued for deferred execution or batching (e.g., `InputBuffer`, `DeltaBuffer`).
* **`*Pool`**: Object lifecycle recycling container to prevent allocations in tick loops (e.g., `ParticlePool`, `CommandPacketPool`).
* **`*Blackboard`**: Flat, shared key-value context storage used for decoupling state from behavior (e.g., `AgentBlackboard`, `GlobalBlackboard`).

#### Group B: Transformations, Computations & Algorithms (Pure Functions / Stateless)

* **`*Evaluator`**: Pure query or heuristic calculator; inspects state and returns a scalar score, rank, or boolean decision without mutating inputs (e.g., `CoverEvaluator`, `UtilityEvaluator`).
* **`*Resolver`**: Evaluates interactions, arbitrates conflicts, or solves rules between two or more parties (e.g., `CombatResolver`, `CollisionResolver`, `TradeResolver`).
* **`*Calculator`**: Deterministic mathematical utility executing domain equations (e.g., `TrajectoryCalculator`, `TaxCalculator`).
* **`*Codec` / `*Serializer**`: Bidirectional data transformer; converts memory structures to/from wire or disk formats (e.g., `BinaryStateCodec`, `JsonSnapshotSerializer`).
* **`*Filter`**: Evaluates a stream or collection and yields a subset meeting specific criteria (e.g., `TargetFilter`, `SaveDataFilter`).
* **`*Validator`**: Enforces system invariants; inspects a payload and returns a boolean or validation error list (e.g., `CommandValidator`, `RecipeValidator`).

#### Group C: Execution, Lifecycles & Coordination (Stateful)

* **`*Driver`**: Long-running, multi-tick state machine driving a single agent or process through sequential steps until completion or interruption (e.g., `JobDriver`, `AnimationSequenceDriver`).
* **`*Sequencer` / `*Scheduler**`: Coordinates chronological ordering, phases, or turn progressions across multiple entities (e.g., `TurnSequencer`, `TaskScheduler`).
* **`*Dispatcher` / `*Router**`: Routes messages, packets, or UI views to their appropriate destinations without executing domain logic (e.g., `EventDispatcher`, `ScreenRouter`).
* **`*Director` / `*Orchestrator**`: Macro-level system that observes systemic telemetry and periodically issues high-level commands or environmental shifts (e.g., `ThreatDirector`, `WeatherDirector`).
* **`*Pipeline`**: A fixed, linear chain of steps through which a data packet must pass sequentially (e.g., `DamagePipeline`, `SavePipeline`).

#### Group D: Boundaries, Contracts & Views

* **`*Contract` / `*Interface**`: Pure abstract definition of signatures, enums, and docstrings; zero executable logic (e.g., `SavableContract`, `TickingContract`).
* **`*Adapter` / `*Bridge**`: Converts an external or engine-specific API into an internal engine contract (e.g., `GodotInputAdapter`, `SteamLeaderboardBridge`).
* **`*View`**: Visual-only presentation component bound to dumb data (e.g., `HealthBarView`, `InventoryGridView`).
* **`*Presenter`**: Presentation-layer coordinator that observes model changes and updates the View, or translates UI input into commands (e.g., `InventoryPresenter`).
* **`*Sensor`**: Inspects the world and translates spatial/physical realities into plain data for a Blackboard or Agent (e.g., `VisionSensor`, `ProximitySensor`).

#### Group E: Data Models & Payloads

* **`*Definition`**: Immutable configuration schema defining base properties of an asset (e.g., `ItemDefinition`, `SkillDefinition`).
* **`*Snapshot`**: Immutable, read-only slice of runtime state at a specific tick (e.g., `WorldStateSnapshot`, `PawnSnapshot`).
* **`*Packet` / `*Message` / `*Envelope**`: Atomic data transport payload passed across boundaries or queues (e.g., `CommandPacket`, `LogMessage`).
* **`*Record`**: A single row or instance of structured transactional state (e.g., `CombatLogRecord`, `TradeRecord`).

---

### 2. The Granular Lexicon of Operations (Method & Function Grammar)

LLMs often fall back on generic verbs like `process()`, `update()`, `handle()`, or `run()`. A comprehensive lexicon specifies the verb according to what the function physically does to memory:

| Verb Category | Permitted Prefix | Semantic Meaning | Must Return | Must NOT Do |
| --- | --- | --- | --- | --- |
| **Pure Queries** | `get_*` | Fetches an existing reference or computed value in $O(1)$ or light $O(N)$. | Value / Object | Never mutate internal state. |
|  | `find_*` | Searches a collection or spatial tree; may return null/empty. | Result / Null | Never mutate internal state. |
|  | `calculate_*` | Runs mathematical transformations on inputs. | Primitive / Struct | Never access globals or mutate state. |
|  | `has_*` / `is_*` / `can_*` | Boolean check against conditions or capabilities. | `bool` | Never perform side effects. |
| **Mutations** | `set_*` | Direct value assignment or property overwrite. | `void` | Minimal side effects; no cascades. |
|  | `mutate_*` / `apply_*` | Alters state based on a delta or calculation (e.g., `apply_damage_delta`). | Result / `void` | Must enforce invariants. |
|  | `reset_*` / `clear_*` | Restores an object to default or empty initial state. | `void` | Cannot leave dangling references. |
| **Lifecycle** | `initialize_*` | One-time setup of dependencies, allocations, and buffers. | `void` | Never call mid-simulation. |
|  | `tick_*` | Fixed-step discrete frame execution. | `void` | No dynamic memory allocation. |
|  | `dispose_*` / `teardown_*` | Cleans up memory, detaches observers, drops claims. | `void` | Must be idempotent. |
| **Transactions** | `try_*` | Attempts an action that may fail due to state locks. | `bool` or Result Enum | Never throw unhandled errors. |
|  | `claim_*` / `reserve_*` | Exclusively locks a resource for an entity. | Result Enum | Must provide a release path. |
|  | `release_*` | Relinquishes a claim or lock on a resource. | `bool` / `void` | Cannot fail silently. |
|  | `commit_*` | Finalizes a multi-step staging buffer to permanent state. | Result Enum | Must be atomic (all or nothing). |
| **Routing** | `dispatch_*` / `emit_*` | Pushes an event or packet onto a bus or observer chain. | `void` | Never wait for synchronous results. |
|  | `bind_*` / `unbind_*` | Connects or disconnects presentation views to models. | `void` | No business logic. |

---

### 3. Variable & Attribute Precision Rules

Ambiguity in variables is where state desyncs begin. Every variable must tell you its **type**, its **measurement unit**, and its **cardinality** from its name alone:

1. **Temporal & Physical Units Must Be Explicit:**
* Time: `*_in_ticks`, `*_in_seconds`, `*_in_ms`, `*_timestamp`.
* Distance/Space: `*_in_cells`, `*_in_world_units`, `*_in_pixels`.
* Weights/Rates: `*_per_tick`, `*_per_second`, `*_ratio` (0.0 to 1.0), `*_percentage` (0 to 100).


2. **Collections Must Describe Contents and Keying:**
* Maps/Dictionaries: `[key_type]_to_[value_type]` (e.g., `pawn_id_to_active_driver`, `cell_coord_to_occupant_id`).
* Arrays/Lists: Must be plural nouns matching the entity: `active_pawn_ids`, `dirty_chunk_indices`, `pending_commands`.
* Sets/Flags: `*_mask` (for bitfields), `*_set` (for unique collections).


3. **Pointers & References:**
* Raw Identifier vs. Object: If it's a numeric handle, it MUST end in `*_id` or `*_handle` (e.g., `target_pawn_id`, never just `target_pawn` if it's an integer).



---

### 4. Domain-Agnostic Lexicon (Banned Vocabulary vs. Agnostic Terms)

To keep systems truly generic across genres, strip out theme-specific terminology from Layer 1 and Layer 2:

| Game/Genre-Specific Term (Banned in Core) | Universal Agnostic Term (Required) | Why |
| --- | --- | --- |
| `Pawn` / `Hero` / `Monster` / `Player` | **`Agent`** or **`Actor`** or **`Entity`** | Works for a colonist, a chess piece, a sports player, or a spaceship. |
| `Inventory` / `Chest` / `Backpack` | **`ItemContainer`** or **`SlotArray`** | Works for an RPG satchel, a deck of cards, or an equipment dock. |
| `Health` / `Mana` / `Hunger` / `Stamina` | **`Attribute`** (with **`AttributeModifier`**) | A numeric resource influenced by stacking base/flat/multiplicative values. |
| `Tile` / `Hex` / `MapPosition` | **`Cell`** (discrete) or **`WorldPoint`** (continuous) | Decouples coordinate logic from visual shapes. |
| `Skill` / `Spell` / `Ability` / `Tech` | **`ActionDefinition`** or **`Capability`** | Universal executable behaviors with costs and cooldowns. |
| `Buff` / `Debuff` / `StatusEffect` | **`StateModifier`** or **`Condition`** | A time-decaying or event-decaying transformation on an entity. |
| `Building` / `Tree` / `Rock` | **`StaticProp`** or **`Obstacle`** | Static occupants of spatial cells. |

---

### 5. Architectural Scoping (The Prefix Matrix)

To eliminate confusion about where a file lives and what rules it must follow, enforce directory and namespace prefixes:

* `core_*`: Layer 1 universal infrastructure (zero game logic, zero engine scene tree).
* `domain_*`: Layer 2 reusable domain frameworks (modular across genres: spatial grids, attribute pipelines).
* `game_*`: Layer 3 game-specific implementation (the actual rules of the project you are building).
* `view_*`: Layer 2/3 Godot presentation scenes and visual renderers.

---

### How to Formalize This

This expanded lexicon eliminates the "shallow" constraint while ensuring the AI coder cannot invent ambiguous terminology. Every class maps to a structural role, every function declares its memory footprint, and all parameters communicate their physical units.