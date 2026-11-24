extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")

var _capture_dir := ""
var _text_scale := 100
var _portrait_keys := {}
var _checks := 0
var _failed := 0
var _path := "user://c14-story-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		_capture_dir = args[0]
		var dimensions := args[1].split("x")
		root.size = Vector2i(dimensions[0].to_int(), dimensions[1].to_int())
		DirAccess.make_dir_recursive_absolute(_capture_dir)
		if args.size() >= 3:
			_text_scale = args[2].to_int()
	else:
		root.size = Vector2i(960, 540)
	var legacy := FirstContactProgress.new(_path + ".legacy")
	legacy.set_leader_name("Talia")
	legacy.record_clear(true, 100, 50)
	var app := _launcher()
	app.presentation.values.text = _text_scale
	app._restyle()
	var progress: CampaignProgress = app._campaign_progress
	var campaign: CampaignContent = app._campaign
	_check(app._route == &"menu" and progress.snapshot().leader_name == "Talia" and progress.snapshot().funds == 10000 and progress.snapshot().records.is_empty(), "Launcher carries over the name and starts a separate Campaign wallet and records")
	if campaign.operations.size() != 15:
		_check(false, campaign.error)
		_finish()
		return
	var c1 := campaign.operation(&"C1-01")
	var c2 := campaign.operation(&"C1-02")
	var c4 := campaign.operation(&"C1-04")
	var finale := campaign.operation(&"C2-10")
	app._screen.get_node("%OpenCampaign").pressed.emit()
	_check(_node(app._screen, c2).disabled and _node(app._screen, c4).disabled and _node(app._screen, c4).text == "C1-04", "Story conceals fogged titles and locks a revealed successor")
	if not _capture_dir.is_empty():
		await _capture("story-selection")
	var troops := await _play_first_contact(app, c1)
	_check(troops.defeated == 14 and troops.escaped == 0 and troops.outcome == "Perfect clear", "C1-01 wins both W13 waves with touch deployment and automatic Ranger combat")
	_check(troops.settlement.credited == 10000 and troops.settlement.pending_awards == ["first_perfect_funds"], "C1-01 pays the approved first clear and identifies the pending perfect award")
	app.show_story()
	_check(not _node(app._screen, c2).disabled and _node(app._screen, c4).disabled, "Clearing the predecessor unlocks the next revealed operation only")
	_node(app._screen, c2).pressed.emit()
	_check(app._screen.find_child("StartOperation", true, false).disabled, "C1-02 plan needs the Mechanical slot before Start")
	app._screen.find_child("OpenHeadquarters", true, false).pressed.emit()
	app._screen.find_child("Room_mechanical", true, false).pressed.emit()
	var mechanical := app._screen as HeadquartersRoomPage
	_check(not mechanical._purchase.disabled and progress.funds() == 20000, "C1-01 earns exactly enough for Mechanical")
	mechanical._purchase.pressed.emit()
	mechanical._dialog.hide()
	mechanical._dialog.confirmed.emit()
	_check(progress.room_level(HeadquartersCatalog.MECHANICAL) == 1 and progress.funds() == 0, "Build Mechanical debits the approved Campaign earnings exactly")
	mechanical.back_requested.emit()
	(app._screen as HeadquartersOverview).back_requested.emit()
	_check(app._screen.plan.can_start() and app._screen.plan.facility_limit == 2, "Returning from Access equips the newly legal Logistics Post")
	await _funded_launch_resume(app, c2)
	_play_second_operation(app._screen.plan)
	# Simulated active accrual exercises the real storage cap, claim and upgrade
	# purchases while W13's release payouts await approval.
	_fund_control(progress, 5)
	_check(progress.is_visible(finale) and not progress.access_error(finale).is_empty(), "Max Control reveals the finale without bypassing its uncleared predecessor")
	var spawned := 14
	var tested_waves: int = c1.stage.waves.size()
	for i in range(1, campaign.operations.size()):
		var operation := campaign.operations[i]
		if i + 1 < campaign.operations.size():
			var successor := campaign.operations[i + 1]
			_check(progress.access_error(successor) == "Clear %s first" % operation.stage.stage_id, "%s stays locked until its immediate predecessor clears" % successor.stage.stage_id)
		var field := _open(app, operation)
		var normal_post := _entry(field.operation_plan, &"facility.logistics_post")
		if i == 1:
			await _consume_dialogue(field, true, [])
			_check(normal_post != null and field.battle.deployment.deploy(normal_post, Vector2i(1, 0), 1).is_empty() and field.battle.deployment.tokens == 0, "C1-02 battle accepts the funded free ordinary Post")
		if operation.opening_rules.fixed_stockpile:
			_check(normal_post == null and field.battle.deployment.tokens == 120, "C1-05 field loads 120 Tokens and omits the Post")
		if operation.has_heat:
			_check(field.get_node("%HeatRow").visible, "%s displays the Heat HUD" % operation.stage.stage_id)
		var timeline := await _drive(field, true)
		_check(timeline.missing_art.is_empty(), "%s resolves exact live field rig paths: %s" % [
			operation.stage.stage_id, timeline.missing_art])
		await process_frame
		var report: Dictionary = app._screen.report
		var phase_spawns := 3 if operation == finale else 0
		var base_script := _expected_spawns(operation.stage)
		if operation.has_heat:
			var expected_heat: Array = base_script.filter(func(entry: Array) -> bool: return entry[2] == &"E14")[0]
			var scale := 0.6 if operation.stage.stage_id == &"C2-07" else 1.0
			var rate := preload("res://data/enemies/e14_ignition_operator.tres").heat_per_second
			_check(timeline.heat_tick == expected_heat[0] and is_equal_approx(timeline.first_heat, rate * CombatClock.STEP_SECONDS * 1.3 * scale), "%s applies D14 and the actual Firebreak state at first Heat" % operation.stage.stage_id)
			if operation.stage.stage_id == &"C2-07":
				_check(timeline.heat_tick == 5341, "C2-07 first Heat arrives at the eased opener tick after the Beacon build")
		_check(timeline.spawns.slice(0, base_script.size()) == base_script and timeline.spawns.size() == base_script.size() + phase_spawns, "%s spawns the authored order, route and tick plus scheduled phase support" % operation.stage.stage_id)
		_check(report.defeated == base_script.size() + phase_spawns and report.escaped == 0 and report.balance == progress.snapshot().funds and report.settlement.first_clear, "%s settles a perfect first clear through the runtime result" % operation.stage.stage_id)
		if operation.stage.stage_id == &"C1-03":
			_check(timeline.messenger.count == 1 and "dialogue.c1_03.messenger" in timeline.beats and report.defeated == 33 and report.integrity == 100, "C1-03 records one noncombat withdrawal while preserving counts and Integrity")
		if operation.stage.stage_id == &"C1-05":
			_check(report.outcome == "Boss captured" and report.perfect and "dialogue.c1_05.boss_phase_1" in timeline.beats, "C1-05 captures the Captain and retires outstanding phase orders")
		if operation == finale:
			_check("dialogue.c2_10.boss_phase_2" in timeline.beats and timeline.beats.back() == "dialogue.c2_10.epilogue" and report.settlement.pending_awards.has("story_completion_funds"), "Finale resolves both phases and runners, then shows the first-clear epilogue")
		spawned += timeline.spawns.size()
		tested_waves += operation.stage.waves.size()
		_check(progress.record_for(operation.stage.stage_id).perfect and progress.snapshot().pending_attempt.is_empty(), "%s persists perfect and closes the attempt" % operation.stage.stage_id)
		for id in operation.clear_unlock_ids:
			_check(String(id) in progress.snapshot().owned, "Clear persists " + String(id))
	_check(progress.snapshot().records.size() == 15 and spawned == 1114 and tested_waves == 49, "All 15 operations clear sequentially across 49 waves and 1,114 actual arrivals")
	_check(_portrait_keys.size() == 10, "All ten authored speaker and pose combinations resolve approved portrait art")
	_check("facility.firebreak_beacon" not in progress.snapshot().owned, "Trial supplies expire after C2-07 settlement")
	await _replay_and_losses(app, c1, finale)
	if _capture_dir.is_empty():
		await _all_result_paths(app, campaign)
	app.free()
	_finish()

