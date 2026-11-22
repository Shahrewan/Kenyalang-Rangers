class_name BattleSimulation
extends RefCounted

signal enemy_spawned(id: int, definition_id: StringName)
signal enemy_resolved(id: int, escaped: bool)
signal cinematic_withdrawal

enum Outcome { RUNNING, WON, LOST }

var deployment: DeploymentState
var clock := CombatClock.new()
var integrity := 100
var heat := 0.0
var defeated := 0
var escaped := 0
var outcome := Outcome.RUNNING
var active: Dictionary[int, BattleEnemy] = {}
var ranger_combat: RangerCombat
var facility_combat: FacilityCombat
var _enemy_combat := EnemyCombat.new()
var _enemy_abilities := EnemyAbilities.new()
var wave_number := 0
var wave_count: int:
	get:
		return _waves.size()

var _stage: BattleStage
var _waves: Array[BattleWave] = []
var _groups: Array[BattleSpawnGroup] = []
var _group_index := 0
var _spawned_in_group := 0
var _next_spawn_tick := 1
var _next_id := 1

func _init(stage: BattleStage) -> void:
	_stage = stage
	ranger_combat = RangerCombat.new(clock, active)
	ranger_combat.hit.connect(damage_enemy)
	facility_combat = FacilityCombat.new(active)
	facility_combat.hit.connect(damage_enemy)
	_enemy_combat.hit.connect(_receive_enemy_hit)
	for wave in stage.waves:
		if wave.groups.any(func(group: BattleSpawnGroup) -> bool: return group.count > 0):
			_waves.append(wave)
	clock.stepped.connect(_step)
	_begin_next_wave(1 + CombatClock.ticks_for(stage.opening_delay_seconds))

func defeat_enemy(id: int) -> bool:
	if not clock.is_running() or not active.has(id):
		return false
	active.erase(id)
	defeated += 1
	enemy_resolved.emit(id, false)
	_try_finish_wave(clock.tick)
	return true

func record_cinematic_withdrawal() -> void:
	cinematic_withdrawal.emit()

func lose_integrity(amount: int) -> void:
	if amount <= 0 or not clock.is_running():
		return
	integrity = maxi(0, integrity - amount)
	if integrity == 0:
		_finish(Outcome.LOST)

func is_perfect() -> bool:
	return outcome == Outcome.WON and escaped == 0

func tap_ranger(id: StringName) -> bool:
	return tap_unit(id)

func confirm_ranger_target() -> bool:
	return confirm_skill_target()

func tap_unit(id: StringName) -> bool:
	return deployment != null and deployment.quick_tap(id, _use_skill)

func confirm_skill_target() -> bool:
	return deployment != null and deployment.confirm_target(_use_skill)

func _use_skill(unit: DeploymentState.Placement, target: Vector2i) -> String:
	if unit.facility != null:
		return facility_combat.use_skill(unit, target, deployment)
	var interval := facility_combat.attack_interval(deployment, unit, clock.tick)
	return ranger_combat.use_skill(unit, target, deployment, interval)

func _receive_enemy_hit(enemy: BattleEnemy, id: StringName, kind: EnemyAttackProfile.Kind) -> void:
	var target: DeploymentState.Placement = deployment.placed.get(id)
	if target == null:
		return
	var amount := facility_combat.enemy_damage(deployment, enemy, target, clock.tick)
	deployment.receive_hit(id, amount, kind)

func damage_enemy(id: int, damage: int) -> void:
	var enemy: BattleEnemy = active.get(id)
	if enemy == null or damage <= 0 or not clock.is_running():
		return
	var bonus := enemy.damage_mark_bonus(clock.tick)
	var effective := roundi(damage * (100 + bonus) / 100.0)
	enemy.hp = maxi(0, enemy.hp - effective)
	if enemy.hp == 0:
		defeat_enemy(id)

