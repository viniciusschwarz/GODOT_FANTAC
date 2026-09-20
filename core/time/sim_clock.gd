class_name SimClock
extends RefCounted

var current_tick: int = 0
var tick_rate_hz: int = 30
var tick_step_usec: int = 33333 # 1_000_000 / 30
var speed_multiplier: int = 1   # 0=Paused, 1=1x, 2=2x, 5=5x
var accumulated_usec: int = 0

func advance_accumulator(delta_usec: int) -> int:
	if speed_multiplier == 0:
		return 0
	accumulated_usec += delta_usec * speed_multiplier
	var available_ticks: int = accumulated_usec / tick_step_usec
	if available_ticks > 10:
		available_ticks = 10
	return available_ticks

func step_tick() -> int:
	accumulated_usec -= tick_step_usec
	current_tick += 1
	return current_tick

func set_speed(multiplier: int) -> void:
	speed_multiplier = multiplier

func is_paused() -> bool:
	return speed_multiplier == 0

func reset() -> void:
	current_tick = 0
	accumulated_usec = 0