func _launcher() -> Control:
	var app := LAUNCHER.instantiate()
	app.save_path = _path + ".legacy"
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	return app

func _play_first_contact(app: Control, first: StoryOperation) -> Dictionary:
	_node(app._screen, first).pressed.emit()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	await process_frame
	await process_frame
	var battle := field.battle
	var state := battle.deployment
	_verify_portrait(field)
	if not _capture_dir.is_empty():
		await _capture("t01-briefing")
	var opening := _pause_snapshot(battle)
	field.get_node("%Continue").pressed.emit()
	battle.clock.advance_frame()
	_check(field.dialogue_id == "dialogue.c1_01.opening" and opening == _pause_snapshot(battle), "Continue holds the opening until its last line")
	app._process(5.0)
	_check(app._campaign_progress.snapshot().finance == 0.0, "Finance does not accrue behind full-screen dialogue")
	_verify_portrait(field)
	field.get_node("%Skip").pressed.emit()
	var board: BattleBoard = field.get_node("%Board")
	var tray: Control = field.get_node("%DeploymentTray")
	_check(field.get_global_rect().encloses(board.get_global_rect()) and field.get_global_rect().encloses(tray.get_global_rect()), "Story HUD, field and tray fit 960×540 landscape")
	_drag(_card(tray, "Logistics Post"), board, Vector2i(4, 3), 0.0)
	_check(state.tokens == 0 and state.occupancy.is_empty(), "Invalid Campaign touch drop spends zero and preserves occupancy")
	_drag(_card(tray, "Logistics Post"), board, Vector2i(1, 0), 0.0)
	_check(state.posts_deployed == 1 and state.tokens == 0 and state.occupancy.size() == 2, "Touch places the mission Post on a legal elevated pair")
	for i in 1200:
		battle.clock.advance_frame()
	_drag(_card(tray, "Scout Sniper"), board, Vector2i(5, 2), 0.0)
	for i in 600:
		battle.clock.advance_frame()
	_drag(_card(tray, "Patrolman"), board, Vector2i(6, 3), -8.0)
	_check(state.placed.has(&"ranger.scout_sniper") and state.placed.has(&"ranger.patrolman"), "Campaign tray deploys canonical Scout and Patrolman by touch")
	if not _capture_dir.is_empty():
		field._refresh()
		await _capture("t01-first-contact")

	while not battle.clock.stopped and battle.clock.tick < 15000:
		battle.clock.advance_frame()
		if battle.clock.dialogue_open:
			await _consume_dialogue(field, true, [])
	field._refresh()
	await _consume_dialogue(field, true, [])
	await process_frame
	return app._screen.report

