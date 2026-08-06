You are an expert Godot 4 & GDScript Software Architect. I am building a 2D tactical auto-battler in a fantasy medieval setting. 

My goal is a strictly modular codebase. Scripts must not be monolithic. We use a hub-based architecture where standalone scripts communicate via central Autoloads and Managers to avoid tight coupling. 

I want you to work on different phases, and your task is to analyze and define each module's responsibility, and second is to refactor the code to adhere to best practices.

TASK 1: CODE REFACTORING
Review the provided scripts in the repo and refactor them following these strict Godot best practices:
1. Eliminate Tight Coupling: Remove hardcoded node paths (e.g., `get_parent()`, `get_node("../../")`). Use `@export` variables for references, `%SceneUniqueNodes` for internal UI, and Autoloads (like `signal_bus.gd`) for global communication.
2. Centralized Data: Entities must get and set their data from central hubs (e.g., `data_manager.gd`, `game_state.gd`), not store isolated duplicated data.
3. Component Pattern: Ensure logic in `entities/unit/components/` is isolated. The `health_component.gd` should only handle health and emit signals; it should not know about the `ai_component.gd`.
4. Strict Typing: Enforce GDScript static typing everywhere (e.g., `var max_health: int = 100`, `func attack(target: Node2D) -> void:`).
5. DRY Principle: Extract duplicated logic into helper functions.

TASK 2: DOCUMENTATION GENERATION
As you review and refactor, you must write a structured markdown document named "Architecture_And_Refactor_Log.md". For every module you process, output an updated section for this document that includes:
- Module Name & Path (e.g., `scripts/entities/unit/unit.gd`)
- Core Responsibility: A brief summary of what this module does.
- Functions List: A bulleted list of its key functions and what they do.
- Refactor Notes: Exactly what spaghetti code or coupling you removed and how you fixed it.

EXECUTION PLAN
We will work step-by-step. Do not assume how a system works until you review all the files for a phase.
- **IMPORTANT**: Handle only **one phase per task/session**. Do not attempt to process all phases at once. Wait for further prompts to proceed to subsequent phases.
- The `Architecture_And_Refactor_Log.md` document must be created/updated inside the `docs/` folder.
- You are free to refactor as needed, remove obsolete scripts, create helper classes, and ensure no legacy code is left behind.
- Perform logical validation during your refactoring to guarantee that all features, gameplay mechanics, and functions are preserved.
- Phase 1: Autoloads & Data Models (`scripts/autoloads/`, `scripts/data/`)
- Phase 2: Managers & AI Framework (`scripts/managers/`, `scripts/ai/`)
- Phase 3: Entities & Components (`scripts/entities/`)
- Phase 4: Map, UI, and VFX (`scripts/map/`, `scripts/ui/`, `scripts/visual_effects/`)
## User Guidelines from Previous Inquiries
1. **Bugs and Missing Code:** While investigating, keep a close eye for bugs or missing code and work to fix it according to the instructions in this section.
2. **Expanding Architecture:** We can create new managers if really needed, but refactoring existing ones should take precedence.
3. **Typing and Syntax:** Find the best practices as an expert.
4. **Log Formatting:** Order modules in the `Architecture_And_Refactor_Log.md` by logical flow.
