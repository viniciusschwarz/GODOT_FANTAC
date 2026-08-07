# Unit Scene (`unit.tscn`) Manual Setup Instructions

Follow these steps exactly to set up the `unit.tscn` file within the Godot Editor. Do not create visual placeholder nodes (like `Sprite2D` or `ColorRect`). This unit is purely a logical container at this stage.

## 1. Create the Scene
1. Open the Godot Editor.
2. Go to **Scene > New Scene**.
3. In the "Create Root Node:" dialog on the left panel, choose **Other Node**.
4. Search for and select **Node2D**.
5. Rename the newly created root node from `Node2D` to **`Unit`**.
6. Save the scene (Ctrl+S or Cmd+S) to the following path:
   `res://core/entities/unit/unit.tscn`

## 2. Attach the Unit Script
1. Select the **`Unit`** root node in the Scene dock.
2. In the Inspector (or by right-clicking the node), click **Attach Script**.
3. In the attach script dialog:
   - Ensure "Language" is `GDScript`.
   - Ensure "Inherits" is `Node2D`.
   - Set the "Path" to: `res://core/entities/unit/unit.gd` (the script we already created).
4. Click **Load** (or **Create** if it asks to overwrite, but you should just select the existing file).

## 3. Create the Components (Child Nodes)
1. Right-click the **`Unit`** root node in the Scene dock and select **Add Child Node**.
2. Search for and select **Node** (the base white circle icon, not `Node2D` or `Node3D`).
3. Rename this newly created node to **`HealthComponent`**.
4. Right-click the **`Unit`** root node again and select **Add Child Node**.
5. Search for and select **Node**.
6. Rename this newly created node to **`MovementComponent`**.

## 4. Attach the Component Scripts
1. Select the **`HealthComponent`** node.
2. Attach a script to it, pointing the path to the existing script:
   `res://core/components/health_component.gd`
3. Select the **`MovementComponent`** node.
4. Attach a script to it, pointing the path to the existing script:
   `res://core/components/movement_component.gd`

## 5. Assign the Exported Variables in the Inspector
1. Select the **`Unit`** root node in the Scene dock.
2. Look at the **Inspector** panel on the right. Under the `Unit.gd` script properties, you should see a category called **Components**.
3. You will see two properties: `Health Component` and `Movement Component`.
4. Click on `Health Component` and select **Assign...**.
5. In the popup, choose the **`HealthComponent`** child node.
6. Click on `Movement Component` and select **Assign...**.
7. In the popup, choose the **`MovementComponent`** child node.

## 6. Final Verification
- Ensure the scene tree looks exactly like this:
  ```
  Unit (Node2D, attached script: unit.gd)
  ├── HealthComponent (Node, attached script: health_component.gd)
  └── MovementComponent (Node, attached script: movement_component.gd)
  ```
- Make sure you save the scene again!

That's it! The backend logic container for the actors is correctly established.