func _step(tick: int, seconds: float) -> void:
	ranger_combat.expire_fields(tick)
	# Stable insertion order makes simultaneous arrivals deterministic.
	var block_counts: Dictionary[StringName, int] = {}
	for id: int in active.keys():
		var enemy := active[id]
		var arrived := _advance_enemy(enemy, tick, seconds, block_counts)
		if arrived:
			active.erase(id)
			escaped += 1
			lose_integrity(integrity if enemy.definition.escape_causes_defeat else enemy.definition.escape_penalty)
			enemy_resolved.emit(id, true)
			if not clock.is_running():
				return
	if _group_index < _groups.size() and tick >= _next_spawn_tick:
		_spawn(tick)
	for enemy: BattleEnemy in active.values():
		_enemy_abilities.advance(enemy, deployment, facility_combat, tick)
	if deployment != null:
		for enemy: BattleEnemy in active.values():
			_enemy_combat.advance(enemy, deployment, facility_combat, tick)
		facility_combat.update_detection(deployment, tick)
	_advance_heat(tick, seconds)
	if not clock.is_running():
		return
	if deployment != null:
		facility_combat.advance(deployment, tick)
		if not clock.is_running():
			return
		for unit: DeploymentState.Placement in deployment.placed.values():
			if unit.spec.is_ranger() and unit.spec.attack_damage > 0:
				var interval := facility_combat.attack_interval(deployment, unit, tick)
				ranger_combat.basic_attack(unit, deployment, tick, interval)
	_try_finish_wave(tick)

func _advance_heat(tick: int, seconds: float) -> void:
	if _stage.heat_capacity <= 0.0:
		return
	var rate := 0.0
	for enemy: BattleEnemy in active.values():
		rate += enemy.definition.heat_per_second
	if rate <= 0.0:
		return
	var scale := facility_combat.heat_multiplier(deployment, tick) if deployment != null else 1.0
	heat += rate * seconds * scale
	if heat > _stage.heat_capacity or is_equal_approx(heat, _stage.heat_capacity):
		heat = 0.0
		lose_integrity(_stage.heat_integrity_loss)

func _advance_enemy(enemy: BattleEnemy, tick: int, seconds: float, block_counts: Dictionary[StringName, int]) -> bool:
	var speed_scale := ranger_combat.movement_scale(enemy, tick)
	if tick < enemy.sonic_slow_until:
		speed_scale = minf(speed_scale, enemy.sonic_speed_scale)
	seconds *= speed_scale * enemy.sprint_scale(tick)
	if deployment == null or enemy.definition.aerial:
		return enemy.advance(seconds)
	var next := enemy.distance + enemy.definition.tiles_per_second * seconds
	var stop_at := INF
	var blocker: StringName
	for id: StringName in deployment.placed:
		var unit := deployment.placed[id]
		if tick < unit.knocked_down_until or unit.spec.block_capacity <= int(block_counts.get(id, 0)):
			continue
		for tile in unit.spec.footprint(unit.anchor):
			var route_index := enemy.route.cells.find(tile)
			# The enemy stays on the approach tile, facing the Ranger on the next tile.
			var approach := float(route_index) - 0.51
			if route_index > 0 and enemy.distance <= approach and next >= approach and approach < stop_at:
				stop_at = approach
				blocker = id
	if blocker != enemy.blocked_by:
		enemy.blocked_by = blocker
		enemy.next_attack_tick = tick + CombatClock.ticks_for(enemy.definition.attack_seconds)
	if not blocker.is_empty():
		block_counts[blocker] = int(block_counts.get(blocker, 0)) + 1
		if enemy.definition.attack_profile == null and tick >= enemy.next_attack_tick and tick >= enemy.stunned_until:
			_receive_enemy_hit(enemy, blocker, EnemyAttackProfile.Kind.MELEE)
			enemy.next_attack_tick = tick + CombatClock.ticks_for(enemy.definition.attack_seconds)
	return enemy.advance(seconds, stop_at)

func _spawn(tick: int) -> void:
	var group := _groups[_group_index]
	var id := _next_id
	_next_id += 1
	active[id] = BattleEnemy.new(group.enemy, _stage.routes[group.route_index], tick)
	_spawned_in_group += 1
	_next_spawn_tick = tick + maxi(1, CombatClock.ticks_for(group.interval_seconds))
	if _spawned_in_group == group.count:
		_group_index += 1
		_spawned_in_group = 0
	enemy_spawned.emit(id, group.enemy.enemy_id)

func _try_finish_wave(tick: int) -> void:
	if outcome == Outcome.RUNNING and _group_index == _groups.size() and active.is_empty():
		var rest := CombatClock.ticks_for(_waves[wave_number - 1].rest_after_seconds)
		_begin_next_wave(tick + maxi(1, rest))

func _begin_next_wave(first_tick: int) -> void:
	if wave_number >= _waves.size():
		_finish(Outcome.WON)
		return
	_groups.assign(_waves[wave_number].groups.filter(func(group: BattleSpawnGroup) -> bool: return group.count > 0))
	wave_number += 1
	_group_index = 0
	_spawned_in_group = 0
	_next_spawn_tick = first_tick

func _finish(result: Outcome) -> void:
	outcome = result
	clock.stopped = true
