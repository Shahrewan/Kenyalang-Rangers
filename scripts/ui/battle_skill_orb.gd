class_name BattleSkillOrb
extends RefCounted

const DIAMETER := 17.0
const RIM := Color("#22352b")
const FACE := Color("#596359")
const READY := Color("#426d51")
const FLASH := Color("#81a77b")
const GOLD := Color("#edca76")
const PAPER := Color("#fff0cc")
const GLYPHS := {
	BattleSkillStatus.Mode.READY: preload("res://assets/imported/ui/w29/icons/light/check.svg"),
	BattleSkillStatus.Mode.LOCKED: preload("res://assets/imported/ui/w29/icons/light/lock.svg"),
	BattleSkillStatus.Mode.SPENT: preload("res://assets/imported/ui/w29/icons/light/minus.svg"),
}

class Placement:
	var area: Rect2
	var status: BattleSkillStatus
	var center: Vector2
	var bounds: Rect2

var placements: Dictionary[StringName, Placement] = {}
var _reserved: Array[Rect2] = []

func reset() -> void:
	placements.clear()
	_reserved.clear()

func protect(area: Rect2) -> void:
	if area.has_area():
		_reserved.append(area)

func add(id: StringName, area: Rect2, status: BattleSkillStatus) -> void:
	protect(area)
	if status == null:
		return
	var orb := Placement.new()
	orb.area = area
	orb.status = status
	placements[id] = orb

static func radius_for(tile: float) -> float:
	return DIAMETER * tile / 160.0

static func ring_sweep(status: BattleSkillStatus) -> float:
	if status.mode in [BattleSkillStatus.Mode.READY, BattleSkillStatus.Mode.RECOVERING] and status.progress >= 0.0:
		return TAU * clampf(status.progress, 0.0, 1.0)
	return -1.0

static func paint_bounds(center: Vector2, radius: float, has_number: bool) -> Rect2:
	var outer := radius * 1.07
	var bounds := Rect2(center - Vector2.ONE * outer, Vector2.ONE * outer * 2.0)
	if has_number:
		var badge_at := center + Vector2(0.78, 0.60) * radius
		var badge_radius := radius * 0.61
		bounds = bounds.merge(Rect2(badge_at - Vector2.ONE * badge_radius, Vector2.ONE * badge_radius * 2.0))
	return bounds

func arrange(tile: float, viewport: Rect2) -> void:
	var radius := radius_for(tile)
	var occupied := _reserved.duplicate()
	# Placement IDs keep priority stable when animation changes sprite depth.
	var ids := placements.keys()
	ids.sort()
	for id: StringName in ids:
		var orb := placements[id]
		orb.center = _nearby(orb.area, radius, orb.status.maximum > 1, viewport, occupied)
		orb.bounds = paint_bounds(orb.center, radius, orb.status.maximum > 1)
		occupied.append(orb.bounds.grow(1.0))

static func _nearby(area: Rect2, radius: float, has_number: bool, viewport: Rect2, occupied: Array[Rect2]) -> Vector2:
	var padding := paint_bounds(Vector2.ZERO, radius, has_number).grow(1.0)
	var low := viewport.position - padding.position
	var high := (viewport.end - padding.end).max(low)
	var right := area.end.x - padding.position.x + 1.0
	var left := area.position.x - padding.end.x - 1.0
	var top := area.position.y - padding.end.y - 1.0
	var shoulder := area.position.y - radius * 0.18
	var candidates := [
		Vector2(right, shoulder),
		Vector2(left, shoulder),
		Vector2(area.end.x - radius * 0.5, top),
		Vector2(area.position.x + radius * 0.5, top),
		Vector2(area.get_center().x, top),
		Vector2(right, shoulder - radius),
		Vector2(left, shoulder - radius),
	]
	var center := Vector2.ZERO
	var best := INF
	for candidate: Vector2 in candidates:
		var safe := candidate.clamp(low, high)
		var box := paint_bounds(safe, radius, has_number)
		var score := safe.distance_squared_to(candidate) * 0.2
		for area_to_avoid: Rect2 in occupied:
			score += box.intersection(area_to_avoid).get_area() * 4.0
		if is_zero_approx(score):
			return safe
		if score < best:
			best = score
			center = safe
	return center

func draw(board: Control, tile: float) -> void:
	var radius := radius_for(tile)
	arrange(tile, Rect2(Vector2.ZERO, board.size))
	for orb: Placement in placements.values():
		_draw_orb(board, orb, radius)

static func _draw_orb(board: Control, orb: Placement, radius: float) -> void:
	var status := orb.status
	var at := orb.center
	var ready := status.mode == BattleSkillStatus.Mode.READY
	var face := (FLASH if status.just_ready else READY) if ready else FACE
	board.draw_circle(at, radius * 1.07, RIM, true, -1, true)
	board.draw_circle(at, radius * 0.86, face, true, -1, true)
	board.draw_circle(at - Vector2(0, radius * 0.14), radius * 0.68, face.lightened(0.10), true, -1, true)
	var sweep := ring_sweep(status)
	if sweep >= 0.0:
		var ring := radius * 0.88
		var stroke := maxf(1.0, radius * 0.15)
		board.draw_arc(at, ring, 0.0, TAU, 24, Color("#aaa186"), stroke, true)
		if sweep > 0.0:
			board.draw_arc(at, ring, -PI / 2.0, sweep - PI / 2.0, 24, GOLD, stroke, true)
	elif ready:
		board.draw_circle(at, radius * 0.85, GOLD if status.just_ready else Color("#b5cea1"), false, 1.0, true)
	if GLYPHS.has(status.mode):
		var width := radius * 1.02
		var glyph := Rect2(at - Vector2.ONE * width * 0.5, Vector2.ONE * width)
		board.draw_texture_rect(GLYPHS[status.mode], glyph, false, PAPER)
	else:
		board.draw_circle(at, radius * 0.18, PAPER, true, -1, true)
	if status.maximum > 1:
		var badge := at + Vector2(0.78, 0.60) * radius
		var font := board.get_theme_default_font()
		var font_size := maxi(7, roundi(radius * 1.05))
		var number := str(status.charges)
		var text_width := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		board.draw_circle(badge, radius * 0.61, RIM, true, -1, true)
		board.draw_string(font, badge + Vector2(-text_width * 0.5, baseline), number,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PAPER)
