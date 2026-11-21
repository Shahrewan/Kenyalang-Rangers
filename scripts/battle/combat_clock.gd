class_name CombatClock
extends RefCounted

signal stepped(tick: int, seconds: float)

const TICKS_PER_SECOND := 60
const STEP_SECONDS := 1.0 / TICKS_PER_SECOND

var paused := false
var dialogue_open := false
var stopped := false
var tick := 0
var _speed := 1

func set_speed(multiplier: int) -> void:
	_speed = clampi(multiplier, 1, 2)

func get_speed() -> int:
	return _speed

func is_running() -> bool:
	return not paused and not dialogue_open and not stopped

# The scene feeds one fixed physics frame at a time. Every gameplay system uses
# the same stepped signal, and 2× repeats the small step instead of enlarging it.
func advance_frame() -> void:
	for step in _speed:
		if not is_running():
			break
		tick += 1
		stepped.emit(tick, STEP_SECONDS)

static func ticks_for(seconds: float) -> int:
	return ceili(seconds * TICKS_PER_SECOND)
