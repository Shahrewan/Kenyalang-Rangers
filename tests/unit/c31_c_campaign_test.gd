extends "res://tests/playtest/c30_campaign_playtest.gd"

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")

var _checks := 0
var _failures := 0
var _captures := ""
var _text_size := 100

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		_captures = args[0]
		var dimensions := args[1].split("x")
		root.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
		_text_size = int(args[2])
		DirAccess.make_dir_recursive_absolute(_captures)
	_tactical = true
	_expanded = true
	var foreman := _content.operation(&"C2-08")
	var convoy := _content.operation(&"C2-09")
	_check(foreman != null and convoy != null, "Both live late Campaign missions resolve")
	if _failures > 0:
		quit(1)
		return
	_late_policy = "heat"
	_trial_buffs = [&"B02", &"B07"]
	var normal := _play(foreman, false)
	_check(normal.outcome == BattleSimulation.Outcome.WON and not normal.perfect and normal.escaped == 1
		and normal.integrity > 0 and normal.heat_overflows == 5, "Lv.1 Post plan clears C2-08 with an ordinary escape and real Heat loss")
	var perfect := _play(foreman, true)
	_check(perfect.perfect and perfect.defeated == 102 and perfect.heat_overflows > 0
		and perfect.boss_phase_ticks.size() == 1 and not perfect.firebreak_owned, "C2-08 perfect uses ordinary owned equipment and the Foreman phase")
	_check(perfect.settled and perfect.funds_credited == 0 and "first_perfect_funds" in perfect.pending_awards
		and normal.settled and normal.funds_credited == 0 and "first_clear_funds" in normal.pending_awards, "Both outcomes settle the actual flags and pending Funds")
	var boss := foreman.stage.waves.back().groups[0].enemy as BossSpec
	_check(boss.phases[0].temporary_hp == 600 and boss.phases[0].protection_seconds == 5.0 and not boss.escape_causes_defeat,
		"Foreman retains the authored shield and ordinary escape behavior")
	_check(foreman.stage.opening_delay_seconds == 36.0 and foreman.stage.heat_capacity == 100 and foreman.stage.heat_integrity_loss == 10,
		"C2-08 keeps the Heat threshold and overflow cost")
	if not _captures.is_empty():
		await _native(foreman, true, perfect)
	_late_policy = "convoy"
	_trial_buffs = [&"B05", &"B07"]
	perfect = _play(convoy, true)
	_check(perfect.perfect and perfect.defeated == 138 and perfect.integrity == 100 and perfect.wave == 4
		and perfect.wave_peaks[3] >= perfect.wave_peaks[0], "Progressed C2-09 earns a perfect across all four waves")
	if not _captures.is_empty():
		await _native(convoy, true, perfect)
	_hold_rangers_seconds = 80.0
	normal = _play(convoy, false)
	_check(normal.outcome == BattleSimulation.Outcome.WON and normal.escaped == 6 and normal.integrity == 10
		and not normal.perfect and normal.fatal_escape == "", "A later legal opening can clear C2-09 with ordinary escapes")
	_check(normal.settled and normal.funds_credited == 0 and perfect.settled and perfect.funds_credited == 0,
		"C2-09 settles both outcome records with unpriced awards")
	_check(convoy.stage.opening_delay_seconds == 52.0 and convoy.stage.waves.size() == 4 and convoy.stage.enemy_count() == 138,
		"C2-09 keeps the four original queues")
	_check(convoy.stage.waves[2].groups.any(func(group: BattleSpawnGroup) -> bool:
		return group.enemy.enemy_id == &"E15" and group.enemy.escape_causes_defeat), "Wildlife Trafficker retains fatal escape")
	_cleanup()
	print("C31-C late Campaign: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _native(operation: StoryOperation, progressed: bool, expected: Dictionary) -> void:
	var pending_plan := _plan(operation, progressed)
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	app.presentation.values.text = _text_size
	app._restyle()
	app._draft = pending_plan
	app._start_campaign()
	var field := app._screen as CampaignBattle
	_check(field != null, "The player-facing Story route opens " + operation.title)
	if field == null:
		app.free()
		return
	field.set_physics_process(false)
	var sim := field.battle
	var entries := pending_plan.deployment_entries()
	var captured_opening := false
	var captured_phase := false
	var phase: Array[int] = []
	var clock := sim.clock
	sim.boss_phase_changed.connect(func(_id: int, _phase: BossPhase) -> void: phase.append(clock.tick))
	var prefix := String(operation.stage.stage_id).to_lower()
	var last_action := -1
	for frame in 90000:
		while sim.clock.dialogue_open:
			field.get_node("%Skip").pressed.emit()
		if sim.clock.stopped:
			break
		if sim.clock.tick % 30 == 0 and sim.clock.tick != last_action:
			last_action = sim.clock.tick
			_deploy(sim, entries)
			_skills(sim)
			_cycle_specialists(sim)
		sim.clock.advance_frame()
		if not captured_opening and sim.clock.tick >= CombatClock.ticks_for(field.stage.opening_delay_seconds + 7.0):
			field._refresh()
			await _capture(prefix + "-opening")
			captured_opening = true
		if not captured_phase and not phase.is_empty() and sim.clock.tick >= phase[0] + 12:
			field._refresh()
			await _capture(prefix + "-foreman-phase")
			captured_phase = true
	_check(sim.is_perfect() and sim.integrity == expected.integrity and sim.defeated == expected.defeated,
		"Live Story matches the deterministic perfect outcome for " + operation.title)
	field._refresh()
	while sim.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()
	await process_frame
	_check(app._route == &"results", "Story opens the real results screen")
	await _capture(prefix + "-result")
	app.free()
	await process_frame

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	_check(screenshot.get_size() == root.size and screenshot.save_png(_captures.path_join(name + ".png")) == OK,
		"Saved rendered " + name)

func _cleanup() -> void:
	for stem in [_path, _path + ".settings"]:
		for suffix in ["", ".bak", ".bak.tmp", ".tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)

func _check(check: bool, message: String) -> void:
	_checks += 1
	if not check:
		_failures += 1
		printerr("FAIL ", message)