func _funded_launch_resume(app: Control, operation: StoryOperation) -> void:
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	field.get_node("%Skip").pressed.emit()
	field.get_node("%Pause").pressed.emit()
	var frozen := _pause_snapshot(field.battle)
	app._process(5.0)
	field.battle.clock.advance_frame()
	_check(frozen == _pause_snapshot(field.battle) and app._campaign_progress.snapshot().finance == 0.0, "Pause freezes Campaign combat and Finance")
	var resumed := _launcher()
	_check(resumed._route == &"plan" and resumed._screen.plan.operation.stage.stage_id == operation.stage.stage_id, "Relaunch opens the interrupted operation plan")
	resumed.free()
	var modal := field.get_node("%PauseOverlay")
	modal.find_child("AskAbandon", true, false).pressed.emit()
	modal.find_child("ConfirmAbandon", true, false).pressed.emit()
	_check(app._route == &"plan" and app._campaign_progress.snapshot().pending_attempt.is_empty() and app._campaign_progress.record_for(operation.stage.stage_id).is_empty(), "Confirmed abandon clears the attempt without clearing the mission")

func _play_second_operation(plan: OperationPlan) -> void:
	var resolved := plan.resolved()
	var battle := BattleSimulation.new(resolved.stage)
	var state := DeploymentState.new(resolved.stage.map, battle.clock, resolved.tokens, resolved.opening, [], battle.effects)
	battle.deployment = state
	var scout := _entry(plan, &"ranger.scout_sniper")
	var patrol := _entry(plan, &"ranger.patrolman")
	var post := _entry(plan, &"facility.logistics_post")
	_check(state.deploy(post, Vector2i(1, 0), 1).is_empty(), "C1-02 starts with an ordinary free Post")
	var queue: Array = [[scout, Vector2i(5, 2)], [patrol, Vector2i(6, 3)], [scout, Vector2i(6, 2)],
		[patrol, Vector2i(9, 3)], [scout, Vector2i(8, 2)]]
	for frame in 15000:
		if battle.outcome != BattleSimulation.Outcome.RUNNING:
			break
		battle.clock.advance_frame()
		if not queue.is_empty() and state.deploy(queue[0][0], queue[0][1], -1).is_empty():
			queue.pop_front()
	_check(queue.is_empty(), "C1-02 places repeat Rangers with earned Tokens and per-type cooldowns")
	_check(battle.outcome == BattleSimulation.Outcome.WON and battle.integrity == 90 and battle.defeated == 17 and battle.escaped == 1 and not battle.is_perfect(),
		"C1-02 clears via autonomous combat with one ordinary escape")

