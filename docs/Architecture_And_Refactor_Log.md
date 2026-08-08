## Destructible Tactical Prop Controller

### Scene Assembly Instructions for `scenes/props/tactical_prop.tscn`

In accordance with the Scene Creation Directive, here are the step-by-step instructions to assemble the `tactical_prop.tscn` scene in the Godot Editor:

1. **Create a New Scene:**
   - Go to `Scene > New Scene` in the Godot Editor.
   - Choose `2D Scene` to create a `Node2D` as the root node.

2. **Name the Root Node:**
   - Rename the root `Node2D` to `TacticalProp`.

3. **Attach the Script:**
   - Right-click the root `TacticalProp` node and select `Attach Script`.
   - Browse to `res://scripts/props/tactical_prop.gd` and attach it.

4. **Assign the Prop Resource (Optional for Template, Mandatory for Instances):**
   - In the Inspector for `TacticalProp`, locate the `Prop Data` export variable.
   - You can load a specific preset (like `res://data/props/wooden_gate_preset.tres`) or leave it empty to assign it per-instance dynamically.

5. **Add Visual Children (Optional but Recommended):**
   - Add a `Sprite2D` node as a child of `TacticalProp` to render the prop's texture.
   - Add an `AnimationPlayer` or `CPUParticles2D`/`GPUParticles2D` for destruction effects.
   - The script `tactical_prop.gd` provides an empty `_update_visual_state(state: int)` method where you can tie in these visual components.

6. **Save the Scene:**
   - Save the scene to `res://scenes/props/tactical_prop.tscn`.
