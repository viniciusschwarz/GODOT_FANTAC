Welcome to **Section 4: Audio, Visuals & Presentation Polish ("Juice")** of our Master Architectural Blueprint!

As your Godot Programming Partner, I am excited to talk about this section. In game development, "Juice" refers to the visual and audio feedback that makes your game feel alive, heavy, and satisfying—things like screen shake, floating damage numbers, sword clash sounds, and hit flashes.

Because we are building a strictly **modular and decoupled** game, our visual and audio effects will **never** contain game logic. Instead, they will act as "listeners." When the `CombatManager` calculates damage, it simply shouts to the `SignalBus`. Our visual systems will hear that shout and spawn the effects automatically!

---

### 1. Core Polish & Presentation Architecture

```
                         ┌────────────────────────┐
                         │  SignalBus (Autoload)  │
                         └───────────┬────────────┘
                                     │ (Listens for events)
       ┌─────────────────┬───────────┴───────────┬─────────────────┐
       ▼                 ▼                       ▼                 ▼
┌──────────────┐  ┌──────────────┐       ┌──────────────┐   ┌──────────────┐
│ FXManager    │  │AudioManager  │       │Environment   │   │UIDebug       │
│ (Particles,  │  │(SFX pooling) │       │(Lights/Time) │   │Visualizer    │
│  Numbers)    │  │              │       │              │   │(AI Paths)    │
└──────────────┘  └──────────────┘       └──────────────┘   └──────────────┘

```

---

### 2. Detailed System Specifications

#### System 1: Visual Combat Feedback (The "Juice")

* **File Path:** `res://Managers/FXManager.gd`

**Purpose:**
Provides immediate, satisfying visual responses to combat events without touching the core math of the game.

**Key Features:**

* **Floating Combat Text:** When `SignalBus.unit_health_changed` is emitted, this system spawns a small, colored number over the unit that floats up and fades out (e.g., Red for damage, White for blocked/armor, Green for healing).
* **Hit-Stop & Screen Shake:** For critical hits or heavy cavalry charges (like a blunt mace impact), the game time pauses for a fraction of a second (Hit-Stop) and shakes the camera, giving the attack immense physical weight.
* **Hit Flashes:** A simple shader attached to the unit's sprite that flashes solid white for `0.1` seconds when they take damage.

#### System 2: Animation State Controllers

* **File Path:** `res://Entities/Unit/Components/AnimationComponent.gd`

**Purpose:**
Manages the `AnimatedSprite2D` or `AnimationPlayer` of a unit.

**Key Features:**

* It listens to the unit's internal state or the `SignalBus` to transition between animations: `Idle`, `Walk`, `Attack`, `Hurt`, and `Die`.
* **Directional Sprites:** Because units can flank, the animation component looks at the unit's `facing_vector` to flip the sprite left/right or swap to up/down sprites (if using 4-directional or 8-directional art).

#### System 3: Dynamic Lighting & Environment

* **File Path:** `res://Managers/EnvironmentManager.gd`

**Purpose:**
To bring the fantasy medieval setting to life with atmosphere, weather, and time of day.

**Key Features:**

* **Day/Night Cycle:** Uses a `CanvasModulate` node to gradually tint the entire screen a dark blue/purple as turns progress into night.
* **Dynamic Shadows:** Uses `DirectionalLight2D` to cast long shadows from the sun/moon, and `PointLight2D` for torches, campfires, or glowing magical units.
* **Weather Overlays:** A full-screen `GPUParticles2D` system that can trigger rain or fog based on the campaign's current assignment weather rules.

#### System 4: AI Debug & Tactical Visualizer

* **File Path:** `res://UI/Overlays/TacticalVisualizer.gd`

**Purpose:**
Since the game uses a WEGO (simultaneous execution) system driven by AI, the player needs to understand *why* their units are doing what they are doing.

**Key Features:**