func _open(app: Control, operation: StoryOperation) -> CampaignBattle:
	app.show_story()
	var button := _node(app._screen, operation)
	_check(not button.disabled, "Campaign opens %s after the preceding clear" % operation.stage.stage_id)
	button.pressed.emit()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	_check(field.battle.clock.tick == 0 and field.battle.integrity == 100 and field.battle.clock.dialogue_open, "%s starts held at 100 Integrity" % field.stage.stage_id)
	var art := (field.get_node("%Board") as BattleBoard).first_contact_field
	_check(field._illustrated and art != null, "%s opens the illustrated operation through Story" % field.stage.stage_id)
	if art != null and field.stage.map.map_id != &"T01":
		_check(_region_matches(field.stage, art), "%s keeps every registered route, entry and exit on live geometry" % field.stage.stage_id)
	return field

func _drive(field: CampaignBattle, read: bool, escape_id := &"") -> Dictionary:
	var battle := field.battle
	var reference: WeakRef = weakref(battle)
	var spawns := []
	var missing_art := {}
	var beats := []
	var holds := []
	var messenger := {"count": 0}
	var forced_escape := 0
	var heat_tick := 0
	var first_heat := 0.0
	var supplies_beacon := field.stage.stage_id == &"C2-07"
	battle.enemy_spawned.connect(func(id: int, definition_id: StringName) -> void:
		var sim: BattleSimulation = reference.get_ref()
		var enemy := sim.active[id]
		spawns.append([sim.clock.tick, sim.wave_number, definition_id, enemy.route.cells.front()])
		var art := (field.get_node("%Board") as BattleBoard).first_contact_field
		var actor: FirstContactField.Actor = art.enemies.get(id) if art != null else null
		var expected := String(FirstContactSkin.w29_art(definition_id).get("rig", ""))
		if actor == null or actor.enemy != enemy or actor.rig.scene_file_path != expected:
			missing_art[definition_id] = true
	)
	battle.cinematic_withdrawal.connect(func() -> void: messenger.count += 1)
	var map_id := String(field.stage.map.map_id).to_lower()
	var field_shot := false
	var boss_shot := false
	await _consume_dialogue(field, read, holds, beats)
	if not _capture_dir.is_empty() and not supplies_beacon and map_id != "t01":
		var post := _entry(field.operation_plan, &"facility.logistics_post")
		if post != null:
			for tile: Vector2i in field.stage.map.elevated:
				if battle.deployment.deploy(post, tile, 1).is_empty():
					break
	if supplies_beacon:
		var post := _entry(field.operation_plan, &"facility.logistics_post")
		_check(battle.deployment.deploy(post, Vector2i(1, 0), 1).is_empty(), "C2-07 places its ordinary Post to fund the supplied Beacon")
	for i in 40000:
		await _consume_dialogue(field, read, holds, beats)
		if battle.clock.stopped:
			break
		battle.clock.advance_frame()
		if battle.clock.dialogue_open:
			continue
		if supplies_beacon and battle.clock.tick == 1800:
			var beacon := _entry(field.operation_plan, &"facility.firebreak_beacon")
			var state := battle.deployment
			_check(state.tokens == beacon.cost and state.deploy(beacon, Vector2i(5, 0), 1).is_empty() and state.tokens == 0, "Firebreak uses its ordinary 30-Token cost and a legal raised pair")
		if heat_tick == 0 and battle.heat > 0.0:
			heat_tick = battle.clock.tick
			first_heat = battle.heat
		if not _capture_dir.is_empty() and not field_shot and not battle.active.is_empty() and map_id != "t01":
			field_shot = true
			field._refresh()
			await _capture("%s-%s" % [map_id, String(field.stage.stage_id).to_lower()])
		for id: int in battle.active.keys():
			var enemy := battle.active[id]
			if forced_escape == 0 and enemy.definition.enemy_id == escape_id:
				forced_escape = id
				enemy.distance = enemy.route.cells.size() - 1.0 - 0.00001
			if id == forced_escape:
				continue
			if not _capture_dir.is_empty() and not boss_shot and enemy.boss != null:
				boss_shot = true
				field._refresh()
				await _capture("%s-%s" % [String(field.stage.stage_id).to_lower(), "boss-defeat" if not escape_id.is_empty() else "boss"])
			if enemy.boss != null and enemy.phase_index < enemy.boss.phases.size():
				var threshold := floori(enemy.boss.max_hp * enemy.boss.phases[enemy.phase_index].hp_percent / 100.0)
				battle.damage_enemy(id, enemy.hp - threshold + enemy.active_shield(battle.clock.tick))
			else:
				battle.damage_enemy(id, enemy.hp + enemy.active_shield(battle.clock.tick))
			if not battle.clock.is_running():
				break
	field._refresh()
	await _consume_dialogue(field, read, holds, beats)
	if not _capture_dir.is_empty() and (field.stage.stage_id == &"C2-10" or field.stage.stage_id == &"C2-08"):
		await _capture("%s-%s" % [String(field.stage.stage_id).to_lower(), "alternate-result" if not escape_id.is_empty() else "result"])
	return {"missing_art": missing_art, "spawns": spawns, "beats": beats, "holds": holds, "messenger": messenger, "heat_tick": heat_tick, "first_heat": first_heat}

