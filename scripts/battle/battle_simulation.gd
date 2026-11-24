class_name BattleSimulation
extends RefCounted

signal enemy_spawned(id: int, definition_id: StringName)
signal enemy_resolved(id: int, escaped: bool)
signal enemy_attack_presented(enemy: BattleEnemy)
signal enemy_hit_presented(id: int)
signal siege_hit
signal heat_overflow
signal cinematic_withdrawal
signal before_wave_first_spawn(wave: int)
signal wave_resolved(wave: int)
signal boss_intro(id: int, boss: BossSpec)
signal boss_phase_changed(id: int, phase: BossPhase)
signal boss_captured(id: int)

enum Outcome { RUNNING, WON, LOST }

var deployment: DeploymentState
var clock := CombatClock.new()
var effects: BattleModifiers
var integrity := 100
var heat := 0.0
var defeated := 0
var configured_defeated := 0
var escaped := 0
var expected_enemy_count: int
var captured_boss_id: StringName
var escaped_boss_id: StringName
var fatal_escape_id: StringName
var outcome := Outcome.RUNNING
var active: Dictionary[int, BattleEnemy] = {}
var ranger_combat: RangerCombat
var facility_combat: FacilityCombat
var _enemy_combat := EnemyCombat.new()
var _enemy_abilities := EnemyAbilities.new()
var _boss_combat := BossCombat.new()
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
var _announced_wave := 0

func _init(stage: BattleStage) -> void:
	_stage = stage
	effects = BattleModifiers.new(stage.modifier_ids)
	expected_enemy_count = stage.enemy_count()
	ranger_combat = RangerCombat.new(clock, active)
	ranger_combat.hit.connect(damage_enemy)
	facility_combat = FacilityCombat.new(active)
	facility_combat.hit.connect(damage_enemy)
	_enemy_combat.hit.connect(_receive_enemy_hit)
	for wave in stage.waves:
		if wave.groups.any(func(group: BattleSpawnGroup) -> bool: return group.count > 0):
			_waves.append(wave)
	clock.stepping.connect(_announce_first_spawn)
	clock.stepped.connect(_step)
	_begin_next_wave(1 + CombatClock.ticks_for(stage.opening_delay_seconds))

func defeat_enemy(id: int) -> bool:
	if not clock.is_running() or not active.has(id):
		return false
	var enemy := active[id]
	active.erase(id)
	_boss_combat.active.erase(id)
	defeated += 1
	if not enemy.reinforcement:
		configured_defeated += 1
	var captured := _is_capture_target(enemy)
	if captured:
		captured_boss_id = enemy.definition.enemy_id
		active.clear()
		_boss_combat.clear()
		expected_enemy_count = defeated + escaped
		_finish(Outcome.WON)
	enemy_resolved.emit(id, false)
	if captured:
		boss_captured.emit(id)
		return true
	_try_finish_wave(clock.tick)
	return true

func _is_capture_target(enemy: BattleEnemy) -> bool:
	return not _stage.capture_boss_id.is_empty() and enemy.boss != null and enemy.boss.capturable and enemy.definition.enemy_id == _stage.capture_boss_id

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
	if deployment.receive_hit(id, amount, kind):
		enemy_attack_presented.emit(enemy)
	if kind == EnemyAttackProfile.Kind.SIEGE:
		siege_hit.emit()

func damage_enemy(id: int, damage: int) -> void:
	var enemy: BattleEnemy = active.get(id)
	if enemy == null or damage <= 0 or not clock.is_running():
		return
	var bonus := enemy.damage_mark_bonus(clock.tick)
	var weakness := 1.0
	if effects.amount(&"weakness_damage_percent") > 0 and _has_weakness(enemy):
		weakness = effects.scale(&"weakness_damage_percent")
	var effective := roundi(damage * weakness * (100 + bonus) / 100.0)
	enemy.take_damage(effective, clock.tick)
	if enemy.hp == 0:
		defeat_enemy(id)
	else:
		enemy_hit_presented.emit(id)

func _has_weakness(enemy: BattleEnemy) -> bool:
	if enemy.is_marked(clock.tick) or clock.tick < enemy.sonic_slow_until or ranger_combat.movement_scale(enemy, clock.tick) < 1.0:
		return true
	if deployment == null:
		return false
	var disruption := facility_combat.disruption_at(deployment, enemy.grid_cell(), clock.tick)
	return disruption != null and disruption.outgoing_reduction_percent > 0

func recon_entries() -> Array[Vector2i]:
	var entries: Array[Vector2i] = []
	var lead := CombatClock.ticks_for(effects.amount(&"recon_seconds"))
	if lead <= 0 or clock.stopped or _groups.is_empty() or _group_index != 0 or _spawned_in_group != 0 or _next_spawn_tick - clock.tick > lead:
		return entries
	for group in _groups:
		var cell: Vector2i = _stage.routes[group.route_index].cells.front()
		if cell not in entries:
			entries.append(cell)
	return entries

func recon_seconds_left() -> int:
	return ceili(float(_next_spawn_tick - clock.tick) / CombatClock.TICKS_PER_SECOND)

func _announce_first_spawn(tick: int) -> void:
	if wave_number > _announced_wave and tick >= _next_spawn_tick:
		_announced_wave = wave_number
		before_wave_first_spawn.emit(wave_number)

