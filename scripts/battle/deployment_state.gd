class_name DeploymentState
extends RefCounted

signal skill_fired(unit_id: StringName, target: Vector2i)

const NO_CELL := Vector2i(-1, -1)

class Placement:
	var spec: DeploymentSpec
	var ranger: RangerSpec
	var facility: FacilitySpec
	var stock := 0
	var next_utility_tick := 0
	var records_enhanced: bool
	var skill_charges := 0
	var skill_recharge_tick := 0
	var anchor: Vector2i
	var paid_cost: int
	var hp: int
	var next_attack_tick := 0
	var burst_remaining := 0
	var burst_target := -1
	var build_deadline: int
	var next_payout_tick: int
	var yield_remainder := 0
	var facing: int:
		get:
			return _facing
	var _facing: int

	func _init(definition: DeploymentSpec, cell: Vector2i, direction: int, paid: int, deadline: int, enhancements: Array[StringName]) -> void:
		spec = definition
		ranger = definition as RangerSpec
		facility = definition as FacilitySpec
		if facility != null:
			next_utility_tick = deadline + CombatClock.ticks_for(facility.work_seconds)
		if ranger != null:
			next_utility_tick = deadline + CombatClock.ticks_for(ranger.repair_seconds)
			records_enhanced = ranger.records_enhancement in enhancements
			if ranger.active_skill != null and (not ranger.active_skill.requires_records or records_enhanced):
				skill_charges = ranger.active_skill.max_charges
		hp = spec.max_hp
		anchor = cell
		paid_cost = paid
		build_deadline = deadline
		next_payout_tick = deadline + LogisticsRules.PAYOUT_TICKS
		_facing = -1 if direction < 0 else 1

	func recharge_skill(tick: int) -> void:
		if skill_recharge_tick == 0 or tick < skill_recharge_tick:
			return
		var skill := ranger.active_skill
		skill_charges += 1
		skill_recharge_tick = 0 if skill_charges == skill.max_charges else tick + CombatClock.ticks_for(skill.recharge_seconds)

	func spend_skill_charge(tick: int) -> void:
		skill_charges -= 1
		if skill_recharge_tick == 0:
			skill_recharge_tick = tick + maxi(1, CombatClock.ticks_for(ranger.active_skill.recharge_seconds))

var map: BattleMap
var clock: CombatClock
var tokens: int
var rules: LogisticsRules
var posts_deployed := 0
var placed: Dictionary[StringName, Placement] = {}
var occupancy: Dictionary[Vector2i, StringName] = {}
var armed: StringName
var pending_target := NO_CELL
var last_skill_error := ""
var _ready_tick: Dictionary[StringName, int] = {}
var _enhancements: Array[StringName]

func _init(board: BattleMap, battle_clock: CombatClock, preview_budget := 0, opening: LogisticsRules = null, enhancements: Array[StringName] = []) -> void:
	map = board
	clock = battle_clock
	rules = opening if opening != null else LogisticsRules.new()
	tokens = LogisticsRules.FIXED_STOCKPILE if rules.fixed_stockpile else preview_budget
	_enhancements = enhancements.duplicate()
	clock.stepped.connect(_advance)

func cost_for(spec: DeploymentSpec) -> int:
	if not spec.logistics_post:
		return spec.cost
	if posts_deployed == 0:
		return 0
	return rules.later_post_base_cost + (posts_deployed - 1) * rules.later_post_cost_step

func build_ticks_left(id: StringName) -> int:
	var unit: Placement = placed.get(id)
	return maxi(0, unit.build_deadline - clock.tick) if unit != null else 0

func has_legal_opening(entries: Array[DeploymentSpec]) -> bool:
	for spec in entries:
		var cells := map.ground if spec.is_melee() else map.elevated
		for cell in cells:
			if placement_error(spec, cell).is_empty():
				return true
	return false

func _advance(tick: int, _seconds: float) -> void:
	if not clock.is_running():
		return
	for unit: Placement in placed.values():
		unit.recharge_skill(tick)
		if not unit.spec.logistics_post or tick < unit.next_payout_tick:
			continue
		var amount := unit.yield_remainder + rules.post_yield_numerator(unit.spec.level)
		tokens += floori(float(amount) / LogisticsRules.YIELD_DENOMINATOR)
		unit.yield_remainder = amount % LogisticsRules.YIELD_DENOMINATOR
		unit.next_payout_tick += LogisticsRules.PAYOUT_TICKS

func cooldown_ticks(id: StringName) -> int:
	return maxi(0, _ready_tick.get(id, 0) - clock.tick)

func reduce_deployment_cooldowns(ticks: int) -> void:
	if not clock.is_running() or ticks <= 0:
		return
	for id: StringName in _ready_tick:
		_ready_tick[id] = maxi(clock.tick, _ready_tick[id] - ticks)

func placement_error(spec: DeploymentSpec, anchor: Vector2i) -> String:
	if not clock.is_running():
		return "Deployment is paused."
	if spec.logistics_post:
		if rules.fixed_stockpile:
			return "Fixed Stockpile prohibits Logistics Posts."
		if rules.starter_only and posts_deployed > 0:
			return "This operation supplies one Starter Post."
	elif placed.has(spec.id):
		return "This unit is already deployed."
	if cooldown_ticks(spec.id) > 0:
		return "This deployment is cooling down."
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
	var cost := cost_for(spec)
	if tokens < cost:
		return "Need %d more Logistic Tokens." % (cost - tokens)
	return ""

