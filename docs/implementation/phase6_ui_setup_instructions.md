# Phase 6: UI Setup Instructions

Commander, here are the step-by-step instructions to set up the Tactics Board UI scenes in the Godot Editor without generating raw `.tscn` text files. We will create two scenes: the reusable slot prefab and the main UI manager scene.

## 1. Setting up `AINodePrefab.tscn` (The Reusable UI Slot)
This scene serves as the generic container for displaying either a Condition or an Action. It is purely visual and handles native Godot drag-and-drop.

1. **Create a New Scene:**
   - In Godot Editor, click **Scene > New Scene**.
   - Create a **PanelContainer** as the root node.
   - Rename the root node to `AINodePrefab`.

2. **Attach the Script:**
   - Right-click `AINodePrefab` and attach the script: `ui/prefabs/ai_node_prefab.gd`.

3. **Add the Child Label:**
   - Right-click `AINodePrefab` and add a **Label** node as a child.
   - Name the new node strictly `Label` (this is expected by the `@onready var label: Label = $Label` in the script).

4. **Adjust Minimum Size (Optional but Recommended):**
   - Select `AINodePrefab`. In the Inspector under **Control > Layout > Custom Minimum Size**, set it to something reasonable, like `x: 150`, `y: 40`.
   - Set the Layout to span nicely by adjusting the anchor presets (e.g., set to Center, or let the future parent container handle it).
   - In the Inspector, ensure **Mouse > Filter** is set to **Stop** (this is necessary for drag-and-drop GUI inputs to be caught).

5. **Save the Scene:**
   - Save the scene in `ui/prefabs/AINodePrefab.tscn`.

---

## 2. Setting up `TacticsBoardUI.tscn` (The Main Tactics Board)
This scene acts as the "Brain" interface. It dynamically spawns `AINodePrefab` instances to populate a rule list and listens to the EventBus for drag-and-drop operations.

1. **Create a New Scene:**
   - Click **Scene > New Scene**.
   - Create a **Control** node as the root.
   - Rename it to `TacticsBoardUI`.

2. **Attach the Script:**
   - Right-click `TacticsBoardUI` and attach the script: `ui/managers/tactics_board_ui_manager.gd`.

3. **Set Up the UI Container Layout:**
   - Add a **Panel** (or `PanelContainer`) as a background to the `TacticsBoardUI`.
   - Add a **MarginContainer** to organize the content.
   - Inside the MarginContainer, add a **VBoxContainer**.
   - Rename this VBoxContainer to `RulesContainer`. This node will hold the dynamically generated rows (HBoxContainers) of rules.

4. **Connect the Export Variables:**
   - Select the root `TacticsBoardUI` node to view its variables in the Inspector.
   - For `Node Prefab Scene`, drag and drop `ui/prefabs/AINodePrefab.tscn` from your FileSystem panel into the slot.
   - For `Rules Container`, click "Assign..." or drag and drop the `RulesContainer` node you just created into the slot.

5. **Save the Scene:**
   - Save the scene in `ui/managers/TacticsBoardUI.tscn` or a dedicated `ui/menus/` folder if you prefer (e.g., `ui/menus/TacticsBoardUI.tscn`).

---

**Architecture Reminder:**
The `AINodePrefab` is lobotomized; it just catches the native Godot `_get_drag_data`, `_can_drop_data`, and `_drop_data` calls and broadcasts them via the global `EventBus`. The `TacticsBoardUIManager` catches those signals and executes the data swaps directly on the `.tres` Resource structure!
