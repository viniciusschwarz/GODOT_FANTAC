# Architectural Audit & Verification: Framework 1 (Phase 3)

* **Document Path:** `res://docs/audit/audit_framework1_phase3.md`
* **Scope:** Technical audit of Phase 3 tactical queries (Bresenham line-of-sight, directional cover, recursive shadowcasting FoV) and multi-agent crowd flow field generation (Dijkstra wave-front integration and deterministic vector descent fields).


* **Target Files:**
* `res://framework/pathfinding/solvers/flow_field_solver.gd`

* `res://framework/pathfinding/evaluators/tactical_query_resolver.gd`




---

## 1. Augmented Architectural Scoring Protocol (A-ASP)

* **D1: Boundary Layer Integrity (10/10):** Both files extend `RefCounted` with zero dependencies on Godot scene trees, visual nodes, or physics engines. Core layers, simulation registries, and GOAP modules remain untouched.


* **D2: Contract & Schema Conformance (10/10):** Strictly interfaces with `SpatialNavGraphRegistry`, `NavigationProfileDefinition`, and `NavTopologyContract`.


* **D3: Stateless Engine Compliance (10/10):** All public algorithms (`generate_integration_field`, `generate_vector_field`, `get_flow_direction`, `has_line_of_sight`, `evaluate_cover`, `calculate_field_of_view`) are declared as `static func`.


* **D4: Memory & Performance Layout (10/10):** The integration field and vector field output directly into flat 1D packed arrays (`PackedFloat32Array`, `PackedVector2Array`) sized `width * height` without runtime allocations in query steps.


* **D5: Algorithmic & Geometric Precision (10/10):**
* `FlowFieldSolver` enforces candidate node clearance, diagonal corner-cutting prevention, and topological offsets (Orthogonal 4, Orthogonal 8, Hex Axial) with deterministic tie-breaking.


* `TacticalQueryResolver` implements Bresenham integer-only raycasting, directional cover derivation based on threat vector offsets, and octant recursive shadowcasting.




* **D6: Lexicon & Suffix Alignment (10/10):** Conforms directly to `res://docs/lexicon.md` using the `*Solver` and `*Resolver` archetypes.



**Total Score: 60 / 60 (Tier A — 100%)**

---

## 2. In-Depth Technical Observations

1. **Deterministic Vector Field Gradient:**
`FlowFieldSolver.generate_vector_field` inspects neighbors using ordered directional offsets (e.g., North $\to$ North-East $\to$ East $\dots$) with a strict threshold (`neighbor_cost < min_cost - 0.0001`), preventing gradient oscillation between cells with identical integration costs.


2. **Endpoint-Safe Line of Sight:**
`TacticalQueryResolver.has_line_of_sight` checks `current != from_coord and current != to_coord`, allowing units to look out of their own cell and acquire targets inside destination cells without self-occlusion.


3. **Octant Shadowcasting Matrix:**
`TacticalQueryResolver._cast_light` implements proper coordinate space transformations across all 8 octants with continuous slope intervals (`start_slope`, `end_slope`) and Euclidean radius clamping (`radius_squared`).



---

## 3. Approved Subsystem Ledger

| Script Identifier | Archetype

 | Score | Architectural Status |
| --- | --- | --- | --- |
| `flow_field_solver.gd`<br> | `Solver` / `Resolver`<br> | **10 / 10** | **Tier A (Frozen)** |
| `tactical_query_resolver.gd`<br> | `Resolver`<br> | **10 / 10** | **Tier A (Frozen)** |

---

## 4. Phase 4 Implementation Prompt for Jules (The Visual Integration Scene)

```markdown
# TASK: Framework 1 (Spatial Topology & Navigation Graph) — Phase 4: Unified Interactive Visual Testbed

With Phases 1, 2, and 3 of Framework 1 verified and frozen at Tier A, construct the interactive presentation test scene uniting the GOAP Logistics Courier with the Spatial Nav Graph, dynamic obstacles, path costs, and tactical debug visualizations.

---

### MANDATORY CONTEXT & INVARIANTS
1. Adhere strictly to `res://docs/architecture_constitution.md` and `res://docs/lexicon.md`.
2. Core and Framework Immutability: Do NOT modify any file under `res://core/`, `res://simulation/`, `res://framework/goap/`, or `res://framework/pathfinding/`.
3. Presentation Layer Boundary: All files live in `res://scenes/tests/pathfinding/`. The scene controller orchestrates the simulation, subscribes to events, registers command executors, and draws the visual representation.
4. CQS & Single Authority: Changing cell traversal costs, toggling solid obstacle walls, or placing asymmetric links must occur strictly via `CommandBus.submit()`. Never mutate `SpatialNavGraphRegistry` directly from UI button callbacks.
5. Discrete Snapping: The visual pawn snaps directly to the current node coordinates without frame interpolation.

---

### TARGET DIRECTORY STRUCTURE

Create the following files in `res://scenes/tests/pathfinding/`:

