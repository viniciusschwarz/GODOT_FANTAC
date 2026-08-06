# Section 10: UI Architecture & Navigation

Welcome to **Section 10: UI Architecture & Navigation**.

To avoid "UI patchworking" as the project scales, this game employs a robust, central `UIManager` Autoload and a standardized component-based architecture. This ensures a consistent, professional layout across all game phases (Campaign, Deployment, Planning, Combat) and allows for easily swappable art assets later.

---

## 1. The UI Manager Autoload

The `UIManager` is responsible for handling the creation, destruction, stacking, and visibility of all user interface elements. It acts as the single source of truth for UI state.

**Responsibilities:**
*   Registering reusable UI prefabs (Windows, Buttons, Tooltips).
*   Handling Z-index and focus (ensuring modals appear on top).
*   Managing the global navigation state (which windows are currently open).
*   Intercepting input events to prevent "click-throughs" to the 3D/2D game world beneath the UI.

---

## 2. Reusable Component Architecture

Rather than building unique windows from scratch every time, all major UI panels inherit from a standardized base scene.

### `WindowBase.tscn`
A generic Control node that defines the standard styling and behavior for any popup or panel.
*   **Header:** Contains the Title Label and an "X" Close Button.
*   **Body:** A `MarginContainer` where specific content (Settings, Roster, etc.) is injected.
*   **Background:** A styled `Panel` using the global Theme resource.
*   **Drag Logic:** Optional script allowing the window to be dragged by the header.

### Global Theme (`main_theme.tres`)
All UI components strictly use Godot's Theme system. Hardcoded colors or fonts on individual nodes are strictly forbidden. Modifying `main_theme.tres` will instantly update the look of the entire game.

---

## 3. Global Layout: The Left Panel Navigation

To provide a consistent user experience, the core navigation is anchored by a persistent Left Panel that is available across all game phases (though specific buttons may disable depending on context).

### Layout Structure (Godot Viewport)

```text
┌────────────────────────────────────────────────────────┐
│ ┌──────────────┐                                       │
│ │ LEFT PANEL   │                                       │
│ │ (VBox)       │                                       │
│ │              │                                       │
│ │ [Campaign]   │      MAIN VIEWPORT AREA               │
│ │ [Roster]     │      (Tactical Map or Campaign Map)   │
│ │ [Inventory]  │                                       │
│ │ [Research]   │                                       │
│ │              │                                       │
│ │              │                                       │
│ │ [Settings]   │                                       │
│ │ [Save/Load]  │                                       │
│ │ [Quit Game]  │                                       │
│ └──────────────┘                                       │
└────────────────────────────────────────────────────────┘
```

### Navigational Buttons & Sub-Windows

Clicking a button on the Left Panel triggers the `UIManager` to instantiate or toggle visibility of the corresponding `WindowBase` child scene.

1.  **Campaign / Mission Select:**
    *   *Availability:* Only available outside of combat.
    *   *Function:* Opens the Mission List UI (See Section 8) to select the next battle.
2.  **Unit Roster:**
    *   *Availability:* Always.
    *   *Function:* Opens a window displaying all owned units, their stats, current health, and equipped gear.
3.  **Inventory / Armory:**
    *   *Availability:* Always.
    *   *Function:* Opens a window to view unequipped weapons, armor, and consumables. Allows drag-and-drop equipping to units in the Roster.
4.  **Research / Upgrades (Future Phase):**
    *   *Availability:* Campaign only.
    *   *Function:* Unlocks new unit types or global buffs.
5.  **Settings:**
    *   *Availability:* Always.
    *   *Function:* Opens the Audio/Video/Gameplay configuration menu.
6.  **Save/Load:**
    *   *Availability:* Always (disabled during Execution Phase of combat).
    *   *Function:* Opens the Save Game manager.

---

## 4. UI Data Binding (Signals)

To maintain decoupling, the UI never directly modifies game state variables, nor does the game state poll the UI. All communication is handled via the `SignalBus`.

**Example: Opening the Roster**
1. Player clicks "Roster" button on Left Panel.
2. Button emits `pressed` signal to `UIManager`.
3. `UIManager` instantiates `roster_window.tscn` (derived from `WindowBase`).
4. `RosterWindow` emits a request via `SignalBus`: `SignalBus.emit_signal("request_player_roster_data")`.
5. `DataManager` hears the request and responds: `SignalBus.emit_signal("player_roster_data_updated", data_array)`.
6. `RosterWindow` receives the array and populates its internal lists.