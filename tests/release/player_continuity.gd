extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const PLANTED := 1700000000
var now := PLANTED
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else ""
	var education := "--education" in args
	var app := LAUNCHER.instantiate()
	# The host runner also isolates the entire user directory for each install path.
	app.save_path = "user://c24-legacy.json"
	app.campaign_save_path = "user://c24-campaign.json"
	app.garden_time = func() -> int: return now
	root.add_child(app)
	app.set_process(false)
	await process_frame
	var profile: CampaignProgress = app._campaign_progress
	if mode == "seed":
		_check(app._route == &"name", "Fresh launch opens Leader naming")
		var input: LineEdit = app._screen.find_child("LeaderName", true, false)
		input.text = "Lina"
		input.text_changed.emit(input.text)
		_press(app, "SaveName")
		_check(app._route == &"menu" and profile.funds() == 10000, "Naming opens the 10,000 Funds profile")
		# Six full Finance claims fund the test through the normal wallet.
		for claim in 6:
			profile.advance_finance(6000.0)
			_check(profile.claim_finance(), "Claim stored active Finance %d" % (claim + 1))
		for id in ["ecology", "outreach", "records", "records"]:
			_open_room(app, id)
			var room: HeadquartersRoomPage = app._screen
			room._purchase.pressed.emit()
			room._dialog.hide()
			room._dialog.confirmed.emit()
		_check(profile.room_level(HeadquartersCatalog.RECORDS) == 2 and profile.funds() == 12000, "Room builds and Records upgrade settle")
		app.show_menu()
		_press(app, "Garden")
		for action in ["Plot1", "ChooseSeed", "Plant_strangler_fig"]:
			_press(app, action)
		_check(profile.garden_state().plots.has("garden_plot.01"), "Growing fig saved from the Garden")
	elif mode == "resume":
		_check(app._route == &"menu" and profile.snapshot().leader_name == "Lina" and profile.funds() == 12000, "Returning process restores Leader and wallet")
		_check(profile.room_level(HeadquartersCatalog.ECOLOGY) == 1 and profile.room_level(HeadquartersCatalog.RECORDS) == 2, "Room purchase and upgrade persist")
		now += 9 * 3600
		_press(app, "Garden")
		_press(app, "Plot1")
		_press(app, "WaterPlot")
		now += 9 * 3600
		app.show_menu()
		_press(app, "Garden")
		_press(app, "Plot1")
		_press(app, "CollectPlot")
		_check(profile.restoration_percent() == 20 and profile.funds() == 65000, "Returning Garden waters and collects a single 53,000 Funds award")
		for id in ["outreach", "records"]:
			_open_room(app, id)
			_press(app, "RoomActivity")
			if id == "outreach":
				if education:
					var choice := app._screen.find_child("OutreachAnswer0", true, false) as Button
					_check(app._screen is OutreachPage and choice != null and not choice.disabled
						and profile.outreach_state().batch.size() == 5, "Returning save opens an installed Outreach batch")
				else:
					_check(app._screen is OutreachPage and _has_text(app._screen, "Outreach questions await an approved bank."), "Installed Outreach reports its approval gate")
			else:
				var chapter: Button = app._screen.find_child("Chapter_scout_sniper", true, false)
				_check(app._screen is RecordsArchivePage and chapter != null and chapter.disabled == (not education),
					"Installed Records follows the player bank and existing Lv.2 room gate")
	elif mode == "verify":
		_check(profile.funds() == 65000 and profile.restoration_percent() == 20 and profile.garden_state().plots.is_empty(), "Second relaunch retains the settled harvest")
		_check(profile.load_status == CampaignProgress.LoadStatus.READY, "Primary profile opens without recovery")
		if education:
			_check(profile.outreach_state().batch.size() == 5, "Second relaunch keeps the installed Outreach rotation")
	else:
		_check(false, "Use seed, resume or verify from the package checker")
	if "--facility-growth" in args:
		_verify_facility_upgrade(mode)
	if "--ranger-growth" in args:
		_verify_ranger_upgrade(mode)
	if "--economy-rewards" in args:
		_verify_economy_rewards(mode, "--legacy-economy" in args)
	if "--chaos-cap" in args:
		_verify_chaos_cap(mode, "--legacy-chaos" in args)
	app.free()
	await process_frame
	quit(1 if failures else 0)

