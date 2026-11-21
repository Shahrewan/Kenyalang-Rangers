class_name BattleSimulation
extends RefCounted

signal enemy_spawned(id: int, definition_id: StringName)
signal enemy_resolved(id: int, escaped: bool)
signal cinematic_withdrawal

enum Outcome { RUNNING, WON, LOST }

var clock := CombatClock.new()
var integrity := 100
var defeated := 0
var escaped := 0
var outcome := Outcome.RUNNING
var active: Dictionary[int, BattleEnemy] = {}
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
	for wave in stage.waves:
		if wave.groups.any(func(group: BattleSpawnGroup) -> bool: return group.count > 0):
			_waves.append(wave)
	clock.stepped.connect(_step)
	_begin_next_wave(1)

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

func _step(tick: int, seconds: float) -> void:
	# Stable insertion order makes simultaneous arrivals deterministic.
	for id: int in active.keys():
		var enemy := active[id]
		if enemy.advance(seconds):
			active.erase(id)
			escaped += 1
			lose_integrity(enemy.definition.escape_penalty)
			enemy_resolved.emit(id, true)
			if not clock.is_running():
				return
	if _group_index < _groups.size() and tick >= _next_spawn_tick:
		_spawn(tick)
	_try_finish_wave(tick)

func _spawn(tick: int) -> void:
	var group := _groups[_group_index]
	var id := _next_id
	_next_id += 1
	active[id] = BattleEnemy.new(group.enemy, _stage.routes[group.route_index])
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