* **Intent Lines:** During the Planning Phase, this draws colored 2D lines (`Line2D`) on the board showing where a unit plans to move and who they plan to attack.
* **State Labels:** Small text below units showing their current Behavior Tree state (e.g., *"Flanking"*, *"Holding Line"*, *"Fleeing"*).

---

### 3. Directory & File Structure for Polish

Here is how these visual and audio files will be organized in your Godot project:

```text
res://
├── Managers/
│   ├── FXManager.gd              # Spawns particles and floating text
│   └── EnvironmentManager.gd     # Controls lighting and weather
│
├── Entities/
│   └── Unit/
│       └── Components/
│           ├── AnimationComponent.gd # Handles sprite states
│           └── HitFlashShader.gdshader
│
├── Assets/
│   ├── VisualEffects/            # Reusable particle prefabs
│   │   ├── BloodSpatter.tscn
│   │   ├── ShieldBlockSparks.tscn
│   │   └── FloatingText.tscn
│   │
│   ├── Shaders/
│   │   └── hit_flash.gdshader
│   │
│   └── Audio/                    
│       ├── SFX/                  # Sword clangs, armor hits
│       └── Ambience/             # Rain, wind, battlefield noise
│
└── UI/
    └── Overlays/
        └── TacticalVisualizer.gd # Draws AI paths and states

```

---

### Panorama Geral & Implementation Example: Floating Text

To show you how easy and modular this is, let's look at how we would create the **Floating Combat Text** system.

**The Goal:** We want numbers to pop up when a unit gets hurt.
**The Rule:** The `HealthComponent` that calculates the math must NOT spawn the text itself. It should only emit a signal. A separate `FXManager` listens and does the visual work.

#### The Educational Code Example: `FXManager.gd`

Here is a simplified example of how our decoupled visual effects will work in practice using Godot's `Tween` system (which is perfect for smooth animations via code).

```gdscript
extends Node2D
## FX MANAGER
## This script sits in the Battlefield scene. It listens to the global
## SignalBus and spawns visual effects without interrupting game logic.

# We preload a simple scene that contains a Label (for the text)
const FLOATING_TEXT_SCENE = preload("res://Assets/VisualEffects/FloatingText.tscn")

func _ready():
    # 1. We connect to the global SignalBus. 
    # Whenever ANY unit health changes, trigger our custom function.
    SignalBus.unit_health_changed.connect(_on_unit_health_changed)

## 2. This function runs automatically when the signal is heard.
func _on_unit_health_changed(unit_id: String, new_health: int, amount: int, world_position: Vector2):
    # Only show floating text if there is actual damage or healing
    if amount == 0:
        return
        
    # 3. Create a new instance of our floating text prefab
    var text_instance = FLOATING_TEXT_SCENE.instantiate()
    
    # 4. Set the text value. If damage (negative), show it as positive text, else add a "+" for heals.
    if amount < 0:
        text_instance.text = str(abs(amount))
        text_instance.modulate = Color.RED # Make it red for damage
    else:
        text_instance.text = "+" + str(amount)
        text_instance.modulate = Color.GREEN # Make it green for healing
        
    # 5. Place it exactly where the unit is on the battlefield
    text_instance.global_position = world_position
    
    # Add it to the game world
    add_child(text_instance)
    
    # 6. Animate it! We use Godot's Tween to make it float up and fade out.
    var tween = get_tree().create_tween()
    
    # Move it 50 pixels UP (negative Y) over 1 second
    tween.tween_property(text_instance, "global_position", text_instance.global_position - Vector2(0, 50), 1.0)
    
    # At the same time (parallel), fade the alpha (transparency) to 0 over 1 second
    tween.parallel().tween_property(text_instance, "modulate:a", 0.0, 1.0)
    
    # Once the animation finishes, delete the text node from memory
    tween.tween_callback(text_instance.queue_free)


```

By using this approach, we can turn off the `FXManager`, delete it entirely, or change how it works, and the core combat math of our auto-battler will continue to work perfectly!