# File: res://core/autoloads/event_bus.gd
extends Node

## GLOBAL EVENT BUS
## Centralized signal registry for strictly decoupled cross-domain communication.

# -- Combat & Turn Phases --
signal turn_phase_changed(new_phase: StringName)
signal execution_tick(delta: float)
signal execution_finished()
signal combat_ended()

# -- Unit Lifecycle & Actions --
signal unit_spawned(unit: Node)
signal unit_died(unit: Node)

## Broadcast when a unit successfully updates its physical coordinate
signal unit_moved(unit_reference: Node, old_coord: Vector3i, new_coord: Vector3i)

# -- Modifiers --
signal unit_modifier_added(unit_id: StringName, mod_data: Resource)
signal unit_modifier_removed(unit_id: StringName, mod_data: Resource)

# -- Visuals & Camera --
## Broadcast when the player changes the Z-level slicing focus
signal camera_z_level_changed(focus_z: int)