func _verify_facility_upgrade(mode: String) -> void:
	const PATH := "user://c32-b-update-level.json"
	const POST := &"facility.logistics_post"
	if mode == "seed":
		var fixture := CampaignSave.fresh()
		fixture.leader_name = "Rimba"
		fixture.funds = 300_000
		_check(ProfileFile.replace(PATH, fixture, false), "Prepare a funded upgrade profile")
		var profile := CampaignProgress.new(PATH)
		_check(profile.purchase_room(HeadquartersCatalog.MECHANICAL).is_empty()
			and profile.purchase_levels(POST, 20).is_empty() and profile.funds() == 219_904,
			"Seed pack purchases Mechanical and Level 20 Logistics Post")
		return
	var returning := CampaignProgress.new(PATH)
	var level := 20 if mode == "resume" else 40
	var spec := DeployableLevels.effective(DeployableLevels.definition(POST), returning.deployable_level(POST))
	_check(returning.load_status == CampaignProgress.LoadStatus.READY and spec.level == level
		and spec.max_hp == (168 if level == 20 else 176)
		and returning.funds() == (219_904 if level == 20 else 88_999),
		"Returning profile retains the paid level and gets scaled Logistics Post HP")
	if mode == "resume":
		_check(returning.purchase_levels(POST, 40).is_empty(), "Updated pack continues the same upgrade track")

func _verify_ranger_upgrade(mode: String) -> void:
	const PATH := "user://c32-c-ranger-level.json"
	const SCOUT := &"ranger.scout_sniper"
	if mode == "seed":
		var fixture := CampaignSave.fresh()
		fixture.leader_name = "Rimba"
		fixture.funds = 300_000
		_check(ProfileFile.replace(PATH, fixture, false), "Prepare a funded Ranger upgrade profile")
		var profile := CampaignProgress.new(PATH)
		_check(profile.purchase_levels(SCOUT, 20).is_empty() and profile.funds() == 239_904,
			"Seed pack purchases Level 20 Scout Sniper")
		return
	var returning := CampaignProgress.new(PATH)
	var level := 20 if mode == "resume" else 40
	var spec := DeployableLevels.effective(DeployableLevels.definition(SCOUT), returning.deployable_level(SCOUT)) as RangerSpec
	_check(returning.load_status == CampaignProgress.LoadStatus.READY and spec.level == level
		and spec.max_hp == (105 if level == 20 else 110) and spec.attack_damage == (25 if level == 20 else 26)
		and spec.active_skill.damage == spec.attack_damage and returning.records_enhancements().is_empty()
		and returning.funds() == (239_904 if level == 20 else 108_999),
		"Returning profile retains the paid Ranger level with scaled outputs and the original Records gate")
	if mode == "resume":
		_check(returning.purchase_levels(SCOUT, 40).is_empty(), "Updated pack continues the same Ranger upgrade track")

func _verify_economy_rewards(mode: String, legacy: bool) -> void:
	const PATH := "user://c32-d-awards.json"
	const FIREBREAK := &"facility.firebreak_beacon"
	const CHAPTER := &"records_chapter.scout_sniper"
	var stage := CampaignContent.new().operation(&"C2-07")
	var expected := 310_000 if legacy else 1_160_000
	if mode == "seed":
		var fixture := CampaignSave.fresh()
		fixture.leader_name = "Rimba"
		fixture.rooms[String(HeadquartersCatalog.CONTROL)] = 4
		fixture.rooms[String(HeadquartersCatalog.RECORDS)] = 2
		fixture.rooms[String(HeadquartersCatalog.MECHANICAL)] = 1
		fixture.records["C2-06"] = {"cleared": true, "perfect": false}
		_check(ProfileFile.replace(PATH, fixture, false), "Seed a save with authored prerequisites")
		var profile := CampaignProgress.new(PATH)
		_check(profile.begin_attempt(stage), "Open the unlocked C2-07 attempt")
		var first := profile.complete(stage, true)
		_check(first.get("credited") == (0 if legacy else 800000), "Source APK settles its own Campaign award data")
		var chapter := _perfect_chapter(profile, CHAPTER)
		_check(chapter.get("credited") == (0 if legacy else 50000) and profile.funds() == expected,
			"Source APK persists question, chapter and Campaign flags with the exact balance")
		return
	var returning := CampaignProgress.new(PATH)
	if mode == "resume":
		var record := returning.record_for(&"C2-07")
		_check(returning.funds() == expected and record.get("perfect", false) and returning.owns(FIREBREAK) == (not legacy),
			"Loading preserves historical milestones and wallet")
		_check(_perfect_chapter(returning, CHAPTER).get("credited") == 0 and returning.funds() == expected,
			"Repeating a historical perfect chapter pays neither question nor chapter awards")
		_check(returning.begin_attempt(stage), "Open the replay with the new pack")
		var replay := returning.complete(stage, true)
		_check(replay.get("awards") == {"replay_funds": 6500} and replay.get("unlocked") == ([FIREBREAK] if legacy else []),
			"Successful replay pays 6,500 and recruits only a previously missing Beacon")
		_check(returning.purchase_levels(FIREBREAK, 20).is_empty(), "Returning player purchases the permanent Beacon milestone")
	else:
		_check(returning.funds() == expected + 6500 - 60096 and returning.deployable_level(FIREBREAK) == 20
			and returning.owns(FIREBREAK) and StringName(CHAPTER) in returning.records_enhancements(),
			"Cold start verifies the exact paid level, ownership, Records flag and Funds")

