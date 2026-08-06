# Section 7: Camera & Viewport Management

Welcome to **Section 7: Camera & Viewport Management**.

This section details the design and implementation of the player's view into the tactical battlefield. The camera system provides fluid movement, continuous zooming, and intelligent Z-level adaptation to ensure the player always has a clear view of the action, including interior spaces.

---

## 1. Camera Architecture & Control

The camera is a dedicated, independent node (`TacticalCamera2D`) that is instantiated within the `CombatManager` or `Battlefield` scene. It does not follow a specific unit but is controlled directly by the player.

### Core Features:
*   **WASD Movement:** The primary method for panning the camera across the battlefield.
*   **Continuous Zoom:** Smooth, interpolation-based zooming using the mouse scroll wheel.
*   **Configurable Settings:** Editor-exposed variables (exported) for easy tuning of speed and zoom limits.

### Exported Configuration Variables (`tactical_camera.gd`)

```gdscript
@export_category("Movement")
@export var pan_speed: float = 600.0        # Pixels per second
@export var acceleration: float = 15.0      # Smoothing factor for starting movement
@export var deceleration: float = 10.0      # Smoothing factor for stopping

@export_category("Zoom")
@export var zoom_speed: float = 0.1         # Rate of zoom per scroll click
@export var min_zoom: float = 0.5           # Furthest zoomed out (smaller number = more map visible)
@export var max_zoom: float = 2.5           # Closest zoomed in
@export var zoom_smoothing: float = 10.0    # Interpolation speed for smooth zooming
```

---

## 2. Z-Level Adaptation

The tactical maps in our game utilize verticality (Z-levels). The camera system is responsible for updating the visual representation of the map based on the *current active viewing level* set by the player.

### The `current_view_z_level` Variable
The `TacticalCamera2D` maintains a variable tracking which Z-level the player is currently focused on. The player can adjust this using dedicated hotkeys (e.g., Page Up/Page Down or dedicated UI buttons).

When `current_view_z_level` changes, the camera emits a signal (routed through the `SignalBus`):
`SignalBus.emit_signal("camera_z_level_changed", current_view_z_level)`

### Visual State of Z-Levels

The `GridManager` or a dedicated `TerrainRenderer` listens to this signal and adjusts the visibility and opacity of the tile map layers and dynamic map objects accordingly:

1.  **Current View Level (`Z == current_view_z_level`):**
    *   Fully visible (100% Opacity).
    *   Fully targetable by the player UI.

2.  **Lower Levels (`Z < current_view_z_level`):**
    *   **Visuals:** Faded/darkened (e.g., 50% Opacity or a darker modulate color) to indicate depth while maintaining context.
    *   **Interaction:** Remains targetable.

3.  **Higher Levels (`Z > current_view_z_level`):**
    *   **Visuals:** Completely invisible (0% Opacity) or heavily clipped.
    *   **Purpose:** This allows the player to "slice" through roofs or upper floors to see inside structures (interiors) or underneath bridges.
    *   **Interaction:** Not targetable while hidden.

### Example Implementation Logic

```gdscript
# Inside GridManager.gd (Listening to the signal)
func _on_camera_z_level_changed(active_z: int) -> void:
    for layer_node in map_layers:
        var layer_z = layer_node.get_z_index()

        if layer_z == active_z:
            layer_node.modulate.a = 1.0     # Fully visible
            layer_node.visible = true
        elif layer_z < active_z:
            layer_node.modulate.a = 0.5     # Faded for depth
            layer_node.visible = true
        else: # layer_z > active_z
            layer_node.visible = false      # Hidden to show interiors
```

---

## 3. Boundary Confinement

To prevent the player from panning into the endless void, the camera must be clamped to the generated map's boundaries.

When the `EnvironmentManager` finishes generating the map, it pushes the bounding box coordinates to the `TacticalCamera2D`. The camera's `_process` function clamps its `global_position` within this rect, taking the current zoom level into account to ensure the edges of the screen do not overshoot the map bounds.