extends "res://tests/playtest/c32_d_fresh_campaign.gd"
## Native host benchmark. Uses a disposable profile and production screens.
## Only the labeled Chaos stress fixture alters its local spawn schedule and HP.

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const CAMPAIGN_CASES := {
	"first": &"C1-01", "chapter2": &"C2-04", "heat": &"C2-08",
	"boss": &"C1-05", "final": &"C2-10",
}
const FRAME_COUNT := 240

var _app: Control
var _draws := 0
var _ok := false

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := args[0] if not args.is_empty() else "first"
	if scenario == "rigs":
		await _rig_case()
		quit()
		return
	if DisplayServer.get_name() == "headless":
		printerr("The host benchmark needs a native display.")
		quit(1)
		return
	var dimensions := (args[1] if args.size() > 1 else "960x540").split("x")
	if dimensions.size() != 2:
		quit(1)
		return
	root.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	Engine.max_fps = 90
	_seed()
	await _transition("launcher", _start_launcher)
	print("C34_ENV ", JSON.stringify({
		"godot": Engine.get_version_info().string, "cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(), "display": DisplayServer.get_name(),
		"size_px": str(DisplayServer.window_get_size()), "cap_fps": Engine.max_fps,
	}))
	if CAMPAIGN_CASES.has(scenario):
		await _campaign_case(scenario)
	else:
		match scenario:
			"hq":
				await _headquarters_case(maxi(1, int(args[2])) if args.size() > 2 else 8)
			"chaos":
				await _chaos_case()
			_:
				printerr("Unknown benchmark case: " + scenario)
				quit(1)
				return
	_app.free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".settings", ".settings.bak"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	quit(0 if _ok else 1)

func _seed() -> void:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Host performance fixture"
	profile.funds = 5000000
	for room: HeadquartersRoom in CampaignProgress.HEADQUARTERS.rooms:
		profile.rooms[String(room.id)] = HeadquartersCatalog.MAX_LEVEL
	for operation: StoryOperation in _content.operations:
		profile.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in operation.clear_unlock_ids:
			if String(id) not in profile.owned:
				profile.owned.append(String(id))
	for id in [POST, FIREBREAK, SCOUT, GUARD, PATROL]:
		if String(id) in profile.owned:
			profile.deployable_levels[String(id)] = 80 if id == SCOUT or id == GUARD else 40
	profile.chaos.personal_best = 3000
	print("C34_PROFILE ", ProfileFile.replace(_path, profile, false))

func _start_launcher() -> void:
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _path
	root.add_child(_app)

func _transition(label: String, action: Callable) -> void:
	var start := Time.get_ticks_usec()
	action.call()
	var setup_ms := (Time.get_ticks_usec() - start) / 1000.0
	await process_frame
	await RenderingServer.frame_post_draw
	print("C34_TRANSITION ", JSON.stringify({
		"screen": label, "setup_ms": setup_ms,
		"first_frame_ms": (Time.get_ticks_usec() - start) / 1000.0, "rss_kib": _rss(),
		"nodes": get_node_count(), "resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
	}))

func _campaign_case(scenario: String) -> void:
	var operation := _content.operation(CAMPAIGN_CASES[scenario])
	await _transition("planning_" + scenario, _app._show_campaign_plan.bind(operation))
	var progress: CampaignProgress = _app._campaign_progress
	_tactical = true
	_expanded = scenario in ["chapter2", "heat"]
	_late_policy = "heat" if scenario == "heat" else ""
	_trial_buffs.assign([&"B02", &"B07"] if scenario == "heat" else [])
	_app._draft = _select_plan(operation, progress, scenario != "first")
	await _transition("story_" + scenario, _app._start_campaign)
	var field := _app._screen as CampaignBattle
	if field == null:
		push_error("Campaign did not enter " + scenario)
		return
	field.set_physics_process(false)
	var sim := field.battle
	var warmup_started := Time.get_ticks_usec()
	var scripted: Array = OPENINGS.get(operation.stage.stage_id, []).duplicate(true)
	var entries: Array[DeploymentSpec] = field.operation_plan.deployment_entries()
	while sim.clock.tick < 90000 and not sim.clock.stopped:
		if sim.clock.dialogue_open:
			field._skip_dialogue()
			continue
		if not scripted.is_empty():
			_place_scripted(sim, entries, scripted)
		elif scenario != "first" and sim.clock.tick % 30 == 0:
			_deploy(sim, entries)
			_skills(sim)
			if _expanded:
				_cycle_specialists(sim)
		sim.clock.advance_frame()
		if _campaign_ready(scenario, field):
			break
	if not _campaign_ready(scenario, field):
		push_error("Missing target condition for %s at tick %d" % [scenario, sim.clock.tick])
		return
	_print_warmup(scenario, warmup_started, field)
	# After synchronous warmup, allow disposed actors to leave the scene tree.
	field._refresh()
	await process_frame
	await process_frame
	field.set_physics_process(true)
	await _sample(scenario + "_active", field, FRAME_COUNT)
	if scenario == "first":
		field._toggle_pause()
		await _sample("first_paused", field, FRAME_COUNT)
	_ok = true