func _step(tick: int, seconds: float) -> void:
	_advance_boss_phases(tick)
	if not clock.is_running():
		return
	ranger_combat.expire_fields(tick)
	if deployment != null:
		for unit: DeploymentState.Placement in deployment.placed.values():
			unit.blocking_count = 0
	# Stable insertion order makes simultaneous arrivals deterministic.
	var block_counts: Dictionary[StringName, int] = {}
	for id: int in active.keys():
		var enemy := active[id]
		var arrived := _advance_enemy(enemy, tick, seconds, block_counts)
		if arrived:
			active.erase(id)
			_boss_combat.active.erase(id)
			escaped += 1
			var fatal := enemy.definition.escape_causes_defeat or _is_capture_target(enemy)
			if enemy.boss != null:
				escaped_boss_id = enemy.definition.enemy_id
			if fatal:
				fatal_escape_id = enemy.definition.enemy_id
			lose_integrity(integrity if fatal else enemy.definition.escape_penalty)
			enemy_resolved.emit(id, true)
			if not clock.is_running():
				return
	if _group_index < _groups.size() and tick >= _next_spawn_tick:
		_spawn(tick)
	elif _boss_combat.has_pending_arrivals():
		var arrived := _boss_combat.take_due(tick)
		if arrived != null:
			_register_enemy(arrived.enemy, arrived.route, tick, true)
	if not clock.is_running():
		return
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
			if unit.spec.is_ranger() and (unit.spec.attack_damage > 0 or (unit.ranger != null and unit.ranger.heal_hp > 0)):
				var interval := facility_combat.attack_interval(deployment, unit, tick)
				ranger_combat.basic_attack(unit, deployment, tick, interval)
				if not clock.is_running():
					return
	_try_finish_wave(tick)

func _advance_boss_phases(tick: int) -> void:
	for id: int in _boss_combat.active.keys():
		var enemy: BattleEnemy = _boss_combat.active.get(id)
		if enemy == null:
			continue
		var phase := _boss_combat.enter_next_phase(enemy, tick)
		if phase != null:
			expected_enemy_count += phase.reinforcement_count
			boss_phase_changed.emit(id, phase)
			if not clock.is_running():
				return

func _advance_heat(tick: int, seconds: float) -> void:
	if _stage.heat_capacity <= 0.0:
		return
	var rate := 0.0
	for enemy: BattleEnemy in active.values():
		rate += enemy.definition.heat_per_second + enemy.phase_heat_bonus
	if rate <= 0.0:
		return
	var scale := facility_combat.heat_multiplier(deployment, tick) if deployment != null else 1.0
	heat += rate * seconds * scale * _stage.heat_gain_scale
	if heat > _stage.heat_capacity or is_equal_approx(heat, _stage.heat_capacity):
		heat = 0.0
		heat_overflow.emit()
		lose_integrity(_stage.heat_integrity_loss)

func _advance_enemy(enemy: BattleEnemy, tick: int, seconds: float, block_counts: Dictionary[StringName, int]) -> bool:
	var speed_scale := ranger_combat.movement_scale(enemy, tick)
	if tick < enemy.sonic_slow_until:
		speed_scale = minf(speed_scale, enemy.sonic_speed_scale)
	seconds *= speed_scale * enemy.sprint_scale(tick) * enemy.phase_speed_scale * _boss_combat.movement_support(enemy)
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
		deployment.placed[blocker].blocking_count = block_counts[blocker]
		if enemy.definition.attack_profile == null and tick >= enemy.next_attack_tick and tick >= enemy.stunned_until:
			_receive_enemy_hit(enemy, blocker, EnemyAttackProfile.Kind.MELEE)
			enemy.next_attack_tick = tick + CombatClock.ticks_for(enemy.definition.attack_seconds)
	return enemy.advance(seconds, stop_at)

func _spawn(tick: int) -> void:
	var group := _groups[_group_index]
	_spawned_in_group += 1
	_next_spawn_tick = tick + maxi(1, CombatClock.ticks_for(group.interval_seconds))
	if _spawned_in_group == group.count:
		_group_index += 1
		_spawned_in_group = 0
	_register_enemy(group.enemy, _stage.routes[group.route_index], tick)

func _register_enemy(definition: BattleEnemyDefinition, route: BattleRoute, tick: int, reinforcement := false) -> void:
	var id := _next_id
	_next_id += 1
	var enemy := BattleEnemy.new(definition, route, tick)
	enemy.reinforcement = reinforcement
	if definition.concealed:
		enemy.revealed_until = tick + CombatClock.ticks_for(effects.amount(&"reveal_seconds"))
	active[id] = enemy
	if enemy.boss != null:
		_boss_combat.active[id] = enemy
	enemy_spawned.emit(id, definition.enemy_id)
	if enemy.boss != null and clock.is_running() and active.has(id):
		boss_intro.emit(id, enemy.boss)

func _try_finish_wave(tick: int) -> void:
	if outcome == Outcome.RUNNING and _group_index == _groups.size() and active.is_empty() and not _boss_combat.has_pending_arrivals():
		var completed := wave_number
		var rest := CombatClock.ticks_for(_waves[completed - 1].rest_after_seconds)
		_begin_next_wave(tick + maxi(1, rest))
		wave_resolved.emit(completed)

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
