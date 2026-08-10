import re

with open("scripts/sim/simulation_server.gd", "r") as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    if "class_name SimulationServer extends RefCounted" in line:
        new_lines.append(line)
        new_lines.append("\nvar telemetry_logger: TurnTelemetryLogger = TurnTelemetryLogger.new()\n")
    elif "var active_projectiles: Array[Dictionary] = []" in line:
        new_lines.append("	telemetry_logger.reset_turn_cache()\n")
        new_lines.append(line)
    elif "ai_evaluator.evaluate_unit_behavior" in line:
        new_lines.append(line.replace("current_tick)", "current_tick, telemetry_logger)"))
    elif "telemetry_events.append(" in line:
        # replace with _append_telemetry
        if "telemetry_events.append(t_entry)" in line:
            new_lines.append(line.replace("telemetry_events.append(t_entry)", "_append_telemetry(telemetry_events, t_entry)"))
        elif "telemetry_events.append(telemetry_logger.log_" in line:
            new_lines.append(line.replace("telemetry_events.append(", "_append_telemetry(telemetry_events, "))
        elif "telemetry_events.append({\"tick\"" in line:
            new_lines.append(line.replace("telemetry_events.append(", "_append_telemetry(telemetry_events, "))
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

new_lines.append("""
func _append_telemetry(events: Array, event: Dictionary) -> void:
	if not event.is_empty():
		events.append(event)
""")

with open("scripts/sim/simulation_server.gd", "w") as f:
    f.writelines(new_lines)