func _campaign_ready(scenario: String, field: CampaignBattle) -> bool:
	var sim := field.battle
	match scenario:
		"first":
			return sim.active.size() >= 2 and sim.deployment.placed.size() >= 2
		"chapter2":
			return sim.wave_number >= 3 and sim.active.size() >= 6
		"heat":
			return sim.heat > 0.0 and sim.active.size() >= 4
		"boss":
			return field._active_boss_id() != 0
		"final":
			return sim.wave_number >= 4 and sim.active.size() >= 6
	return false

func _rig_case() -> void:
	var assets := CampaignVisualAssets.new()
	var packed := assets.rig(assets.actor(&"E04"))
	for sample in range(7):
		var arena := Node2D.new()
		root.add_child(arena)
		var before := Performance.get_monitor(Performance.MEMORY_STATIC)
		var start := Time.get_ticks_usec()
		for index in range(50):
			arena.add_child(packed.instantiate())
		print("C34_RIG ", JSON.stringify({
			"sample": sample, "ms": (Time.get_ticks_usec() - start) / 1000.0,
			"allocated_bytes": Performance.get_monitor(Performance.MEMORY_STATIC) - before,
		}))
		arena.free()
		await process_frame

func _headquarters_case(cycles: int) -> void:
	await _transition("headquarters", _app._open_headquarters.bind(_app.show_menu))
	await _sample("headquarters_all_rooms", null, FRAME_COUNT)
	await _transition("menu_before_cycles", _app.show_menu)
	for index in range(cycles):
		var operation := _content.operation(&"C1-01")
		await _transition("menu_to_plan_%d" % index, _app._show_campaign_plan.bind(operation))
		await _transition("plan_to_battle_%d" % index, _app._start_campaign)
		var field := _app._screen as CampaignBattle
		if field == null:
			return
		field._skip_dialogue()
		await _transition("battle_to_menu_%d" % index, _return_to_menu)
	_ok = true

func _return_to_menu() -> void:
	_app._campaign_progress.abandon_attempt()
	_app.show_menu()

func _chaos_case() -> void:
	await _transition("chaos_routes", _app.show_chaos)
	var config: ChaosConfiguration = _app._chaos_configuration
	config.select_route(&"T05")
	# Five populated authored wave slots for configuration and scroll load.
	for index in range(ChaosConfiguration.WAVE_SLOTS):
		config.set_quantity(index, &"E04", 46)
		config.set_quantity(index, &"E11", 2)
		config.set_quantity(index, &"E14", 1)
		config.set_quantity(index, &"boss.diversion_captain", 1)
	var stage := config.build_stage()
	var selection: Array[StringName] = [POST, SCOUT, MEDIC, GUARD, SONIC]
	_app._chaos_plan = _app._new_chaos_plan(stage, "Host 50-enemy stress fixture", selection)
	var plan: OperationPlan = _app._chaos_plan
	plan.set_modifier(BattleModifiers.CATALOG.definition(&"B13"), true)
	await _transition("chaos_composer_250", _app._render_chaos_composer)
	await _sample("chaos_composer_250", null, FRAME_COUNT)
	# Compress the fixture's first wave and extend actor life so all stock W29
	# rigs remain resident together. No production resource is mutated.
	stage.opening_delay_seconds = 3.0
	for group in stage.waves[0].groups:
		group.interval_seconds = CombatClock.STEP_SECONDS
		group.enemy = group.enemy.duplicate()
		group.enemy.max_hp *= 10
	plan.update_stage(stage)
	await _transition("chaos_battle", _app._start_chaos.bind(Callable()))
	var field := _app._screen as ChaosBattle
	if field == null:
		return
	field.set_physics_process(false)
	var sim := field.battle
	var warmup_started := Time.get_ticks_usec()
	sim.enemy_spawned.connect(_spread.bind(sim))
	var entries := plan.deployment_entries()
	for frame in range(400):
		if frame % 20 == 0:
			_deploy(sim, entries)
		if sim.clock.dialogue_open:
			field.close_dialogue()
		sim.clock.advance_frame()
		if sim.active.size() == 50:
			break
	if sim.active.size() != 50:
		push_error("Chaos stress fixture reached only %d resident enemies" % sim.active.size())
		return
	if sim.clock.dialogue_open:
		field.close_dialogue()
	_print_warmup("chaos_50_resident", warmup_started, field)
	field._refresh()
	await process_frame
	await process_frame
	field.set_physics_process(true)
	await _sample("chaos_50_resident", field, FRAME_COUNT)
	_ok = true