func deploy(spec: DeploymentSpec, anchor: Vector2i, facing: int) -> String:
	var error := placement_error(spec, anchor)
	if not error.is_empty():
		return error
	var first_post := spec.logistics_post and posts_deployed == 0
	var cost := cost_for(spec)
	var id := spec.id
	if spec.logistics_post:
		posts_deployed += 1
		id = StringName("%s#%d" % [spec.id, posts_deployed])
	var build_ticks := 0 if first_post or spec.is_ranger() else CombatClock.ticks_for(spec.build_seconds)
	for cell in spec.footprint(anchor) + spec.reserved(anchor):
		occupancy[cell] = id
	placed[id] = Placement.new(spec, anchor, facing, cost, clock.tick + build_ticks, _enhancements)
	tokens -= cost
	if not first_post and not spec.is_ranger():
		_ready_tick[spec.id] = clock.tick + CombatClock.ticks_for(spec.build_cooldown_seconds)
	cancel_skill()
	return ""

func cancel_construction(id: StringName) -> bool:
	if not clock.is_running() or build_ticks_left(id) == 0:
		return false
	var unit := placed[id]
	tokens += unit.paid_cost
	_release_cells(id, unit)
	return true

func _release_cells(id: StringName, unit: Placement) -> void:
	for cell in unit.spec.footprint(unit.anchor) + unit.spec.reserved(unit.anchor):
		occupancy.erase(cell)
	placed.erase(id)
	if armed == id:
		cancel_skill()

func retreat(id: StringName) -> bool:
	var unit: Placement = placed.get(id)
	if not clock.is_running() or unit == null or not unit.spec.is_ranger():
		return false
	_release_cells(id, unit)
	_ready_tick[id] = clock.tick + CombatClock.ticks_for(unit.spec.redeploy_seconds)
	return true

static func accepts_hit(spec: DeploymentSpec, kind: EnemyAttackProfile.Kind) -> bool:
	if not spec.is_ranger():
		return kind == EnemyAttackProfile.Kind.SIEGE
	return kind != EnemyAttackProfile.Kind.SIEGE and (kind != EnemyAttackProfile.Kind.MELEE or spec.is_melee())

func receive_hit(id: StringName, damage: int, kind: EnemyAttackProfile.Kind) -> bool:
	var unit: Placement = placed.get(id)
	if not clock.is_running() or damage <= 0 or unit == null or not accepts_hit(unit.spec, kind):
		return false
	unit.hp = maxi(0, unit.hp - damage)
	if unit.hp == 0:
		if unit.spec.is_ranger():
			retreat(id)
		else:
			_release_cells(id, unit)
	return true

static func accepts_repair(spec: DeploymentSpec) -> bool:
	return not spec.is_ranger() or spec.id == &"ranger.barricade_ops"

func repair(id: StringName, amount: int) -> int:
	var unit: Placement = placed.get(id)
	return _restore_hp(unit, amount) if unit != null and accepts_repair(unit.spec) else 0

func heal_ranger(id: StringName, amount: int) -> int:
	var unit: Placement = placed.get(id)
	return _restore_hp(unit, amount) if unit != null and unit.spec.is_ranger() else 0

func _restore_hp(unit: Placement, amount: int) -> int:
	if not clock.is_running() or amount <= 0:
		return 0
	var restored := mini(amount, unit.spec.max_hp - unit.hp)
	unit.hp += restored
	return restored

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

func quick_tap(id: StringName, resolve: Callable = Callable()) -> bool:
	var unit: Placement = placed.get(id)
	last_skill_error = _skill_error(unit)
	if not last_skill_error.is_empty():
		return false
	cancel_skill()
	if unit.spec.skill == DeploymentSpec.Skill.TARGETED:
		armed = id
		return true
	return _activate_skill(unit, id, NO_CELL, resolve)

func select_target(cell: Vector2i) -> bool:
	var unit: Placement = placed.get(armed)
	pending_target = NO_CELL
	if not clock.is_running() or unit == null or not can_attack(unit, cell, false):
		return false
	pending_target = cell
	return true

func confirm_target(resolve: Callable = Callable()) -> bool:
	var unit: Placement = placed.get(armed)
	last_skill_error = _skill_error(unit)
	if not last_skill_error.is_empty():
		return false
	if pending_target == NO_CELL or not can_attack(unit, pending_target, false):
		last_skill_error = "Choose a tile in range."
		return false
	return _activate_skill(unit, armed, pending_target, resolve)

func _skill_error(unit: Placement) -> String:
	if not clock.is_running():
		return "Combat is paused."
	if unit == null or unit.spec.skill == DeploymentSpec.Skill.NONE:
		return "No active skill available."
	if unit.facility != null:
		if clock.tick < unit.build_deadline:
			return "The Facility is still building."
		return "" if unit.stock > 0 else "The Facility has no stock ready."
	if unit.ranger == null:
		return ""
	var skill := unit.ranger.active_skill
	if skill == null:
		return "No active skill available."
	if skill.requires_records and not unit.records_enhanced:
		return "%s requires its Records enhancement." % skill.label
	if unit.skill_charges == 0:
		return "%s is recharging." % skill.label
	return ""

func _activate_skill(unit: Placement, id: StringName, target: Vector2i, resolve: Callable) -> bool:
	if unit.ranger != null or unit.facility != null:
		if not resolve.is_valid():
			last_skill_error = "The active skill needs a battle."
			return false
		last_skill_error = resolve.call(unit, target)
		if not last_skill_error.is_empty():
			return false
		if unit.facility != null:
			unit.stock -= 1
		else:
			unit.spend_skill_charge(clock.tick)
	cancel_skill()
	skill_fired.emit(id, target)
	return true

func cancel_skill() -> void:
	armed = &""
	pending_target = NO_CELL
