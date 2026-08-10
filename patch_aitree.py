import re

with open('./scripts/ai/ai_tree_evaluator.gd', 'r') as f:
    content = f.read()

# Add AI_CONDITION logs and PATHFINDING logs to the result
# Let's replace the template evaluation blocks to add telemetry_entries, but AITreeEvaluator returns a single telemetry_entry currently (or we can return an array).
# Actually, the result dict only supports a single `telemetry_entry` which is a dict. Let's change it to an array `telemetry_entries`.
# Wait, SimulationServer doesn't read `telemetry_entry` from `eval_result` anyway in its loop? Let me check SimulationServer!
