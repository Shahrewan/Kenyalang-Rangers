class_name BossCombat
extends RefCounted

class Arrival:
	var enemy: BattleEnemyDefinition
	var route: BattleRoute
	var remaining: int
	var next_tick: int
	var interval: int

var active: Dictionary[int, BattleEnemy] = {}
var _arrivals: Array[Arrival] = []

func enter_next_phase(enemy: BattleEnemy, tick: int) -> BossPhase:
	if enemy.boss == null or enemy.phase_index >= enemy.boss.phases.size():
		return null
	var phase := enemy.boss.phases[enemy.phase_index]
	if enemy.hp * 100 > enemy.boss.max_hp * phase.hp_percent:
		return null
	enemy.phase_index += 1
	enemy.phase_speed_scale = phase.speed_scale
	enemy.phase_heat_bonus = phase.extra_heat_per_second
	if phase.temporary_hp > 0:
		enemy.shield_hp = phase.temporary_hp
		enemy.shield_until = tick + CombatClock.ticks_for(phase.protection_seconds)
	if phase.reinforcement_count > 0:
		var order := Arrival.new()
		order.enemy = phase.reinforcement
		order.route = enemy.route
		order.remaining = phase.reinforcement_count
		order.next_tick = tick + maxi(1, CombatClock.ticks_for(phase.reinforcement_delay_seconds))
		order.interval = maxi(1, CombatClock.ticks_for(phase.reinforcement_interval_seconds))
		_arrivals.append(order)
	return phase

func take_due(tick: int) -> Arrival:
	for index in _arrivals.size():
		var order := _arrivals[index]
		if tick < order.next_tick:
			continue
		order.remaining -= 1
		if order.remaining == 0:
			_arrivals.remove_at(index)
		else:
			order.next_tick = tick + order.interval
		return order
	return null

func has_pending_arrivals() -> bool:
	return not _arrivals.is_empty()

func clear() -> void:
	active.clear()
	_arrivals.clear()

func movement_support(enemy: BattleEnemy) -> float:
	if enemy.boss != null or active.is_empty():
		return 1.0
	var scale := 1.0
	var cell := enemy.grid_cell()
	for source: BattleEnemy in active.values():
		var offset := (source.grid_cell() - cell).abs()
		if maxi(offset.x, offset.y) <= source.boss.ally_speed_radius:
			scale = maxf(scale, source.boss.ally_speed_scale)
	return scale