func _spread(id: int, kind: StringName, sim: BattleSimulation) -> void:
	var enemy: BattleEnemy = sim.active[id]
	enemy.distance = 1.0 if kind == &"E11" else float(id % 8) + float(id % 3) / 4.0
	enemy.add_damage_mark(sim.clock.tick, sim.clock.tick + 1000, 10)
	enemy.sonic_slow_until = sim.clock.tick + 1000
	enemy.sonic_speed_scale = 0.65
	if kind == &"E14":
		sim.heat = 98.0

func _sample(label: String, field: BattleScene, count: int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var frames := PackedFloat64Array()
	var physics := PackedFloat64Array()
	var calls := PackedFloat64Array()
	var resident_min := 0 if field == null else field.battle.active.size()
	var resident_max := resident_min
	var tick := 0 if field == null else field.battle.clock.tick
	var rss_start := _rss()
	var start := Time.get_ticks_usec()
	var previous := start
	if field != null:
		field._board.draw.connect(_count_draw)
	_draws = 0
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		frames.append((now - previous) / 1000.0)
		previous = now
		physics.append(1000.0 * Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
		calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		if field != null:
			resident_min = mini(resident_min, field.battle.active.size())
			resident_max = maxi(resident_max, field.battle.active.size())
			if field.battle.clock.dialogue_open and field.battle.outcome == BattleSimulation.Outcome.RUNNING:
				field._skip_dialogue()
	if field != null:
		field._board.draw.disconnect(_count_draw)
	frames.sort()
	physics.sort()
	calls.sort()
	print("C34_SAMPLE ", JSON.stringify({
		"case": label, "frames": count, "fps": count * 1000000.0 / (previous - start),
		"p50_ms": _quantile(frames, 0.5), "p95_ms": _quantile(frames, 0.95), "p99_ms": _quantile(frames, 0.99),
		"max_ms": frames[-1], "physics_p95_ms": _quantile(physics, 0.95),
		"draw_calls_median": _quantile(calls, 0.5), "board_redraws": _draws, "rss_start_kib": rss_start,
		"rss_end_kib": _rss(), "rss_peak_kib": _rss("VmHWM:"),
		"resident_min": resident_min, "resident_max": resident_max,
		"units": 0 if field == null else field.battle.deployment.placed.size(),
		"start_tick": tick, "end_tick": 0 if field == null else field.battle.clock.tick,
		"heat_end": 0.0 if field == null else field.battle.heat,
		"static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"video_texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"nodes": get_node_count(), "orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
	}))

func _print_warmup(label: String, start: int, field: BattleScene) -> void:
	print("C34_WARMUP ", JSON.stringify({
		"case": label, "ms": (Time.get_ticks_usec() - start) / 1000.0,
		"tick": field.battle.clock.tick, "resident": field.battle.active.size(),
		"static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
	}))

func _count_draw() -> void:
	_draws += 1

func _quantile(sorted: PackedFloat64Array, fraction: float) -> float:
	return sorted[ceili(sorted.size() * fraction) - 1]

func _rss(key := "VmRSS:") -> int:
	var file := FileAccess.open("/proc/self/status", FileAccess.READ)
	if file == null:
		return -1
	while not file.eof_reached():
		var line := file.get_line()
		if line.begins_with(key):
			return line.trim_prefix(key).strip_edges().to_int()
	return -1