func _perfect_chapter(profile: CampaignProgress, chapter: StringName) -> Dictionary:
	var quiz := RecordsQuiz.new(profile, EducationCatalog.load_installed())
	if not quiz.begin(chapter):
		return {}
	for index in quiz.question_count():
		var question := quiz.question()
		var correct: int = question.choices.find_custom(func(choice: Dictionary) -> bool: return choice.id == question.correct_choice_id)
		if not quiz.answer(correct) or not quiz.continue_after_feedback():
			return {}
	return quiz.result

func _verify_chaos_cap(mode: String, legacy: bool) -> void:
	const PATH := "user://c32-e-chaos-cutover.json"
	const PATROL := &"ranger.patrolman"
	const POST := &"facility.logistics_post"
	const RELAY := &"facility.skill_relay_station"
	const DEBUFFS: Array[StringName] = [&"D02", &"D03", &"D05", &"D07", &"D08", &"D12", &"D13", &"D15"]
	if mode == "seed":
		var fixture := CampaignSave.fresh()
		fixture.leader_name = "Rimba"
		fixture.rooms[String(HeadquartersCatalog.MECHANICAL)] = 1
		_check(ProfileFile.replace(PATH, fixture, false), "Prepare an independent Chaos profile with Mechanical")
	var profile := CampaignProgress.new(PATH)
	var expected_best := 1030 if legacy else 130
	var after_seed := 51200 if legacy else 12600
	var expected_tiers := ["chaos_tier.1000"] if legacy else []
	if mode == "verify":
		_check(profile.funds() == after_seed + 2600 and profile.chaos_personal_best() == expected_best
			and profile.owns(RELAY) == legacy and profile.snapshot().chaos.earned_thresholds == expected_tiers
			and profile.pending_chaos_configuration().is_empty(), "Cold launch preserves the capped replay plus all previously earned trophies")
		return
	if mode == "resume":
		_check(profile.funds() == after_seed and profile.chaos_personal_best() == expected_best
			and profile.owns(RELAY) == legacy and profile.snapshot().chaos.earned_thresholds == expected_tiers,
			"Update retains the exact earned best, trophy, Facility and wallet")
	var config := ChaosConfiguration.new()
	config.select_route(&"T01")
	config.set_quantity(0, &"E01", 2)
	config.set_quantity(1, &"E01", 1)
	var setup := ModifierSetup.new()
	setup.chaos = true
	setup.stage = config.build_stage()
	setup.loadout = [DeployableLevels.definition(PATROL), DeployableLevels.definition(POST)]
	var resolution := setup.resolve([], DEBUFFS)
	var run := profile.begin_chaos(config, resolution, [PATROL, POST], DEBUFFS)
	var old_scoring := legacy and mode == "seed"
	if run == null:
		_check(false, "The source package resolves the Chaos setup")
		return
	_check(run.score.points() == (1030 if old_scoring else 130), "The package uses its own effective score")
	var battle := BattleSimulation.new(resolution.stage)
	battle.deployment = DeploymentState.new(resolution.stage.map, battle.clock, resolution.tokens, resolution.opening, [], battle.effects)
	var patrol := resolution.entries[0]
	_check(patrol.id == PATROL and battle.deployment.deploy(patrol, Vector2i(2, 1), -1).is_empty(), "Use the effective Ranger and ordinary placement rules")
	for frame in 10000:
		if battle.clock.stopped:
			break
		battle.clock.advance_frame()
	_check(run.record_outcome(battle) and run.qualifies(), "Real combat earns a qualifying victory")
	var receipt := profile.settle_chaos(run)
	_check(receipt.get("credited") == (41200 if old_scoring else 2600)
		and profile.owns(RELAY) == legacy and profile.chaos_personal_best() == expected_best,
		"The receipt uses the package formula and preserves previously earned ownership")

func _open_room(app: Control, id: String) -> void:
	app.show_menu()
	_press(app, "OpenHeadquarters")
	_press(app, "Room_" + id)

func _press(app: Control, id: String) -> void:
	var button: Button = app._screen.find_child(id, true, false)
	if button == null or button.disabled:
		_check(false, "Expected available action " + id)
		return
	button.pressed.emit()

func _has_text(page: Control, fragment: String) -> bool:
	for label: Label in page.find_children("*", "Label", true, false):
		if fragment in label.text:
			return true
	return false

func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		failures += 1
		push_error(message)