func _replay_and_losses(app: Control, first: StoryOperation, finale: StoryOperation) -> void:
	var c3: StoryOperation = app._campaign.operation(&"C1-03")
	var field := _open(app, c3)
	var read := await _drive(field, true)
	await process_frame
	field = _open(app, c3)
	var skipped := await _drive(field, false)
	await process_frame
	_check(read.spawns == skipped.spawns and read.holds == skipped.holds and read.messenger.count == skipped.messenger.count, "Continue and Skip agree at opening, messenger and outcome, including every spawn tick")
	field = _open(app, finale)
	var read_boss := await _drive(field, true)
	await process_frame
	_check(not "dialogue.c2_10.epilogue" in read_boss.beats and app._screen.report.settlement.pending_awards == ["replay_funds"], "Finale replay excludes its first completion reward and epilogue")
	field = _open(app, finale)
	var skipped_boss := await _drive(field, false)
	await process_frame
	_check(read_boss.spawns == skipped_boss.spawns and read_boss.holds == skipped_boss.holds, "Continue and Skip preserve prewave, boss arrival, both phases and outcome state")
	var defeat_cases := [
		[&"C1-05", &"boss.diversion_captain", "dialogue.c1_05.defeat_captain"],
		[&"C2-09", &"E15", "dialogue.c2_09.defeat_trafficker"],
		[&"C2-10", &"boss.poacher_leader", "dialogue.c2_10.defeat_leader"],
	]
	for test in defeat_cases:
		var operation: StoryOperation = app._campaign.operation(test[0])
		field = _open(app, operation)
		var ending := await _drive(field, false, test[1])
		await process_frame
		var report: Dictionary = app._screen.report
		_check(report.fatal_escape_id == test[1] and report.integrity == 0 and report.escaped == 1 and report.settlement.is_empty() and ending.beats.back() == test[2], "%s resolves a forced fatal escape with its own defeat copy and no reward" % test[0])
	var foreman: StoryOperation = app._campaign.operation(&"C2-08")
	field = _open(app, foreman)
	var ending := await _drive(field, false, &"boss.illegal_logging_foreman")
	await process_frame
	_check(app._screen.report.outcome == "Clear" and app._screen.report.integrity == 50 and app._screen.report.escaped == 1 and ending.beats.back() == "dialogue.c2_08.victory_foreman_escaped", "Foreman trial escape applies ordinary loss and alternate clear dialogue")
	field = _open(app, first)
	_check(field.operation_plan.deployment_entries().size() == 3 and field.battle.deployment.tokens == 0, "Developed profile replays C1-01 with its original supply")
	var replay := await _drive(field, false, &"E01")
	await process_frame
	var report: Dictionary = app._screen.report
	_check(not replay.beats.is_empty() and report.outcome == "Clear" and report.integrity == 90 and report.escaped == 1 and app._campaign_progress.record_for(&"C1-01").perfect, "Ordinary early replay records the escape and preserves permanent perfect status")

