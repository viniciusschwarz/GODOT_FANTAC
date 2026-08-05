Welcome to **Section 5: Desktop Integration & Release Readiness** of our Master Architectural Blueprint!

I am very excited to help you complete this final planning step. This section bridges the gap between a project that runs inside the Godot Editor and a standalone, professional desktop application that players can download, install, and run on their computers.

Because our architecture relies on modular central hubs, adding desktop-specific features is very clean. We will create a dedicated manager that handles the operating system (OS) requests without tangling with your combat or UI code.

---

### Panorama Geral (Overview): Desktop Integration

When you release a desktop game, players expect certain standard features:

1. **Window Controls:** The ability to toggle Fullscreen, Borderless Window, and standard Windowed modes.
2. **Safe Quitting:** When a player clicks the "X" on their desktop window or presses `Alt+F4`, the game shouldn't just crash or close instantly. It should intercept that request, perhaps auto-save, and then close safely.
3. **Performance Limits:** Toggling V-Sync (Vertical Sync) or capping the framerate (FPS) so the game doesn't overwork the player's graphics card during the auto-battler simulation.

To handle this, we will design our final central hub: the **`WindowManager`**.

---

### The Architecture: `WindowManager` (Autoload)

```
                         ┌────────────────────────┐
                         │  SignalBus (Autoload)  │
                         └───────────┬────────────┘
                                     │ (Emits: game_quit_requested)
                                     ▼
┌──────────────┐          ┌──────────────────────┐         ┌──────────────────┐
│SettingsManager│◄───────►│  WindowManager       │◄───────►│ Desktop OS (OS)  │
│(Reads config) │         │  (Handles displays)  │         │ (Windows/Mac)    │
└──────────────┘          └──────────────────────┘         └──────────────────┘

```

#### Responsibilities of the `WindowManager`:

* **OS Interception:** It listens to the player's Operating System. If the OS says "Close the window", this script intercepts it, tells the `SaveManager` to save, and then allows the game to close.
* **Display Configuration:** It takes commands from your Settings UI (e.g., "Set Fullscreen") and applies them to the Godot `DisplayServer`.

---

### Presentation of the Code: `WindowManager.gd`

Here is the complete, modular code for our `WindowManager`.

**Why we are doing it this way:** We use Godot's built-in `DisplayServer` class. By putting all these display commands in one Autoload, your UI buttons (like a "Fullscreen" checkbox in the options menu) only need to call `WindowManager.set_fullscreen(true)` instead of writing complex OS-level code inside the UI scripts.

#### Step-by-Step Implementation Instructions:

1. In your Godot `FileSystem` dock, open the `Autoloads` folder we planned earlier.
2. Create a new script named `WindowManager.gd`.
3. Open the script and paste the code below.
4. Go to **Project -> Project Settings -> Autoload** tab.
5. Add `WindowManager.gd` and name it `WindowManager`. Make sure it is enabled.

```gdscript
extends Node
## WINDOW MANAGER (Autoload)
## Handles all interactions with the Desktop Operating System.
## Controls screen resolution, window modes, V-Sync, and safe quitting.

func _ready() -> void:
    # 1. Intercept the OS "Quit" request (like clicking the window's X button)
    # We tell Godot: "Don't quit automatically, let me handle it!"
    get_tree().set_auto_accept_quit(false)
    
    # Note: In a full game, you would load saved settings from your 
    # SettingsManager here to apply the player's preferred resolution on startup.

## 2. This built-in Godot function listens for OS-level events.
func _notification(what: int) -> void:
    # Check if the OS is asking the game to close (Alt+F4 or X button)
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _handle_safe_quit()

## 3. Custom function to safely shut down the game.
func _handle_safe_quit() -> void:
    print("Window Manager: Safe quit requested by OS.")
    
    # Here, we can tell the SignalBus that we are quitting.
    # Other systems (like SaveManager) can listen to this and save the game!
    # Example: SignalBus.game_quit_requested.emit()
    
    print("Window Manager: Shutting down safely.")
    # Finally, we tell the engine to actually close the application.
    get_tree().quit()

# ==========================================
# DISPLAY CONTROL API (Used by Settings UI)
# ==========================================

## Sets the game to Fullscreen or Windowed mode.
## @param is_fullscreen: true for Fullscreen, false for Windowed.
func set_fullscreen(is_fullscreen: bool) -> void:
    if is_fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
        print("Window Manager: Mode set to Fullscreen.")
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        print("Window Manager: Mode set to Windowed.")

## Toggles V-Sync (Vertical Synchronization) to prevent screen tearing.
## @param enabled: true to enable V-Sync, false to disable.
func set_vsync(enabled: bool) -> void:
    if enabled:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
        print("Window Manager: V-Sync Enabled.")
    else:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        print("Window Manager: V-Sync Disabled.")

## Sets a maximum frame rate to prevent the GPU from overworking.
## @param fps_limit: The maximum frames per second (e.g., 60). Use 0 for unlimited.
func set_fps_limit(fps_limit: int) -> void:
    Engine.max_fps = fps_limit
    print("Window Manager: FPS limit set to ", fps_limit)

```

---

### Step 4: Exporting the Game

When you are ready to share your MVP with others, you will use Godot's Export pipeline.

1. You will go to **Project -> Export**.
2. Download the Godot Export Templates (Godot will prompt you to do this the first time).
3. Add a **Windows Desktop** (and/or macOS/Linux) preset.
4. Here, you will set your custom game icon (`.ico` for Windows), the game's title, and version number.
5. Click **Export Project** to generate an `.exe` file!

---

We have now successfully mapped out the entire Master Blueprint:

1. **Game Flow & Screens** (SceneManager)
2. **Technical Core** (DataManager, SaveManager)
3. **Combat Simulation** (WEGO, AI, GridManager)
4. **Visual Polish** (FXManager)
5. **Desktop Integration** (WindowManager)