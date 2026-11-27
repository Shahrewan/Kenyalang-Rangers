extends SceneTree

const T01 := preload("res://data/stages/c05_first_contact.tres")
const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const POST := &"facility.logistics_post"
const PATROL := &"ranger.patrolman"
const SCOUT := &"ranger.scout_sniper"

var _checks := 0
var _failures := 0
var _events: Array[String] = []
var _resolved: Dictionary[String, String] = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var mixer := PresentationAudio.new()
	mixer.path = "user://c36-audio-test-%d.json" % OS.get_process_id()
	root.add_child(mixer)
	mixer.cue_dispatched.connect(func(group: String, source: String) -> void:
		_events.append(group)
		_resolved[group] = source
	)
	_catalog(mixer)
	_mixer(mixer)
	_polyphony(mixer)
	_bindings()
	_dense_baseline()
	await _story_and_hq()
	await _learning()
	mixer.free()
	await process_frame
	print("C36 audio integration: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _catalog(mixer: PresentationAudio) -> void:
	var catalog := PresentationAudio.catalog()
	var paths := 0
	var bytes := 0
	var failures := PackedStringArray()
	for group: String in catalog.groups:
		var row: Dictionary = catalog.groups[group]
		for path: String in row.paths:
			var stream := mixer._resource(path)
			paths += 1
			if stream == null or stream.stereo or stream.mix_rate != 22050 or stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
				failures.append(path)
				continue
			bytes += stream.data.size()
			var playback := stream.instantiate_playback()
			playback.start()
			var frames := ceili(AudioServer.get_mix_rate() * stream.get_length())
			var source := playback.mix_audio(1.0, frames)
			var audible := false
			for frame in source:
				if frame.length_squared() > 0.00001:
					audible = true
					break
			if not audible:
				failures.append(path)
			playback.stop()
	_check(catalog.groups.size() == 114 and paths == 133 and failures.is_empty(), "133 approved variants resolve and mix audible nonzero frames: %s" % failures)
	_check(mixer._cache.size() <= PresentationAudio.CACHE_LIMIT, "Resource cache stays within its configured file count")
	print("C36 serialized playback data: ", bytes, " bytes")
	for id: String in PresentationAudio.CUES:
		var group: String = catalog.aliases[id]
		var row: Dictionary = catalog.groups[group]
		_check(not mixer._resolve(group, row).is_empty(), "Resolve legacy " + id)
		row = row.duplicate()
		row.paths = ["res://assets/audio/sfx/not_installed.wav"]
		_check(mixer._resolve(group, row).get("path") == "procedural:" + id, "Missing replacement falls back to " + id)
	_events.clear()

func _mixer(mixer: PresentationAudio) -> void:
	mixer.set_route(&"battle")
	var track := mixer.music.stream
	mixer.cue("confirm")
	mixer.cue("invalid")
	mixer.cue("invalid")
	mixer._process(0.0)
	_check(_events == ["ui_invalid"] and _resolved.ui_invalid.contains("ui_invalid"), "Visible rejection supersedes generic click and repeat in the same frame")
	mixer.set_route(&"battle")
	mixer.cue("confirm")
	mixer._process(0.0)
	_check(_resolved.ui_confirm != _resolved.ui_invalid, "Confirmation and invalid resolve to separate audio resources")
	_events.clear()
	mixer.cue("ranger_scout_sniper_attack")
	mixer.cue("combat_heat_overflow")
	mixer.hold(true)
	mixer._process(0.0)
	_check(_events == ["combat_heat_overflow"] and mixer._held, "Dialogue hold removes queued rifle and leaves tactical overflow")
	_events.clear()
	mixer.cue("ui_cancel")
	mixer._process(0.0)
	_check(_events == ["ui_cancel"], "Paused interface still has SFX")
	mixer.cue("combat_boss_alert")
	mixer.background(true)
	mixer.background(false)
	mixer._process(0.0)
	_check(_events == ["ui_cancel"] and mixer.music.stream == track and mixer._held, "Backgrounding removes stale SFX without replacing the held music")
	mixer.hold(false)
	mixer.values.sfx = 0
	mixer.values.music = 60
	mixer.values.master = 50
	mixer._mix()
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	var master_bus := AudioServer.get_bus_index(&"Master")
	_check(not AudioServer.is_bus_mute(music_bus) and AudioServer.is_bus_mute(sfx_bus)
		and is_equal_approx(AudioServer.get_bus_volume_linear(master_bus) * AudioServer.get_bus_volume_linear(music_bus), 0.5 * pow(0.6, 1.5)), "SFX mute preserves the master-scaled music")
	_events.clear()
	mixer.cue("combat_heat_overflow")
	mixer._process(0.0)
	_check(_events.is_empty(), "SFX mute suppresses tactical warnings")
	mixer.values.sfx = 80
	mixer.values.music = 0
	mixer._mix()
	mixer.cue("ui_confirm")
	mixer._process(0.0)
	_check(AudioServer.is_bus_mute(music_bus) and _events == ["ui_confirm"], "Music mute preserves UI SFX")
	mixer.values.master = 0
	mixer._mix()
	mixer.cue("ui_invalid")
	mixer._process(0.0)
	_check(_events == ["ui_confirm"] and AudioServer.is_bus_mute(master_bus), "Master mute affects both")
	mixer.values = PresentationAudio.DEFAULTS.duplicate()
	mixer._mix()

func _polyphony(mixer: PresentationAudio) -> void:
	var groups: Dictionary = PresentationAudio.catalog().groups
	var row: Dictionary = groups.ranger_melee_attack
	var stream: AudioStreamWAV = mixer._resolve("ranger_melee_attack", row).stream
	var regular_limit := mixer._voices.size() >> 1
	for i in regular_limit:
		var voice := mixer._voices[i]
		voice.group = "ranger_melee_attack"
		voice.category = "rangers"
		voice.priority = 43
		voice.player.stream = stream
		voice.player.play()
	_check(mixer._voices[0].player.playing and mixer._available_voice("ranger_melee_attack", row) == null,
		"An already-playing group cannot exceed its concurrent limit")
	_check(mixer._available_voice("enemy_melee_light", groups.enemy_melee_light) == null,
		"Routine combat cannot consume the reserved voices")
	_check(mixer._available_voice("combat_heat_overflow", groups.combat_heat_overflow) != null,
		"An overflow warning can still acquire a voice")
	mixer.background(true)
	_check(mixer._voices.all(func(voice: PresentationAudio.Voice) -> bool: return voice.player.stream == null),
		"Background clears every live playback voice")
	mixer.background(false)

func _sim() -> BattleSimulation:
	var stage := T01.duplicate() as BattleStage
	var sim := BattleSimulation.new(stage)
	sim.deployment = DeploymentState.new(stage.map, sim.clock, 600)
	return sim

func _place(sim: BattleSimulation, spec: DeploymentSpec) -> DeploymentState.Placement:
	var candidates := T01.map.ground if spec.uses_ground() else T01.map.elevated
	for cell: Vector2i in candidates:
		if sim.deployment.deploy(spec, cell, -1).is_empty():
			return sim.deployment.placed[sim.deployment.interaction_id(cell)]
	return null

func _bindings() -> void:
	var known: Dictionary = PresentationAudio.catalog().groups
	for spec: DeploymentSpec in DeployableLevels.catalog(true):
		var sim := _sim()
		var routed: Array[String] = []
		var binding := BattleAudioEvents.new(sim, sim.deployment, routed.append)
		var unit := _place(sim, spec)
		_check(unit != null and routed == ["combat_deploy"], "%s commits one placement cue" % spec.label)
		if unit == null:
			continue
		routed.clear()
		if spec.id == &"ranger.combat_medic":
			sim.ranger_combat.healing_presented.emit(unit, unit.anchor)
		else:
			sim.ranger_combat.attack_presented.emit(unit, 1, &"Attack")
		_check(routed.size() == 1 and known.has(routed[0]), "%s resolves its primary accepted action" % spec.label)
		routed.clear()
		if BattleAudioEvents.SKILLS.has(spec.id):
			sim.ranger_combat.attack_presented.emit(unit, 1, &"Skill")
			sim.deployment.skill_fired.emit(unit.id, unit.anchor)
			_check(routed == [BattleAudioEvents.SKILLS[spec.id]], "%s skill commits a single cue" % spec.label)
		_check(binding != null, "Keep the Ranger adapter bound for the fixture")
	for spec: DeploymentSpec in DeployableLevels.catalog(false):
		var sim := _sim()
		var routed: Array[String] = []
		var binding := BattleAudioEvents.new(sim, sim.deployment, routed.append)
		var unit := _place(sim, spec)
		_check(unit != null and routed == ["combat_deploy" if spec.id == POST else "facility_construction_start"], "%s commits its true construction state" % spec.label)
		if unit == null:
			continue
		var deadline := unit.build_deadline
		while sim.clock.tick < deadline:
			sim.clock.advance_frame()
		_check(routed.count("facility_construction_ready") == (0 if spec.id == POST else 1) and binding != null, "%s readiness cue follows the actual build deadline" % spec.label)
	var sim := _sim()
	var routed: Array[String] = []
	var binding := BattleAudioEvents.new(sim, sim.deployment, routed.append)
	var blocker := _place(sim, DeployableLevels.definition(PATROL))
	for enemy: BattleEnemyDefinition in CampaignContent.ENEMIES.entries:
		var actor := BattleEnemy.new(enemy, T01.routes[0])
		routed.clear()
		sim.enemy_attack_presented.emit(actor)
		_check(routed.size() == 1 and known.has(routed[0]), "%s maps an accepted attack" % enemy.display_name)
		if enemy.ability != null:
			if enemy.enemy_id == &"E13":
				actor.blocked_by = blocker.id
				sim.enemy_ability_presented.emit(actor, blocker.anchor)
				_check(routed.size() == 1, "Resisted Breach stays quiet")
				blocker.knocked_down_until = sim.clock.tick + 1
			routed.clear()
			sim.enemy_ability_presented.emit(actor, blocker.anchor)
			_check(routed == [BattleAudioEvents.ABILITIES[enemy.enemy_id]], "%s maps its accepted ability" % enemy.display_name)
	for boss: BossSpec in CampaignContent.BOSSES.entries:
		routed.clear()
		sim._register_enemy(boss, T01.routes[0], sim.clock.tick)
		var serial: int = sim.active.keys().back()
		_check(routed.has(PresentationAudio.entity_cue(boss.enemy_id, "intro")), "%s has its registered intro" % boss.display_name)
		routed.clear()
		for phase: BossPhase in boss.phases:
			sim.boss_phase_changed.emit(serial, phase)
		_check(routed.size() == boss.phases.size() and routed.all(func(id: String) -> bool: return id.begins_with("boss_") and known.has(id)), "%s has every configured phase cue" % boss.display_name)
	routed.clear()
	sim.record_cinematic_withdrawal()
	_check(routed == ["combat_messenger_withdrawal"] and sim.integrity == 100 and sim.escaped == 0 and binding != null, "Messenger cue never resolves as a combat escape")

func _dense_baseline() -> void:
	var baseline := _run_dense(1, false)
	var normal := _run_dense(1, true)
	var accelerated := _run_dense(2, true)
	_check(baseline.game == normal.game and baseline.game == accelerated.game, "Dense combat outcomes, clock, integrity and Tokens match at 1× and 2× with audio")
	_check(normal.events > 50 and accelerated.events == normal.events, "Dense combat produces the same sequence count independent of wall speed")
	print("C36 dense fixture [outcome,tick,defeated,escaped,Integrity,Tokens], events: ", normal)

func _run_dense(speed: int, with_sound: bool) -> Dictionary:
	var stage := T01.duplicate() as BattleStage
	var wave := BattleWave.new()
	var group := BattleSpawnGroup.new()
	group.enemy = CampaignContent.ENEMIES.entries[0]
	group.count = 40
	group.interval_seconds = 0.35
	wave.groups.append(group)
	stage.waves = [wave]
	var sim := BattleSimulation.new(stage)
	sim.deployment = DeploymentState.new(stage.map, sim.clock, 600)
	var routed := [0]
	var binding: BattleAudioEvents
	if with_sound:
		binding = BattleAudioEvents.new(sim, sim.deployment, func(_id: String) -> void: routed[0] += 1)
	sim.deployment.deploy(DeployableLevels.definition(POST), Vector2i(1, 0), -1)
	sim.deployment.deploy(DeployableLevels.definition(PATROL), Vector2i(6, 3), -1)
	sim.deployment.deploy(DeployableLevels.definition(SCOUT), Vector2i(5, 2), -1)
	sim.clock.set_speed(speed)
	while sim.clock.is_running() and sim.clock.tick < 20000:
		sim.clock.advance_frame()
	if with_sound:
		_check(binding != null, "Dense fixture keeps the passive route connection")
	return {"game": [sim.outcome, sim.clock.tick, sim.defeated, sim.escaped, sim.integrity, sim.deployment.tokens], "events": routed[0]}

func _story_and_hq() -> void:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = "user://c36-audio-profile-%d.json" % OS.get_process_id()
	app.save_path = app.campaign_save_path + ".legacy"
	root.add_child(app)
	app._campaign_progress.set_leader_name("Rimba")
	app._campaign_progress.adjust_developer_funds(300000)
	app.show_menu()
	await process_frame
	var app_events: Array[String] = []
	app.presentation.cue_dispatched.connect(func(group: String, _source: String) -> void: app_events.append(group))
	app._open_headquarters(app.show_menu)
	app.presentation._process(0.0)
	_check(app_events.has("ui_navigate"), "Actual launcher route uses its navigation cue")
	app._show_hq_room(CampaignProgress.HEADQUARTERS.room(HeadquartersCatalog.ECOLOGY))
	var room := app._screen as HeadquartersRoomPage
	app.presentation._process(0.0)
	app_events.clear()
	var before: int = app._campaign_progress.funds()
	var cost: int = app._campaign_progress.room_quote(HeadquartersCatalog.ECOLOGY).cost
	room._confirm_room_purchase()
	_check(app_events.is_empty() and app._campaign_progress.funds() == before, "Opening the HQ quote is silent and does not spend")
	room._dialog.confirmed.emit()
	room._dialog.hide()
	app.presentation._process(0.0)
	_check(app_events == ["progression_hq_room_built"] and app._campaign_progress.room_level(HeadquartersCatalog.ECOLOGY) == 1
		and app._campaign_progress.funds() == before - cost, "Room plays one receipt after exact Funds and build commit")
	for iteration in 8:
		app.show_story()
		app._show_campaign_plan(app._campaign.operation(&"C1-01"))
		app._start_campaign()
		var field := app._screen as CampaignBattle
		field.set_physics_process(false)
		field.get_node("%Skip").pressed.emit()
		app.presentation._process(0.0)
		app.show_menu()
		await process_frame
		_check(app.presentation._pending.is_empty() and app.presentation._voices.all(func(voice: PresentationAudio.Voice) -> bool:
			return voice.player.stream == null or not voice.category in PresentationAudio.BATTLE_CATEGORIES),
			"Route %d disposes of old active and pending SFX" % (iteration + 1))
	app.free()

func _learning() -> void:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = "user://c36-learning-audio-%d.json" % OS.get_process_id()
	app.save_path = app.campaign_save_path + ".legacy"
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.rooms[String(HeadquartersCatalog.OUTREACH)] = 2
	profile.rooms[String(HeadquartersCatalog.RECORDS)] = 2
	ProfileFile.replace(app.campaign_save_path, profile, false)
	root.add_child(app)
	app._show_outreach(CampaignProgress.HEADQUARTERS.room(HeadquartersCatalog.OUTREACH))
	var page := app._screen as OutreachPage
	var cues: Array[String] = []
	page.sound_requested.connect(cues.append)
	var batch := page._session.batch()
	var tested := ["best", "acceptable", "poor", "harmful"]
	for i in tested.size():
		var question: String = batch.batch[i]
		var order: Array = batch.choice_order[question]
		for choice in order.size():
			if page.catalog.outreach[question].choices[order[choice]].grade == tested[i]:
				cues.clear()
				page._select(question)
				page._submit(question, choice)
				var expected := "outreach_response_positive" if i < 2 else "outreach_response_reflect"
				_check(cues == [expected] and page._session.batch().responses[question].grade == tested[i], "Outreach dispatches the saved %s grade once" % tested[i])
				break
	var quiz := RecordsQuiz.new(app._campaign_progress, app._education())
	_check(quiz.begin("records_chapter.scout_sniper"), "Start a real disposable Records chapter")
	app._show_records_quiz(quiz, CampaignProgress.HEADQUARTERS.room(HeadquartersCatalog.RECORDS))
	var quiz_page := app._screen as RecordsQuizPage
	quiz_page.set_process(false)
	cues.clear()
	quiz_page.sound_requested.connect(cues.append)
	quiz.advance(16.0)
	quiz_page._render()
	_check(quiz.reviewing() and quiz.feedback().choice == -1 and cues == ["records_time_expired"],
		"Actual quiz timeout cues once despite a re-render")
	app.free()
	await process_frame

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
