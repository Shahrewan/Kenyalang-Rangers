extends SceneTree

const LOAD_SCENE := preload("res://scenes/qa/c23_load.tscn")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var first := _trial()
	var second := _trial()
	_check(first == second and first.size() == 50, "Repeated fixed-tick trials end in the same 50 enemy states")
	quit(1 if failures else 0)

func _trial() -> Array:
	var fixture := LOAD_SCENE.instantiate()
	fixture.auto_finish = false
	root.add_child(fixture)
	var battle: BattleSimulation = fixture.field.battle
	for frame in 1200:
		if battle.clock.dialogue_open:
			fixture.field.close_dialogue()
		battle.clock.advance_frame()
		if battle.clock.tick == 540:
			break
	_check(battle.active.size() == 50 and battle.wave_count == 1 and battle.deployment.placed.size() == 4, "One full Chaos wave lives alongside two Rangers and two Facilities")
	_check(battle.active.values().any(func(e: BattleEnemy) -> bool:
		return e.is_marked(battle.clock.tick) and e.sonic_slow_until > battle.clock.tick
	), "Mark and slow overlap during combat")
	var before := _snapshot(battle)
	for flag in ["paused", "dialogue_open"]:
		battle.clock.set(flag, true)
		for frame in 120:
			battle.clock.advance_frame()
		_check(before == _snapshot(battle), "%s freezes dense combat and status deadlines" % flag)
		battle.clock.set(flag, false)
	for frame in 400:
		battle.clock.advance_frame()
	_check(fixture.siege_hits > 0 and fixture.heat_events > 0 and battle.clock.tick == 940, "Combat resumes with live Siege and Heat events")
	var result: Array = _snapshot(battle).enemies
	fixture.free()
	return result

func _snapshot(battle: BattleSimulation) -> Dictionary:
	var units := []
	for unit: DeploymentState.Placement in battle.deployment.placed.values():
		units.append([unit.hp, unit.next_attack_tick, unit.build_deadline])
	var enemies := []
	for enemy: BattleEnemy in battle.active.values():
		enemies.append([enemy.definition.enemy_id, enemy.hp, enemy.distance, enemy.sonic_slow_until, enemy.fire_tick])
	return {"tick": battle.clock.tick, "heat": battle.heat, "integrity": battle.integrity,
		"tokens": battle.deployment.tokens, "units": units, "enemies": enemies}

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		failures += 1
		push_error(label)
