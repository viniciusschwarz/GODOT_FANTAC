import re

with open('./scripts/sim/simulation_server.gd', 'r') as f:
    content = f.read()

# Add log_ui_intent logging
content = re.sub(
    r'has_override = true\n\t\t\t\t\tvar target_id = directive.target_id',
    r'has_override = true\n\t\t\t\t\tvar target_id = directive.target_id\n\t\t\t\t\ttelemetry_events.append(TurnTelemetryLogger.log_ui_intent(current_tick, unit_id, target_id, "ATTACK"))',
    content
)

with open('./scripts/sim/simulation_server.gd', 'w') as f:
    f.write(content)
