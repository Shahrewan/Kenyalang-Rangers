class_name DeploymentGesture
extends RefCounted

enum Release { NONE, DROP, TAP, HOLD, TARGET }

const HOLD_MS := 350
const SLOP := 14.0

var dragging: DeploymentSpec
var unit: StringName
var held := false
var moved := false
var _targeting := false
var _start := Vector2.ZERO
var _pressed_ms := 0

func press(at: Vector2, now_ms: int, card: DeploymentSpec, actor: StringName, targeting: bool) -> void:
	reset()
	dragging = card
	unit = actor
	_targeting = targeting
	_start = at
	_pressed_ms = now_ms

func motion(at: Vector2) -> void:
	moved = moved or _start.distance_to(at) > SLOP

func reveal_hold(now_ms: int) -> bool:
	if held or moved or _targeting or unit.is_empty() or now_ms - _pressed_ms < HOLD_MS:
		return false
	held = true
	return true

func release(at: Vector2, now_ms: int) -> Release:
	motion(at)
	if dragging != null:
		return Release.DROP if moved else Release.NONE
	if held or reveal_hold(now_ms):
		return Release.HOLD
	if moved:
		return Release.NONE
	if _targeting:
		return Release.TARGET
	return Release.TAP if not unit.is_empty() else Release.NONE

func reset() -> void:
	dragging = null
	unit = &""
	held = false
	moved = false
	_targeting = false