```text
res://scenes/tests/pathfinding/
├── pathfinding_test_view.tscn    # Root Control node with grid canvas, inspector telemetry, and controls
└── pathfinding_test_view.gd      # Presentation controller managing registries, commands, and drawing

```

---

### SPECIFICATIONS & BEHAVIORAL REQUIREMENTS

#### 1. Simulation Setup & Topography

* **Grid Dimensions:** 12 columns by 12 rows (`Rect2i(0, 0, 12, 12)`).
* **Entities & Locations:**
* **Supply Depot (ID 101):** Coord `Vector2i(1, 1)`. Type `&"SUPPLY"`. Balance: `50` units of `&"wood"`.
* **Demand Depot (ID 102):** Coord `Vector2i(10, 10)`. Type `&"DEMAND"`. Balance: `0` units of `&"wood"`.
* **Courier Pawn (Entity ID 1):** Starts at `Vector2i(0, 0)`. Inventory container ID: `1`.


* **Topological Obstacles & Terrain:**
* Place a solid obstacle barrier (e.g. wall cells from `Vector2i(4, 2)` to `Vector2i(4, 9)`).
* Place a rough mud zone (costs = `3.0`) at `Vector2i(5, 5)` through `Vector2i(7, 7)`.
* Place an asymmetric one-way teleporter/drop link from `Vector2i(2, 6)` to `Vector2i(8, 6)`.


* **Registries Initialized:**
* `SpatialNavGraphRegistry` (size 12x12).
* `AsymmetricLinkRegistry`.
* `SpatialCellRegistry`, `ResourceContainerRegistry`, `ReservationRegistry`.
* `GoapSequencer`, `GoapPlanner`, `GoapGoalArbitrator`.



#### 2. Navigation-Aware Action Upgrade

In `pathfinding_test_view.gd`, wire the courier's navigation routine so `ActionNavigateTo` computes its full path using `AStar2DSolver.find_path()` on the `SpatialNavGraphRegistry`, navigating step-by-step along the resulting path rather than using naive Manhattan stepping.

#### 3. Visual Presentation Layout (`pathfinding_test_view.tscn`)

* Window split via `HSplitContainer` (Left: Grid Canvas, Right: Dashboard & Telemetry).
* **Left Panel (Grid Canvas - Custom `_draw()`):**
* Draw 12x12 grid (40x40 pixels per cell).
* Normal cells: Dark charcoal `#1e1e24` with subtle grid lines.
* Mud cells (cost > 1.0): Brownish/amber tint `#5c4033`.
* Solid obstacle walls: Dark stone gray `#555555`.
* Supply Depot (`1, 1`): Emerald green square `#2ecc71` with stock count.
* Demand Depot (`10, 10`): Orange square `#e67e22` with stock count.
* Asymmetric Link: Cyan dashed line or indicator connecting `(2, 6)` to `(8, 6)`.
* Active Path Overlay: Draw a green/yellow polyline connecting the waypoints of the pawn's current active path.
* Courier Pawn: Blue circle at `pawn_coord` with current cargo text.
* Interactive Cell Painting: Clicking on the grid allows the user to toggle an obstacle cell at the clicked cell coordinate (dispatches `&"NAV_SET_CELL_MASK"` command).


* **Right Panel (Dashboard & Telemetry):**
* **Simulation Controls:** `"Step Tick"`, `"Play / Pause"`, Speed selector (`1x`, `2x`, `5x`, `10x`), `"Reset"`.
* **Debug Toggles (Checkboxes):**
* Show Clearance Map (draw clearance integer values in cells).
* Show Flow Field (draw directional vector arrows in cells pointing toward Demand Depot).
* Show Line of Sight / FoV from Pawn (highlight visible cells in subtle light blue).


* **Telemetry Labels:** Tick, Active Goal, Active Action, Courier Cargo, Remaining Path Nodes.
* **Event Console:** Scrollable `RichTextLabel` logging emitted events.



#### 4. Command Registrations (Two-Stage Pipeline)

Register commands on `CommandBus`:

* `&"SPATIAL_RELOCATION"`
* `&"RESERVATION_CLAIM"`
* `&"RESERVATION_RELEASE"`
* `&"RESOURCE_TRANSFER"`
* `&"NAV_SET_CELL_MASK"` (Updates `SpatialNavGraphRegistry` mask and triggers `recalculate_clearance()`)
* `&"NAV_SET_CELL_COST"` (Updates cell travel cost multiplier)

---

### DELIVERABLES

* Create `res://scenes/tests/pathfinding/pathfinding_test_view.tscn`.
* Create `res://scenes/tests/pathfinding/pathfinding_test_view.gd`.
* Verify headless compilation and proper syntax checks.

```

<FollowUp label="Shall we review the command handler implementations for pathfinding_test_view.gd before Jules builds the scene?" query="Detail the exact command validation and execution callbacks for NAV_SET_CELL_MASK and NAV_SET_CELL_COST in pathfinding_test_view.gd."/>

```