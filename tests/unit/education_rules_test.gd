extends SceneTree

const Fixture := preload("res://tests/fixtures/education/banks.gd")
const SCOUT := "records_chapter.scout_sniper"
const PATROL := "records_chapter.patrolman"
const MEDIC := "records_chapter.combat_medic"
const WOODS := "records_chapter.woods_tracker"
const TRIAL := preload("res://data/stages/c16_modifier_trial.tres")
var _checks := 0
var _failed := 0
var _paths: Array[String] = []

func _initialize() -> void:
	_bank_gate()
	_outreach()
	_participation()
	_records()
	_enhancements()
	for path in _paths:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	print("Education rules: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _bank_gate() -> void:
	for directory in ["res://tests/missing-education-banks", "res://docs/production/w18"]:
		var unapproved := EducationCatalog.load_installed(directory)
		_check(unapproved.outreach.is_empty() and unapproved.chapters.is_empty() and unapproved.facts.is_empty(), "%s serves no unapproved player copy" % directory)
	var catalog := Fixture.catalog()
	_check(catalog.outreach.size() == 20 and catalog.chapters.size() == 4 and catalog.facts.has(Fixture.FACT), "Validated synthetic payload opens all three approved-format collections")
	var data := Fixture.payload()
	var directory := "user://c19-banks-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(directory)
	var written := true
	for bank: String in data:
		written = ProfileFile.replace(directory.path_join(bank + ".json"), data[bank], false) and written
	var installed := EducationCatalog.load_installed(directory)
	_check(written and installed.outreach_revision == 1 and installed.records_revision == 1 and installed.first_correct_funds == 30000, "The installed-file loader reads approved-format JSON and its configured awards")
	for bank: String in data:
		DirAccess.remove_absolute(directory.path_join(bank + ".json"))
	DirAccess.remove_absolute(directory)
	data.outreach.editorial_status = "draft_source_checked"
	_check(EducationCatalog.from_banks(data.outreach, data.records, data.references).outreach.is_empty(), "Draft questions are refused even with an approved reference register")
	data = Fixture.payload()
	data.outreach.questions[0].choices[0].grade = "harmful"
	_check(EducationCatalog.from_banks(data.outreach, data.records, data.references).outreach.is_empty(), "Each Outreach prompt needs one of every grade")
	data = Fixture.payload()
	data.records.chapters[0].questions[0].correct_choice_id = "missing"
	_check(EducationCatalog.from_banks(data.outreach, data.records, data.references).chapters.is_empty(), "A malformed answer key disables the Records bank")
	data = Fixture.payload()
	data.records.chapters[1].final_perfect_chapter_funds = null
	_check(EducationCatalog.from_banks(data.outreach, data.records, data.references).chapters.is_empty(), "Unresolved awards are never guessed")
	data = Fixture.payload()
	data.references.facts[0].source_ids = ["source.absent"]
	_check(EducationCatalog.from_banks(data.outreach, data.records, data.references).facts.is_empty(), "An unresolved citation prevents the invalid reference package loading")

func _outreach() -> void:
	var path := _profile("pr", 2200, 1, 0)
	var progress := CampaignProgress.new(path)
	var catalog := Fixture.catalog()
	var rng := RandomNumberGenerator.new()
	rng.seed = 717
	var session := OutreachSession.new(progress, catalog, rng)
	var now := 200000
	var interval := CampaignActivities.OUTREACH_INTERVAL
	_check(session.refresh(now), "Opening Outreach commits the first batch")
	var state := session.batch()
	_check(state.rotation.size() == 20 and state.batch.size() == 5 and state.choice_order.size() == 5 and state.bank_revision == 1, "The first batch saves its rotation, five shuffled choices and bank revision")
	var loss := _grade(session, 0, 3)
	_check(loss.get("deducted", -1) == 2200 and progress.funds() == 0, "Harmful applies the lesser of its loss and held Funds")
	var id: String = state.batch[0]
	_check(session.batch().responses[id].grade == "harmful" and session.batch().responses[id].choice == 3, "The shuffled tapped choice resolves to its authored grade and index")
	_check(_grade(session, 0, 0).is_empty() and progress.funds() == 0, "An answered prompt cannot settle twice")
	_check(_grade(session, 1, 0).get("credited", -1) == 25000 and _grade(session, 2, 1).get("credited", -1) == 12500, "Best and Acceptable use the sourced Lv.1 table")
	_check(_grade(session, 3, 2).get("credited", -1) == 0 and progress.outreach_successes() == 2, "Only Best and Acceptable count toward the participation gate")
	var restart := OutreachSession.new(CampaignProgress.new(path), catalog, rng)
	var reloaded := restart.batch()
	var persisted := session.batch()
	_check(_same_batch(reloaded, persisted), "Rotation, choices, replies and actual settlement survive reload")
	_check(restart.refresh(now - 900) and restart.batch().batch == state.batch and restart.seconds_until_refresh(now - 900) == interval + 900, "A clock rollback keeps the original eligibility date")
	_check(restart.refresh(now + interval - 1) and restart.seconds_until_refresh(now + interval - 1) == 1 and restart.batch().batch == state.batch, "One second before the boundary preserves the batch")
	_check(restart.submit(String(state.batch[4]), 0, now + interval).is_empty(), "An expired prompt cannot settle before the player opens the new batch")
	var seen: Array = state.batch.duplicate()
	for offset in range(1, 4):
		_check(restart.refresh(now + interval * offset), "An eligible visit opens batch %d" % (offset + 1))
		seen.append_array(restart.batch().batch)
	_check(seen == state.rotation and ProfileFile.unique_ids(seen), "Four batches consume the whole 20-question rotation once")
	var far_future := now + interval * 20
	_check(restart.refresh(far_future) and restart.batch().refreshed_at == far_future and restart.batch().responses.is_empty(), "A large forward jump opens one batch with a new anchor")
	var refreshed := restart.batch()
	_check(restart.refresh(far_future) and restart.batch() == refreshed and restart.seconds_until_refresh(far_future) == interval, "Opening twice at the same time produces no catch-up batch")
	var revised := Fixture.payload()
	revised.outreach.content_revision = 2
	var revised_catalog := EducationCatalog.from_banks(revised.outreach, revised.records, revised.references)
	restart = OutreachSession.new(CampaignProgress.new(path), revised_catalog, rng)
	_check(restart.refresh(far_future) and not restart.matches_bank(restart.batch()) and restart.submit(String(refreshed.batch[0]), 0, far_future).is_empty(), "A revised bank keeps the old deadline and never grades an obsolete choice index")
	_check(restart.refresh(far_future + interval) and restart.batch().bank_revision == 2, "The new approved revision starts at the next eligible boundary")

func _participation() -> void:
	var path := _profile("gate", FundsWallet.CAP - 20, 4, 0)
	var progress := CampaignProgress.new(path)
	var session := OutreachSession.new(progress, Fixture.catalog())
	session.refresh(200000)
	var result := _grade(session, 0, 0)
	_check(result.get("credited") == 20 and result.get("discarded") == 179980, "Outreach reports the actual credit and discarded Lv.4 overflow")
	for i in range(1, 4):
		_grade(session, i, 1)
	_check(not progress.room_quote(HeadquartersCatalog.OUTREACH).error.is_empty(), "Four qualifying responses still block the Lv.5 purchase")
	_grade(session, 4, 1)
	_check(progress.outreach_successes() == 5 and progress.purchase_room(HeadquartersCatalog.OUTREACH).is_empty(), "The fifth success and sufficient Funds unlock the real Lv.5 purchase")

func _records() -> void:
	var path := _profile("quiz", 10000, 0, 2)
	var progress := CampaignProgress.new(path)
	var catalog := Fixture.catalog()
	var quiz := RecordsQuiz.new(progress, catalog)
	_check(not quiz.begin(WOODS) and quiz.begin(SCOUT) and quiz.seconds_left() == 15, "Records Lv.2 opens only the first 15-second chapter")
	_check(not quiz.begin(SCOUT), "An active quiz cannot silently reset its own clock")
	quiz.advance(4.25)
	quiz.pause()
	quiz.advance(20.0)
	_check(quiz.time_left_ticks == 645 and progress.quiz_attempt().time_left_ticks == 645, "Pause freezes and checkpoints the exact live countdown")
	progress = CampaignProgress.new(path)
	quiz = RecordsQuiz.new(progress, catalog)
	_check(quiz.can_resume() and quiz.paused and quiz.time_left_ticks == 645, "A cold reopen offers the same paused question")
	_check(not quiz.answer(2), "A paused question cannot accept an answer")
	quiz.resume()
	quiz.advance(10.75)
	_check(quiz.reviewing() and quiz.feedback().choice == -1 and not quiz.feedback().correct and progress.funds() == 10000, "The exact deadline settles a timeout and explanation with zero credit")
	_check(not quiz.answer(2), "Timeout feedback cannot accept a late tap")
	_check(quiz.continue_after_feedback() and quiz.question_number() == 2 and quiz.time_left_ticks == 900, "Feedback confirmation resets only the next question clock")
	_check(quiz.answer(2) and quiz.feedback().credited == 30000 and progress.funds() == 40000, "The first correct answer credits once and stores its review")
	progress = CampaignProgress.new(path)
	quiz = RecordsQuiz.new(progress, catalog)
	_check(quiz.reviewing() and quiz.question_number() == 2 and quiz.feedback().credited == 30000, "A cold reopen after settlement restores the same feedback")
	_check(quiz.continue_after_feedback() and quiz.result.correct == 1 and quiz.result.credited == 0 and progress.records_enhancements().is_empty(), "A timeout prevents a perfect award")

	quiz = RecordsQuiz.new(progress, catalog)
	quiz.begin(SCOUT)
	_check(quiz.answer(2) and quiz.feedback().credited == 30000, "A question missed before can still earn its first correct payout")
	quiz.continue_after_feedback()
	_check(quiz.answer(2) and quiz.feedback().credited == 0, "A previously paid question still counts as correct without another credit")
	_check(quiz.continue_after_feedback() and quiz.result.first_perfect and quiz.result.credited == 70000 and StringName(SCOUT) in progress.records_enhancements(), "A first perfect attempt awards the chapter and Scout enhancement")
	_check(progress.snapshot().encyclopaedia.discovered_facts == [Fixture.FACT], "Correct answers record a cited fact only once")
	quiz = RecordsQuiz.new(progress, catalog)
	quiz.begin(SCOUT)
	_perfect(quiz)
	_check(quiz.result.correct == 2 and not quiz.result.first_perfect and quiz.result.credited == 0 and progress.funds() == 140000, "A second perfect attempt cannot farm question or chapter rewards")
	progress = CampaignProgress.new(path)
	_check(progress.quiz_attempt().is_empty() and progress.records_enhancements() == [StringName(SCOUT)] and progress.snapshot().encyclopaedia.first_correct.size() == 2, "Question rewards and a completed perfect chapter persist")

	var full := CampaignProgress.new(_profile("full_records", 10000, 0, 5))
	for id in [SCOUT, PATROL, MEDIC, WOODS]:
		quiz = RecordsQuiz.new(full, catalog)
		_check(quiz.begin(id), "The unlocked chapter %s starts" % id)
		_perfect(quiz)
		_check(StringName(id) in full.records_enhancements(), "%s grants its own named enhancement" % id)
	var strike := DeployableLevels.definition(&"ranger.strike_team") as RangerSpec
	_check(full.records_enhancements().size() == 4 and strike.records_enhancement.is_empty(), "Exactly four Rangers receive Records enhancements")

func _enhancements() -> void:
	var stage := TRIAL.duplicate() as BattleStage
	stage.opening_delay_seconds = 0.0
	var battle := BattleSimulation.new(stage)
	var state := DeploymentState.new(stage.map, battle.clock, 100, null, [StringName(PATROL), StringName(MEDIC)])
	battle.deployment = state
	var patrol := DeployableLevels.definition(&"ranger.patrolman") as RangerSpec
	var medic := DeployableLevels.definition(&"ranger.combat_medic") as RangerSpec
	state.deploy(patrol, Vector2i(1, 1), -1)
	state.deploy(medic, Vector2i(1, 0), -1)
	battle.clock.advance_frame()
	var ranger := state.placed[patrol.id]
	var enemy := battle.active[1]
	var hp := enemy.hp
	ranger.next_attack_tick = 0
	enemy.blocked_by = &""
	battle.ranger_combat.basic_attack(ranger, state, battle.clock.tick, 90)
	_check(hp - enemy.hp == 12, "Reinforced Patrol leaves ordinary attacks and block slots at base stats")
	hp = enemy.hp
	enemy.blocked_by = patrol.id
	ranger.next_attack_tick = 0
	battle.ranger_combat.basic_attack(ranger, state, battle.clock.tick, 90)
	_check(hp - enemy.hp == 18 and ranger.spec.block_capacity == 2, "Reinforced Patrol adds six HP only against its aggressor")

	ranger.hp = 150
	ranger.jammed_until = 200
	ranger.entangled_until = 200
	ranger.knocked_down_until = 200
	ranger.attack_slow_until = 200
	_check(battle.tap_unit(medic.id) and state.select_target(ranger.anchor) and battle.confirm_skill_target(), "Unlocked Emergency Treatment takes an explicitly confirmed ally target")
	_check(ranger.hp == 215 and ranger.can_act(battle.clock.tick) and ranger.jammed_until == 0 and ranger.attack_slow_until == 0, "The proposed kit restores 65 HP and cleanses current statuses")
	_check(not battle.tap_unit(medic.id) and state.placed[medic.id].skill_recharge_tick == 0, "The treatment kit is spent once per deployment")
	var woods := DeployableLevels.definition(&"ranger.woods_tracker").duplicate() as RangerSpec
	woods.records_bonus_hp = 10
	woods.records_redeploy_reduction_seconds = 1.0
	var enhanced := DeployableLevels.with_records_stats(woods, [StringName(WOODS)])
	_check(enhanced.max_hp == woods.max_hp + 10 and enhanced.redeploy_seconds == woods.redeploy_seconds - 1.0 and DeployableLevels.with_records_stats(woods, []) == woods, "Authored Records HP and redeploy tuning only applies to the named Ranger")

func _profile(name: String, funds: int, outreach: int, records: int) -> String:
	var path := "user://c19-%d-%s.json" % [OS.get_process_id(), name]
	_paths.append(path)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Fixture"
	profile.funds = funds
	profile.rooms[String(HeadquartersCatalog.OUTREACH)] = outreach
	profile.rooms[String(HeadquartersCatalog.RECORDS)] = records
	ProfileFile.replace(path, profile, false)
	return path

func _grade(session: OutreachSession, index: int, authored: int) -> Dictionary:
	var state := session.batch()
	var id: String = state.batch[index]
	return session.submit(id, state.choice_order[id].find(authored), int(state.refreshed_at))

func _same_batch(loaded: Dictionary, saved: Dictionary) -> bool:
	if loaded.rotation != saved.rotation or loaded.batch != saved.batch or int(loaded.refreshed_at) != int(saved.refreshed_at):
		return false
	for id: String in saved.batch:
		if PackedInt32Array(loaded.choice_order[id]) != PackedInt32Array(saved.choice_order[id]):
			return false
		var reply: Dictionary = loaded.responses.get(id, {})
		var original: Dictionary = saved.responses.get(id, {})
		if reply.get("grade") != original.get("grade") or int(reply.get("choice", 0)) != int(original.get("choice", 0)) or int(reply.get("change", 0)) != int(original.get("change", 0)):
			return false
	return true

func _perfect(quiz: RecordsQuiz) -> void:
	for number in 2:
		quiz.answer(2)
		quiz.continue_after_feedback()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