func _all_result_paths(app: Control, campaign: CampaignContent) -> void:
	for operation: StoryOperation in campaign.operations:
		var field := _open(app, operation)
		var ordinary: StringName
		for group: BattleSpawnGroup in operation.stage.waves.front().groups:
			if group.count > 0 and not group.enemy.escape_causes_defeat:
				ordinary = group.enemy.enemy_id
				break
		var completed := await _drive(field, false, ordinary)
		await process_frame
		var report: Dictionary = app._screen.report
		_check(not ordinary.is_empty() and report.escaped == 1 and report.integrity > 0
			and not report.perfect and report.outcome != "Defeat" and not report.settlement.first_clear,
			"%s settles an ordinary escape on replay through its authored events: %s" % [operation.stage.stage_id, completed.beats])
		var balance: int = report.balance
		field = _open(app, operation)
		await _consume_dialogue(field, false, [])
		for frame in 40000:
			field.battle.clock.advance_frame()
			await _consume_dialogue(field, false, [])
			if field.battle.clock.stopped:
				break
		field._refresh()
		await _consume_dialogue(field, false, [])
		await process_frame
		report = app._screen.report
		_check(report.outcome == "Defeat" and report.integrity == 0 and report.settlement.is_empty()
			and report.balance == balance and app._campaign_progress.record_for(operation.stage.stage_id).perfect,
			"%s undefended result keeps the previous perfect record and Funds" % operation.stage.stage_id)
		app._screen.find_child("ReviewPlan", true, false).pressed.emit()
		_check(app._screen.plan.operation.stage.stage_id == operation.stage.stage_id,
			"%s defeat returns to the correct plan" % operation.stage.stage_id)

func _consume_dialogue(field: CampaignBattle, read: bool, holds: Array, beats := []) -> void:
	var battle := field.battle
	while battle.clock.dialogue_open:
		var id := field.dialogue_id
		var snapshot := _pause_snapshot(battle)
		battle.clock.advance_frame()
		battle.clock.advance_frame()
		var stayed := snapshot == _pause_snapshot(battle)
		while field.dialogue_id == id and battle.clock.dialogue_open:
			_verify_portrait(field)
			if not _capture_dir.is_empty():
				var line: Dictionary = field._active_beat.lines[field._line_index]
				var key := ""
				if line.speaker_id in ["speaker.diversion_captain", "speaker.illegal_logging_foreman", "speaker.poacher_leader", "speaker.poacher", "speaker.poacher_messenger"]:
					key = "portrait-" + line.speaker_id.trim_prefix("speaker.") + "-" + line.pose_key
				if field._active_beat.trigger.event == "after_victory_dialogue":
					key = "first-clear-epilogue"
				if not key.is_empty() and not FileAccess.file_exists(_capture_dir.path_join(key + ".png")):
					await _capture(key)
			var button := "%Continue" if read else "%Skip"
			field.get_node(button).pressed.emit()
		_check(stayed and snapshot == _pause_snapshot(battle), "%s holds all observed combat state through dismissal" % id)
		holds.append([id, snapshot])
		beats.append(id)

func _verify_portrait(field: CampaignBattle) -> void:
	var line: Dictionary = field._active_beat.lines[field._line_index]
	var portrait := field._portrait
	var identity: String = field.content.speakers[line.speaker_id].portrait_key
	var key: String = identity + "/" + line.pose_key
	if not _portrait_keys.has(key):
		_portrait_keys[key] = true
		_check(portrait.identity == identity and portrait.pose == line.pose_key and portrait._texture != null,
			"Approved portrait registration resolves " + key)
	_check(field.get_node("%DialogueText").text == line.text, "Runtime preserves the authored text for " + field.dialogue_id)
	if field._epilogue_art != null:
		_check(field._epilogue_art.visible == (field._active_beat.trigger.event == "after_victory_dialogue"),
			"Epilogue art follows the existing first-clear event only")

