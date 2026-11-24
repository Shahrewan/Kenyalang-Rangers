extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const STAGE := &"C1-03"
const POST := &"facility.logistics_post"
const PATROL := &"ranger.patrolman"
const SCOUT := &"ranger.scout_sniper"
const MEDIC := &"ranger.combat_medic"
const TURRET := &"facility.sonic_turret"
const MESSENGER := "dialogue.c1_03.messenger"
const NORMAL := [[SCOUT, Vector2i(5, 2)], [PATROL, Vector2i(6, 3)], [MEDIC, Vector2i(6, 2)],
	[TURRET, Vector2i(5, 0)], [SCOUT, Vector2i(1, 2)], [PATROL, Vector2i(9, 3)], [SCOUT, Vector2i(8, 2)]]
const PERFECT := [[PATROL, Vector2i(10, 3)], [SCOUT, Vector2i(5, 2)], [SCOUT, Vector2i(9, 2)],
	[SCOUT, Vector2i(1, 2)], [PATROL, Vector2i(9, 3)], [TURRET, Vector2i(5, 0)],
	[SCOUT, Vector2i(8, 2)], [MEDIC, Vector2i(8, 0)]]

var _checks := 0
var _failures := 0
var _save := "user://c28-c-%d.json" % OS.get_process_id()
var _output := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		root.size = Vector2i(960, 540)
	else:
		_output = args[0]
		DirAccess.make_dir_recursive_absolute(_output)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Ari"
	profile.rooms["room.records"] = 4
	profile.rooms["room.r_d_crisis"] = 3
	profile.encyclopaedia.perfect_chapters = ["records_chapter.combat_medic"]
	ProfileFile.replace(_save, profile, false)
	var app := _launcher()
	await _developer_settings(app)
	var progress: CampaignProgress = app._campaign_progress
	var content: CampaignContent = app._campaign
	var c1 := content.operation(&"C1-01")
	var c2 := content.operation(&"C1-02")
	app.show_story()
	_check(_story_node(app).disabled, "C1-03 is locked before C1-02")
	progress.begin_attempt(c1)
	progress.complete(c1, false)
	progress.purchase_room(HeadquartersCatalog.MECHANICAL)
	app.show_story()
	_check(_story_node(app).disabled, "Clearing C1-01 alone keeps Narrow Escape locked")
	progress.begin_attempt(c2)
	progress.complete(c2, false)
	app.show_story()
	_check(not _story_node(app).disabled and progress.owns(MEDIC) and progress.owns(TURRET),
		"C1-02 opens Narrow Escape and grants the supported Medic and Turret")
	_story_node(app).pressed.emit()
	var badge: TextureRect = app._screen.find_child("E03Badge", true, false)
	_check(badge != null and badge.texture.resource_path == FirstContactSkin.w29_art(&"E03").badge, "Planning shows the approved E03 Intel badge")
	await _capture("planning-intel", app._screen)
	var failed := await _play(app, "defeat", [])
	_check(failed.outcome == "Defeat" and failed.integrity == 0 and failed.escaped == 10 and failed.defeated == 0
		and failed.settlement.is_empty() and progress.record_for(STAGE).is_empty(), "Undefended defeat consumes no clear or reward")
	app._screen.find_child("ReviewPlan", true, false).pressed.emit()
	_check(app._route == &"plan" and app._screen.plan.operation.stage.stage_id == STAGE, "Review plan retries the same Story operation")
	var normal := await _play(app, "normal", NORMAL.duplicate())
	_check(normal.outcome == "Clear" and normal.integrity > 0 and normal.escaped > 0 and normal.defeated + normal.escaped == 33
		and normal.settlement.first_clear and normal.settlement.pending_awards == ["first_clear_funds"]
		and normal.settlement.credited == 0 and normal.settlement.unlocked == [&"ranger.guard_veteran", &"facility.medic_cabin"],
		"Ordinary clear settles the existing unlocks and pending reward key")
	_check(progress.adjust_developer_funds(DeployableLevels.TOTAL_COST) and progress.purchase_levels(POST, 100).is_empty(),
		"The perfect replay uses the existing level-100 Logistics Post")
	app.show_story()
	_story_node(app).pressed.emit()
	var plan: OperationPlan = app._screen.plan
	_check(plan.select_buff(BattleModifiers.CATALOG.definition(&"B13")) and plan.resolved().tokens == 35,
		"The perfect replay equips the already unlocked Emergency Requisition")
	app._screen._refresh_plan()
	var perfect := await _play(app, "perfect", PERFECT.duplicate())
	_check(perfect.outcome == "Perfect clear" and perfect.integrity == 100 and perfect.escaped == 0 and perfect.defeated == 33
		and perfect.settlement.pending_awards == ["replay_funds", "first_perfect_funds"]
		and perfect.settlement.credited == 0 and perfect.settlement.unlocked.is_empty(), "Perfect replay keeps the two pending reward keys and pays no Funds")
	var saved_funds := progress.funds()
	app.free()
	await process_frame
	app = _launcher()
	var restored: CampaignProgress = app._campaign_progress
	_check(restored.record_for(STAGE) == {"cleared": true, "perfect": true} and restored.funds() == saved_funds
		and restored.snapshot().pending_attempt.is_empty() and restored.owns(&"ranger.guard_veteran")
		and restored.owns(&"facility.medic_cabin"), "Relaunch restores the perfect flag, unlocks and Funds")
	_check(FirstContactSkin.is_pilot(&"C1-03") and not FirstContactSkin.is_pilot(&"C1-04") and not FirstContactSkin.illustrates_operation(&"chaos"),
		"The original pilot bindings stay scoped to C1-01–03 and exclude Chaos")
	await _terminal_support(app)
	app.free()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(_save + suffix)
	print("Narrow Escape: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

func _launcher() -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _save
	app.save_path = _save + ".legacy"
	root.add_child(app)
	app.set_process(false)
	return app

func _story_node(app: Control) -> Button:
	return app._screen.find_child("Operation_C1_03", true, false)

func _developer_settings(app: Control) -> void:
	var progress: CampaignProgress = app._campaign_progress
	var before := progress.snapshot()
	app._screen.get_node("%OpenSettings").pressed.emit()
	var page: ProfileSettingsPage = app._screen
	var input: LineEdit = page.find_child("DeveloperFundsAmount", true, false)
	var add: Button = page.find_child("DeveloperAddFunds", true, false)
	var remove: Button = page.find_child("DeveloperRemoveFunds", true, false)
	input.text = "250"
	add.pressed.emit()
	_check(progress.funds() == int(before.funds) + 250, "Settings Developer adds Funds to the saved Campaign wallet")
	input.text = "50"
	remove.pressed.emit()
	input.text = "abc"
	add.pressed.emit()
	input.text = "10000000"
	add.pressed.emit()
	_check(progress.funds() == int(before.funds) + 200, "Remove Funds and invalid input use the same local wallet")
	input.text = str(FundsWallet.CAP)
	add.pressed.emit()
	_check(progress.funds() == FundsWallet.CAP, "Developer addition clamps to the existing cap")
	remove.pressed.emit()
	_check(progress.funds() == 0, "Developer removal clamps to zero")
	input.text = str(before.funds)
	add.pressed.emit()
	_check(progress.snapshot() == before and CampaignProgress.new(_save).funds() == before.funds,
		"The saved Developer adjustment touches only Funds")
	if not _output.is_empty():
		await process_frame
		var scroll: ScrollContainer = page.find_children("*", "ScrollContainer", true, false).front()
		scroll.ensure_control_visible(input)
		await _capture("developer-settings", page)
	page.request_back()

func _play(app: Control, scenario: String, queue: Array) -> Dictionary:
	var progress: CampaignProgress = app._campaign_progress
	var original_funds := progress.funds()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	await process_frame
	var battle := field.battle
	var art := field._board.first_contact_field
	var state := battle.deployment
	var d03: Array[StringName] = field.operation_plan.operation.fixed_debuff_ids
	_check(art != null and field._portrait.illustrated and battle.expected_enemy_count == 33 and d03 == [&"D03"],
		"%s opens illustrated T01 with 33 actors and D03" % scenario)
	var opened := {}
	var clips := {}
	var observations := {"messenger": 0, "processed": false, "mixed": false, "clock": false, "retreat": false,
		"skill": false, "heal": false, "build": false, "sonic": false, "ready": false}
	var live: WeakRef = weakref(battle)
	battle.enemy_spawned.connect(func(_serial: int, _kind: StringName) -> void:
		var wave: int = live.get_ref().wave_number
		opened[wave] = opened.get(wave, 0) + 1)
	var resolutions := {}
	battle.enemy_resolved.connect(func(id: int, escaped: bool) -> void:
		var actor: FirstContactField.Actor = art.enemies.get(id)
		resolutions[id] = not resolutions.has(id) and actor != null and actor.clip == (&"Exit" if escaped else &"Defeat"))
	battle.cinematic_withdrawal.connect(func() -> void: observations.messenger += 1)
	field.get_node("%Continue").pressed.emit()
	_check(field.get_node("%DialogueText").text.contains("Retreat"), "Opening keeps the authored Retreat and skill instructions")
	_skip(field)
	if not queue.is_empty():
		_drop(field, POST, Vector2i(1, 0))
	var main_fixture := scenario == "normal"
	for frame in 22000:
		battle.clock.advance_frame()
		if field.dialogue_id == MESSENGER and not observations.processed:
			await _messenger(field, progress, observations, opened, resolutions, main_fixture)
		if battle.clock.stopped:
			break
		if not queue.is_empty():
			var controller = field.get_node("%DeploymentController")
			var spec: DeploymentSpec = controller._offered[queue[0][0]]
			if state.placement_error(spec, queue[0][1]).is_empty():
				_drop(field, queue[0][0], queue[0][1])
				queue.pop_front()
		var active_ids := {}
		var running_e03: FirstContactField.Actor
		for actor: FirstContactField.Actor in art.enemies.values():
			var kind := actor.enemy.definition.enemy_id
			if not actor.terminal:
				active_ids[kind] = true
			if kind == &"E03":
				clips[actor.clip] = true
				if actor.clip in [&"Move", &"Sprint"]:
					running_e03 = actor
		if main_fixture and not observations.mixed and active_ids.size() == 3:
			observations.mixed = true
			_check(running_e03 != null and running_e03.parts.size() == 16, "E01, E02 and E03 coexist as separate cutout rigs")
			await _capture("mixed-wave", field)
		if main_fixture and not observations.clock and running_e03 != null and running_e03.clip == &"Move":
			_check_clock(field, running_e03)
			observations.clock = true
		if main_fixture:
			await _observe_support(field, observations)
	_check(resolutions.size() == battle.defeated + battle.escaped and not resolutions.values().has(false),
		"Each combat resolution has exactly one visual terminal event in " + scenario)
	if scenario != "defeat":
		_check(opened == {1: 9, 2: 11, 3: 13} and observations.messenger == 1 and observations.processed,
			"Completed %s keeps all authored wave counts and one cinematic" % scenario)
	if main_fixture:
		_check(observations.mixed and observations.clock and observations.retreat and observations.skill,
			"Live C1-03 exercises the mixed cast, clock and both tutorial cues")
		_check(observations.heal and observations.sonic and observations.build and observations.ready,
			"Combat Medic heals and Sonic Turret builds, becomes ready and attacks")
		_check(clips.has_all([&"Move", &"Sprint", &"Blocked", &"Attack", &"Hit", &"Defeat", &"Exit"]),
			"C1-03 observed all seven E03 animation states")
	var tick := battle.clock.tick
	field._refresh()
	_skip(field)
	await process_frame
	var report: Dictionary = app._screen.report
	_check(report.balance == original_funds and not report.save_failed, "C1-03 %s report preserves the original wallet" % scenario)
	print("C1-03 %s at %d: %d defeated, %d escaped, %d Integrity" % [scenario, tick, report.defeated, report.escaped, report.integrity])
	await _capture("result-" + scenario, app._screen)
	return report

func _messenger(field: CampaignBattle, progress: CampaignProgress, observations: Dictionary, opened: Dictionary,
		resolutions: Dictionary, read_lines: bool) -> void:
	var battle := field.battle
	var before := [battle.clock.tick, battle.active.size(), battle.defeated, battle.escaped, battle.integrity, progress.funds(), resolutions.size()]
	_check(opened == {1: 9, 2: 11} and before[1] == 0 and observations.messenger == 1, "Messenger is triggered once after wave 2 with zero active actors")
	if read_lines:
		field.get_node("%Continue").pressed.emit()
		_check(field._portrait.messenger_alert and field._portrait.identity == "portrait.poacher"
			and field._portrait.pose == "alert", "Continue shows the authored messenger alert and cinematic cue")
		battle.clock.advance_frame()
		await _capture("messenger-alert", field)
		field.get_node("%Continue").pressed.emit()
		_check(not field._portrait.messenger_alert and field._portrait.identity == "portrait.leader", "Continue advances from the messenger to the Leader")
		field.get_node("%Continue").pressed.emit()
	else:
		field.get_node("%Skip").pressed.emit()
	_check(not battle.clock.dialogue_open and before == [battle.clock.tick, battle.active.size(), battle.defeated, battle.escaped,
		battle.integrity, progress.funds(), resolutions.size()], "Messenger leaves combat counters, clock, Integrity and Funds intact")
	observations.processed = true

func _check_clock(field: CampaignBattle, actor: FirstContactField.Actor) -> void:
	var battle := field.battle
	var tick := battle.clock.tick
	var player: AnimationPlayer = actor.rig.player
	var before := player.current_animation_position
	var duration := player.current_animation_length
	field.get_node("%Pause").pressed.emit()
	var badge: TextureRect = field._pause_overlay.find_child("E03Badge", true, false)
	battle.clock.advance_frame()
	_check(badge != null and battle.clock.tick == tick and before == player.current_animation_position, "Pause freezes E03 and shows its Intel badge")
	field._pause_overlay.find_child("ResumeOperation", true, false).pressed.emit()
	field.get_node("%Speed").pressed.emit()
	battle.clock.advance_frame()
	field.get_node("%Speed").pressed.emit()
	_check(battle.clock.tick == tick + 2 and is_equal_approx(player.current_animation_position,
		fposmod(before + 2.0 * CombatClock.STEP_SECONDS, duration)), "2× samples E03 twice on the existing combat clock")

func _observe_support(field: CampaignBattle, seen: Dictionary) -> void:
	var art := field._board.first_contact_field
	var state := field.battle.deployment
	if not seen.retreat and art.rangers.has(SCOUT):
		field._refresh()
		if field._tip.text.contains("Retreat"):
			var cell := art.rangers[SCOUT].unit.anchor
			_touch(_at(field, cell), true)
			await create_timer(0.4).timeout
			_touch(_at(field, cell), false)
			seen.retreat = field.get_node("%Retreat").visible
	for turret: FirstContactField.Turret in art.turrets.values():
		if not seen.build and turret.clip == &"Construction":
			seen.build = state.build_ticks_left(turret.unit.id) > 0
			await _capture("turret-construction", field)
		seen.ready = seen.ready or turret.clip == &"Ready"
		if not seen.sonic and turret.clip == &"Active":
			seen.sonic = true
			await _capture("turret-attack", field)
	for effect: FirstContactField.Effect in art._effects:
		if effect.name == "treatment" and not seen.heal:
			seen.heal = effect.socket == &"treatment_case" and effect.actor.clip == &"Attack"
			if seen.heal:
				await _capture("medic-healing", field)
			break
	if seen.skill or not art.rangers.has(MEDIC) or not art.rangers.has(PATROL):
		return
	var medic := art.rangers[MEDIC].unit
	var patrol := art.rangers[PATROL].unit
	if medic.skill_charges == 0 or patrol.hp == patrol.spec.max_hp:
		return
	field._refresh()
	var cue := field._tip.text.contains("quick tap") and field._tip.text.contains("Confirm")
	_tap(field, medic.anchor)
	var armed := state.armed == medic.id
	_tap(field, patrol.anchor)
	var was_unspent := medic.skill_charges > 0
	field.get_node("%ConfirmSkill").pressed.emit()
	seen.skill = cue and armed and was_unspent and medic.skill_charges == 0 and art.rangers[MEDIC].clip == &"Skill"

func _terminal_support(app: Control) -> void:
	app.show_story()
	_story_node(app).pressed.emit()
	var plan: OperationPlan = app._screen.plan
	for choice in plan.choices:
		if choice.id == &"facility.medic_cabin":
			plan.select_unit(choice, false)
		elif choice.id == TURRET:
			plan.select_unit(choice, true)
	app._screen._refresh_plan()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	await process_frame
	_skip(field)
	_drop(field, POST, Vector2i(1, 0))
	for tick in 2400:
		field.battle.clock.advance_frame()
	var state := field.battle.deployment
	_drop(field, MEDIC, Vector2i(6, 2))
	_drop(field, TURRET, Vector2i(5, 0))
	var art := field._board.first_contact_field
	var turret_id := state.interaction_id(Vector2i(5, 0))
	var turret: FirstContactField.Turret = art.turrets.get(turret_id)
	var medic: FirstContactField.Actor = art.rangers.get(MEDIC)
	if turret == null or medic == null:
		_check(false, "Damage fixture deployed the Medic and Sonic Turret")
		return
	_check(not state.receive_hit(turret_id, turret.unit.hp, EnemyAttackProfile.Kind.MELEE)
		and turret.clip == &"Construction", "The illustrated Turret retains Siege-only damage rules")
	# Exercise the existing damage entry point in a separate fixture. Story C1-03 has no Siege attackers.
	_check(state.receive_hit(MEDIC, medic.unit.hp, EnemyAttackProfile.Kind.RANGED) and medic.clip == &"Defeat"
		and not state.placed.has(MEDIC), "Accepted terminal Ranger damage drives the Medic defeat pose")
	_check(state.receive_hit(turret_id, turret.unit.hp, EnemyAttackProfile.Kind.SIEGE)
		and turret.clip == &"Destroyed" and state.interaction_id(Vector2i(5, 0)).is_empty(),
		"Accepted Siege destruction drives the Turret ruin and releases both cells")

func _capture(name: String, screen: Control) -> void:
	if _output.is_empty():
		return
	if screen is CampaignBattle:
		screen._refresh()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_output.path_join(name + ".png")) == OK, "Captured " + name)

func _skip(field: CampaignBattle) -> void:
	while field.battle.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()

func _drop(field: CampaignBattle, id: StringName, tile: Vector2i) -> void:
	var controller = field.get_node("%DeploymentController")
	var index: int = controller._entries.find_custom(func(spec: DeploymentSpec) -> bool: return spec.id == id)
	var start: Vector2 = controller._cards[index].get_global_rect().get_center()
	var target := _at(field, tile) - Vector2(8, 0)
	_touch(start, true)
	var drag := InputEventScreenDrag.new()
	drag.position = target
	drag.relative = target - start
	root.push_input(drag, true)
	_touch(target, false)

func _tap(field: CampaignBattle, cell: Vector2i) -> void:
	var point := _at(field, cell)
	_touch(point, true)
	_touch(point, false)

func _at(field: CampaignBattle, cell: Vector2i) -> Vector2:
	return field._board.get_global_transform_with_canvas() * field._board.cell_center(cell)

func _touch(position: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = position
	touch.pressed = pressed
	root.push_input(touch, true)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
