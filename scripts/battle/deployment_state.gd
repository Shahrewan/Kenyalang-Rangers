class_name DeploymentState
extends RefCounted

signal skill_fired(unit_id: StringName, target: Vector2i)

const NO_CELL := Vector2i(-1, -1)

class Placement:
	var spec: DeploymentSpec
	var anchor: Vector2i
	var facing: int:
		get:
			return _facing
	var _facing: int

	func _init(definition: DeploymentSpec, cell: Vector2i, direction: int) -> void:
		spec = definition
		anchor = cell
		_facing = -1 if direction < 0 else 1

var map: BattleMap
var clock: CombatClock
var tokens: int
var placed: Dictionary[StringName, Placement] = {}
var occupancy: Dictionary[Vector2i, StringName] = {}
var armed: StringName
var pending_target := NO_CELL
var _ready_tick: Dictionary[StringName, int] = {}

func _init(board: BattleMap, battle_clock: CombatClock, preview_budget: int) -> void:
	map = board
	clock = battle_clock
	tokens = preview_budget

func cooldown_ticks(id: StringName) -> int:
	return maxi(0, _ready_tick.get(id, 0) - clock.tick)

func placement_error(spec: DeploymentSpec, anchor: Vector2i) -> String:
	if not clock.is_running():
		return "Deployment is paused."
	if placed.has(spec.id):
		return "This unit is already deployed."
	if cooldown_ticks(spec.id) > 0:
		return "This Ranger is cooling down."
	var bounds := Rect2i(Vector2i.ZERO, map.size)
	var required := BattleMap.Tile.GROUND if spec.is_melee() else BattleMap.Tile.ELEVATED
	for cell in spec.footprint(anchor):
		if not bounds.has_point(cell):
			return "The footprint extends off the board."
		if occupancy.has(cell):
			return "A footprint cell is occupied."
		if map.tile_at(cell) != required:
			return "Ground tiles required." if spec.is_melee() else "Elevated tiles required."
	for cell in spec.reserved(anchor):
		if not bounds.has_point(cell) or cell in map.spawns or cell == map.tunnel or occupancy.has(cell):
			return "The clearance cell above is unavailable."
	if tokens < spec.cost:
		return "Need %d more Logistic Tokens." % (spec.cost - tokens)
	return ""

func deploy(spec: DeploymentSpec, anchor: Vector2i, facing: int) -> String:
	var error := placement_error(spec, anchor)
	if not error.is_empty():
		return error
	for cell in spec.footprint(anchor) + spec.reserved(anchor):
		occupancy[cell] = spec.id
	placed[spec.id] = Placement.new(spec, anchor, facing)
	tokens -= spec.cost
	cancel_skill()
	return ""

func retreat(id: StringName) -> bool:
	var unit: Placement = placed.get(id)
	if not clock.is_running() or unit == null or not unit.spec.is_ranger():
		return false
	for cell in unit.spec.footprint(unit.anchor) + unit.spec.reserved(unit.anchor):
		occupancy.erase(cell)
	placed.erase(id)
	_ready_tick[id] = clock.tick + CombatClock.ticks_for(unit.spec.redeploy_seconds)
	if armed == id:
		cancel_skill()
	return true

func coverage(spec: DeploymentSpec, anchor: Vector2i, facing: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if spec.attack_range <= 0:
		return cells
	if spec.is_melee():
		var front := anchor
		if facing > 0 and spec.kind == DeploymentSpec.Kind.GROUND_PAIR:
			front += Vector2i.RIGHT
		for distance in range(1, spec.attack_range + 1):
			cells.append(front + Vector2i(facing * distance, 0))
	else:
		for y in range(-spec.attack_range, spec.attack_range + 1):
			for x in range(-spec.attack_range, spec.attack_range + 1):
				cells.append(anchor + Vector2i(x, y))
	var bounds := Rect2i(Vector2i.ZERO, map.size)
	return cells.filter(func(cell: Vector2i) -> bool: return bounds.has_point(cell))

func can_attack(unit: Placement, cell: Vector2i, aerial: bool) -> bool:
	if aerial and (unit.spec.is_melee() or not unit.spec.targets_aerial):
		return false
	return cell in coverage(unit.spec, unit.anchor, unit.facing)

func quick_tap(id: StringName) -> bool:
	var unit: Placement = placed.get(id)
	if not clock.is_running() or unit == null or unit.spec.skill == DeploymentSpec.Skill.NONE:
		return false
	cancel_skill()
	if unit.spec.skill == DeploymentSpec.Skill.TARGETED:
		armed = id
	else:
		skill_fired.emit(id, NO_CELL)
	return true

func select_target(cell: Vector2i) -> bool:
	var unit: Placement = placed.get(armed)
	pending_target = NO_CELL
	if not clock.is_running() or unit == null or not can_attack(unit, cell, false):
		return false
	pending_target = cell
	return true

func confirm_target() -> bool:
	if not clock.is_running() or armed.is_empty() or pending_target == NO_CELL:
		return false
	var id := armed
	var target := pending_target
	cancel_skill()
	skill_fired.emit(id, target)
	return true

func cancel_skill() -> void:
	armed = &""
	pending_target = NO_CELL