func _region_matches(stage: BattleStage, art: FirstContactField) -> bool:
	if art._regional == null:
		return false
	var layout := art._regional.layout
	if layout.route_cells.size() != stage.routes.size() or layout.entries.size() != stage.map.spawns.size():
		return false
	for i in stage.routes.size():
		var cells: Array = layout.route_cells[i]
		if cells.size() != stage.routes[i].cells.size():
			return false
		for j in cells.size():
			if Vector2i(FirstContactSkin.vector(cells[j])) != stage.routes[i].cells[j]:
				return false
		if Vector2i(FirstContactSkin.vector(layout.entries[i].cell)) != stage.map.spawns[i]:
			return false
	return Vector2i(FirstContactSkin.vector(layout.exit.cell)) == stage.map.tunnel

func _capture(key: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size and image.save_png(_capture_dir.path_join(key + ".png")) == OK,
		"Native framebuffer capture " + key)

func _pause_snapshot(battle: BattleSimulation) -> Array:
	var live := []
	for enemy: BattleEnemy in battle.active.values():
		live.append([enemy.definition.enemy_id, enemy.hp, enemy.distance, enemy.phase_index, enemy.shield_until, enemy.ability_ready_tick])
	var placed := []
	for unit: DeploymentState.Placement in battle.deployment.placed.values():
		placed.append([unit.spec.id, unit.hp, unit.build_deadline, unit.next_payout_tick, unit.skill_recharge_tick])
	return [battle.clock.tick, battle.wave_number, battle.integrity, battle.heat, battle.deployment.tokens, battle.defeated, battle.escaped, battle.expected_enemy_count, live, placed]

func _expected_spawns(stage: BattleStage) -> Array:
	var path := CampaignContent.SOURCE + "stages/%s.json" % String(stage.stage_id).to_lower()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var modifiers: Array = source.operation.fixed_debuff_ids
	var pacing: Dictionary = source.balance_trial.get("c31_c_pacing", source.balance_trial.get("c30_pacing", {}))
	var multipliers: Array = pacing.get("wave_interval_multipliers", [])
	var intervals: Array = pacing.get("wave_interval_seconds", [])
	var tick := 1 + CombatClock.ticks_for(source.balance_trial.opening_delay_seconds + pacing.get("preparation_seconds", 0.0))
	var expected := []
	for i in source.waves.size():
		var wave: Dictionary = source.waves[i]
		var last := tick
		for group in wave.groups:
			for n in int(group.count):
				last = tick
				expected.append([tick, i + 1, StringName(group.enemy_id), stage.routes[int(group.route_index)].cells.front()])
				var interval: float = intervals[i] if not intervals.is_empty() else group.base_interval_seconds * (1.0 if multipliers.is_empty() else multipliers[i])
				tick += maxi(1, CombatClock.ticks_for(interval * (0.8 if "D13" in modifiers else 1.0)))
		tick = last + maxi(1, CombatClock.ticks_for(wave.base_rest_after_seconds * (0.6 if "D07" in modifiers else 1.0)))
	return expected

func _fund_control(progress: CampaignProgress, target: int) -> void:
	while progress.room_level(HeadquartersCatalog.CONTROL) < target:
		var cost: int = progress.room_quote(HeadquartersCatalog.CONTROL).cost
		while progress.snapshot().funds < cost:
			progress.advance_finance(6000.0)
			progress.claim_finance()
		if not progress.purchase_room(HeadquartersCatalog.CONTROL).is_empty():
			_check(false, "Funded Control upgrade persists")
			return

func _node(page: Control, operation: StoryOperation) -> Button:
	return page.find_child("Operation_" + String(operation.stage.stage_id).replace("-", "_"), true, false)

func _entry(plan: OperationPlan, id: StringName) -> DeploymentSpec:
	for spec in plan.deployment_entries():
		if spec.id == id:
			return spec
	return null

func _card(tray: Control, label: String) -> Control:
	for card: Control in tray.get_children():
		if card.is_visible_in_tree() and card.get_child(0).get_child(1).text.begins_with(label):
			return card
	return null

func _drag(card: Control, board: BattleBoard, cell: Vector2i, offset: float) -> void:
	var start := card.get_global_rect().get_center()
	var target := board.get_global_transform_with_canvas() * (board.cell_center(cell) + Vector2(offset, 0))
	_touch(start, true)
	var motion := InputEventScreenDrag.new()
	motion.position = target
	motion.relative = target - start
	root.push_input(motion, true)
	_touch(target, false)

func _touch(point: Vector2, down: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = down
	root.push_input(touch, true)

func _finish() -> void:
	for stem in [_path, _path + ".legacy"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("Campaign story: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
