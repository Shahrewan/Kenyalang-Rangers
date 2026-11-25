extends SceneTree

const CHAOS := preload("res://tests/balance/chaos_payout_case.gd")
const PROPOSAL := "res://docs/production/c32/rewards_proposal.json"
const MECHANICAL := HeadquartersCatalog.MECHANICAL
const CONTROL := HeadquartersCatalog.CONTROL
const ECOLOGY := HeadquartersCatalog.ECOLOGY
const OUTREACH := HeadquartersCatalog.OUTREACH
const RECORDS := HeadquartersCatalog.RECORDS
const POST := &"facility.logistics_post"
const FIREBREAK := &"facility.firebreak_beacon"
const SCOUT_CHAPTER := "records_chapter.scout_sniper"
const TIME := 1700000000

var _content := CampaignContent.new()
var _proposal := ProfileFile.read(PROPOSAL)
var _checks := 0
var _failures := 0
var _files: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_validate_data()
	if _failures == 0:
		_campaign_gates()
		_all_perfect()
		_firebreak()
		_legacy_story()
		_legacy_control()
		_records()
		_records_full_receipts()
		_hq_and_activities()
		_chaos_receipts()
	for path in _files:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	print("C32 economy and progression: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _validate_data() -> void:
	_check(_content.error.is_empty() and _content.operations.size() == 15, "All fifteen live operations load")
	_check(_proposal.get("status") == "approved_for_playtest" and _proposal.get("campaign", {}).size() == 15,
		"Approved schedule covers all fifteen missions")
	if _failures > 0:
		return
	var activated := 0
	var first := 0
	var typical_perfect := 0
	var previous := [0, 0, 0]
	for op in _content.operations:
		var id := String(op.stage.stage_id)
		var row: Dictionary = _proposal.campaign.get(id, {})
		var fields := ["first_clear_funds", "first_perfect_funds", "replay_funds"]
		if id == "C2-10":
			fields.append("story_completion_funds")
		_check(row.size() == fields.size() and fields.all(func(key: String) -> bool: return ProfileFile.whole_between(row.get(key), 1, FundsWallet.CAP)),
			id + " has every whole-Funds amount proposed")
		_check(int(row.first_clear_funds) > previous[0] and int(row.first_perfect_funds) > previous[1]
			and int(row.replay_funds) > previous[2] and int(row.replay_funds) < int(row.first_perfect_funds),
			id + " escalates each payout while keeping replay below the one-time bonus")
		previous = [int(row.first_clear_funds), int(row.first_perfect_funds), int(row.replay_funds)]
		for field: String in fields:
			if id == "C1-01" and field == "first_clear_funds":
				_check(op.rewards[field] == 10000 and row[field] == 10000, "Approved First Contact amount stays at 10,000")
			else:
				_check(op.rewards.get(field) == row[field], id + " uses the exact approved " + field)
				activated += 1
		first += int(row.first_clear_funds)
		if id in _proposal.reference_first_perfects:
			typical_perfect += int(row.first_perfect_funds)
	_check(activated == 45 and first + int(_proposal.campaign["C2-10"].story_completion_funds) + typical_perfect == 7420000,
		"The 45 activated amounts keep the GDD partial-perfection scenario at 7.42M")
	var education := EducationCatalog.load_installed()
	var chapter_bonuses := 0
	for id: String in EducationCatalog.CHAPTERS:
		_check(education.chapters.has(id) and education.chapters[id].final_perfect_chapter_funds == _proposal.records_perfect_chapter_funds[id], "Records uses the exact bonus for " + id)
		chapter_bonuses += int(_proposal.records_perfect_chapter_funds[id])
	_check(chapter_bonuses == 350000 and education.first_correct_funds == 30000, "Four active bonuses total 350k, with current first-correct payouts intact")

func _campaign_gates() -> void:
	var profile := _profile("ordinary")
	var starting_rangers := profile.owns(&"ranger.scout_sniper") and profile.owns(&"ranger.patrolman")
	_check(starting_rangers and profile.level_quote(&"ranger.k9_ranger", 20).error.contains("Recruit"), "Fresh ownership and later Ranger recruitment gate")
	_check(profile.level_quote(POST, 20).error.contains("Mechanical"), "Facility upgrade requires the actual Mechanical room")
	var ordinary_clear := 0
	for source in _content.operations:
		if source.min_control_level > profile.room_level(CONTROL):
			var quote := profile.room_quote(CONTROL)
			_check(not profile.access_error(source).is_empty() and quote.error.is_empty(), String(source.stage.stage_id) + " Control gate is affordable from preceding ordinary clears")
			_check(profile.purchase_room(CONTROL).is_empty(), "Buy the required Control tier")
		var plan := OperationPlan.new(source, [])
		plan.configure_campaign(profile)
		_check(plan.can_start(), String(source.stage.stage_id) + " has a legal opening at the current ownership and spend")
		if source.stage.stage_id == &"C1-02":
			var resolved := plan.resolved()
			var state := DeploymentState.new(resolved.stage.map, CombatClock.new(), resolved.tokens, resolved.opening, [], BattleModifiers.new(resolved.stage.modifier_ids))
			var post := DeployableLevels.definition(POST)
			var cell := resolved.stage.map.elevated[0]
			_check(post in plan.choices and state.deploy(post, cell, 1).is_empty() and state.tokens == 0
				and state.build_ticks_left(&"facility.logistics_post#1") == 0, "C1-02 opens with the actual free ordinary 2×1 Post")
		var result := _settle(profile, source, false)
		_check(result.first_clear and not result.first_perfect and result.credited > 0, "Only ordinary first-clear and eligible finale value credit")
		ordinary_clear += int(result.credited)
		for entry in source.clear_unlock_ids:
			_check(profile.owns(entry), "Campaign unlock survives in the same transaction: " + String(entry))
		if source.stage.stage_id == &"C1-01":
			_check(profile.funds() == 20000 and profile.purchase_room(MECHANICAL).is_empty() and profile.funds() == 0,
				"The current approved clear plus the opening wallet pays the 20,000 Mechanical price exactly")
	_check(ordinary_clear == 6600000 and profile.funds() == 5290000 and profile.owns(&"facility.firebreak_beacon"),
		"Zero-perfect path through Control Lv.5 costs 1.32M and recruits the Beacon")
	var before := profile.funds()
	var scout := _content.operation(&"C2-10")
	var replay := _settle(profile, scout, true)
	_check(replay.credited == 274000 and not replay.first_clear and replay.first_perfect
		and not replay.awards.has("story_completion_funds"), "First perfect on a later finale clear credits 265,000 plus replay only")
	_check(_settle(profile, scout, true).credited == 9000 and profile.funds() == before + 283000, "Further perfect replays pay the 9,000 replay award alone")

func _all_perfect() -> void:
	var player := _profile("all-perfect")
	var earned := 0
	var replays := 0
	for operation: StoryOperation in _content.operations:
		while player.room_level(CONTROL) < operation.min_control_level:
			var bought := player.purchase_room(CONTROL).is_empty()
			_check(bought, "Buy the next Control gate from settled rewards")
			if not bought:
				return
		var receipt := _settle(player, operation, true)
		_check(receipt.first_clear and receipt.first_perfect and receipt.pending_awards.is_empty(), "First perfect includes both first awards")
		earned += int(receipt.credited)
		var replay := _settle(player, operation, true)
		_check(replay.awards == {"replay_funds": int(operation.rewards.replay_funds)}, "A further win earns only the approved replay")
		replays += int(replay.credited)
	_check(earned == 8450000 and replays == 64000, "All-perfect first clears total 8.45M and one replay of each adds 64,000")
	var near_cap := player.snapshot()
	near_cap.funds = FundsWallet.CAP - 400
	var clipped := _profile("replay-cap", near_cap)
	var replay := _settle(clipped, _content.operations.back(), true)
	_check(replay.credited == 400 and replay.discarded == 8600 and clipped.funds() == FundsWallet.CAP
		and clipped.complete(_content.operations.back(), true).is_empty(), "Wallet clipping consumes the result exactly once")

func _firebreak() -> void:
	var fixture := CampaignSave.fresh()
	fixture.rooms[String(CONTROL)] = 4
	fixture.rooms[String(MECHANICAL)] = 1
	fixture.funds = 100000
	fixture.records["C2-06"] = {"cleared": true, "perfect": false}
	fixture.records["C2-07"] = {"cleared": true, "perfect": true}
	var path := _seed("returning-firebreak", fixture)
	var profile := CampaignProgress.new(path)
	var stage := _content.operation(&"C2-07")
	_check(not profile.owns(FIREBREAK) and profile.funds() == 100000, "A historical C2-07 perfect stays paid as recorded and ownership awaits a replay")
	_check(profile.begin_attempt(stage) and profile.abandon_attempt() and not profile.owns(FIREBREAK), "Abandoning the replay grants no ownership")
	_check(profile.begin_attempt(stage), "Begin a returning Beacon replay")
	DirAccess.make_dir_absolute(path + ".tmp")
	_check(profile.complete(stage, true).is_empty() and not profile.owns(FIREBREAK) and profile.funds() == 100000,
		"Failed save leaves payout and permanent ownership uncommitted")
	DirAccess.remove_absolute(path + ".tmp")
	profile = CampaignProgress.new(path)
	var receipt := profile.complete(stage, true)
	_check(receipt.get("unlocked") == [FIREBREAK] and receipt.get("credited") == 6500
		and profile.record_for(stage.stage.stage_id).perfect and profile.complete(stage, true).is_empty(),
		"Successful replay awards the Beacon exactly once, pays replay only and preserves the perfect flag")
	_check("C2-07" in HeadquartersRosterPage.lock_message(DeployableLevels.definition(FIREBREAK))
		and profile.purchase_levels(FIREBREAK, 20).is_empty(), "Mechanical routes the recruit to the existing paid level track")
	profile = CampaignProgress.new(path)
	var selection: Array[StringName] = [POST, FIREBREAK, &"ranger.scout_sniper"]
	var plan := OperationPlan.new(stage, [])
	plan.configure_campaign(profile, selection)
	var entries := _beacons(plan)
	_check(entries.size() == 1 and entries[0].level == 1 and entries[0].max_hp == 220 and FIREBREAK not in plan.selected_ids,
		"C2-07 uses one unchanged Lv.1 supply outside the ordinary slots after recruitment")
	var next := _content.operation(&"C2-08")
	plan = OperationPlan.new(next, [])
	plan.configure_campaign(profile, selection)
	_check(_deploy_beacon(plan) and is_equal_approx(next.stage.heat_gain_scale, 0.32),
		"Owned Beacon consumes a regular Story slot with the existing Heat pacing")
	var settings := ChaosConfiguration.new()
	settings.select_route(&"T05")
	settings.set_quantity(0, &"E14", 1)
	var chaos := StoryOperation.new()
	chaos.campaign_spec = true
	chaos.roster = _content.roster
	chaos.stage = settings.build_stage()
	chaos.opening_rules = LogisticsRules.new()
	plan = OperationPlan.new(chaos, [], true)
	plan.configure_campaign(profile, selection)
	_check(_deploy_beacon(plan), "Chaos selects and deploys the same saved Lv.20 Beacon")

func _beacons(plan: OperationPlan) -> Array[DeploymentSpec]:
	return plan.deployment_entries().filter(func(spec: DeploymentSpec) -> bool: return spec.id == FIREBREAK)

func _deploy_beacon(plan: OperationPlan) -> bool:
	var entries := _beacons(plan)
	if not plan.can_start() or entries.size() != 1 or FIREBREAK not in plan.selected_ids or plan.selected_count(false) != 2:
		return false
	var spec := entries[0] as FacilitySpec
	var setup := plan.resolved()
	var clock := CombatClock.new()
	var state := DeploymentState.new(setup.stage.map, clock, setup.tokens, setup.opening)
	for cell: Vector2i in setup.stage.map.elevated:
		if state.deploy(DeployableLevels.definition(POST), cell, 1).is_empty():
			break
	for frame in 4 * LogisticsRules.PAYOUT_TICKS:
		clock.advance_frame()
	for cell: Vector2i in setup.stage.map.elevated:
		if state.deploy(spec, cell, 1).is_empty():
			var unit := state.placed[FIREBREAK]
			return spec.level == 20 and unit.hp == 231 and spec.heat_slow_percent == 42 and unit.paid_cost == 30 \
				and state.build_ticks_left(FIREBREAK) == 360 and state.cooldown_ticks(FIREBREAK) == 2400
	return false

func _legacy_story() -> void:
	var legacy := CampaignSave.fresh()
	legacy.records["C1-01"] = {"cleared": true, "perfect": true}
	var path := _seed("legacy-early", legacy)
	var player := CampaignProgress.new(path)
	var replay := _settle(player, _content.operations[0], true)
	_check(replay.credited == 500 and not replay.first_clear and not replay.first_perfect, "Historical First Contact flags prevent both first awards")
	_check(not player.room_quote(MECHANICAL).error.is_empty(), "Legacy replay Funds still fall short by 9,500")
	player.advance_finance(4750)
	_check(player.finance_stored() == 9500 and player.claim_finance() and player.purchase_room(MECHANICAL).is_empty(),
		"Repeatable Finance plus a successful replay reaches Mechanical with historical flags consumed")
	var no_replay := _profile("legacy-finance", legacy)
	no_replay.advance_finance(5000)
	_check(no_replay.finance_stored() == 10000 and no_replay.claim_finance() and no_replay.purchase_room(MECHANICAL).is_empty(),
		"Current-only Finance reaches the early gate in 5,000 active seconds")
	var late := CampaignSave.fresh()
	late.rooms[String(CONTROL)] = 5
	late.records["C2-09"] = {"cleared": true, "perfect": true}
	late.records["C2-10"] = {"cleared": true, "perfect": false}
	path = _seed("legacy-finale", late)
	player = CampaignProgress.new(path)
	var finale := _content.operation(&"C2-10")
	_check(player.funds() == 10000 and player.record_for(&"C2-10").cleared, "Loading a historical unpaid finale leaves the balance intact")
	player = CampaignProgress.new(path)
	var cash := _settle(player, finale, true)
	_check(cash.credited == 274000 and cash.first_perfect and not cash.first_clear, "Returning finale save may earn a genuinely new perfect")
	_check(_settle(player, finale, true).credited == 9000, "Returning finale save consumes first-clear, completion and perfect only once")
	var before := player.funds()
	_check(player.complete(finale, true).is_empty() and player.funds() == before, "Duplicate settlement callback cannot pay without a new attempt")

func _legacy_control() -> void:
	var data := CampaignSave.fresh()
	data.funds = 0
	data.rooms[String(CONTROL)] = 4
	data.rooms[String(MECHANICAL)] = 1
	data.rooms[String(OUTREACH)] = 3
	for operation in _content.operations.slice(0, 13):
		data.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": true}
		for id: StringName in operation.clear_unlock_ids:
			data.owned.append(String(id))
	var player := _profile("legacy-control", data)
	var next := _content.operation(&"C2-09")
	_check(player.room_quote(CONTROL).shortfall == 900000 and not player.access_error(next).is_empty(),
		"Returning C2-08 clear with no remaining Funds faces the actual Control Lv.5 price")
	var bank := EducationCatalog.load_installed()
	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var outreach := OutreachSession.new(player, bank, rng)
	for visit in 4:
		var now := TIME + visit * CampaignActivities.OUTREACH_INTERVAL
		_check(outreach.refresh(now), "Open the next ordinary Outreach batch")
		var batch := outreach.batch()
		for id: String in batch.batch:
			var authored: int = bank.outreach[id].choices.find_custom(func(choice: Dictionary) -> bool: return choice.grade == "acceptable")
			_check(outreach.submit(id, batch.choice_order[id].find(authored), now).credited == 55000,
				"Repeatable Lv.3 Acceptable response pays real Funds")
	_check(player.funds() == 1100000 and player.purchase_room(CONTROL).is_empty()
		and player.access_error(next).is_empty() and player.funds() == 200000,
		"Four Outreach batches fund Control Lv.5 without paying any previously consumed Story award")
	var plan := OperationPlan.new(next, [])
	plan.configure_campaign(player)
	_check(plan.can_start(), "Returning save has a legal C2-09 opening after the recurring-income path")

func _records() -> void:
	var education := EducationCatalog.load_installed()
	var data := CampaignSave.fresh()
	data.rooms[String(RECORDS)] = 2
	var path := _seed("records", data)
	var old_path := _seed("records-old", data)
	var player := CampaignProgress.new(path)
	var old := CampaignProgress.new(old_path)
	education.chapters[SCOUT_CHAPTER].final_perfect_chapter_funds = null
	_check(_quiz(old, education, false).credited == 0 and SCOUT_CHAPTER in old.snapshot().encyclopaedia.perfect_chapters,
		"Historical unpriced chapter already saves the perfect flag and enhancement")
	var updated_education := EducationCatalog.load_installed()
	var partial := _quiz(player, updated_education, true)
	_check(partial.credited == 0 and player.funds() == 280000 and player.records_enhancements().is_empty(),
		"Nine first correct answers pay 270,000 without a perfect chapter")
	player = CampaignProgress.new(path)
	var complete := _quiz(player, updated_education, false)
	_check(complete.credited == 50000 and player.funds() == 360000 and SCOUT_CHAPTER in player.snapshot().encyclopaedia.perfect_chapters,
		"The tenth first-correct and first perfect bonuses settle independently")
	_check(_quiz(player, updated_education, false).credited == 0 and player.funds() == 360000, "Complete chapter replay duplicates neither award")
	old = CampaignProgress.new(old_path)
	_check(_quiz(old, updated_education, false).credited == 0 and old.funds() == 310000, "Returning perfect flag keeps the formerly unpriced chapter bonus consumed")

func _records_full_receipts() -> void:
	var data := CampaignSave.fresh()
	data.rooms[String(RECORDS)] = 5
	var path := _seed("all-chapters", data)
	var profile := CampaignProgress.new(path)
	var catalog := EducationCatalog.load_installed()
	for id: String in EducationCatalog.CHAPTERS:
		var first := _quiz(profile, catalog, false, id)
		_check(first.first_perfect and first.credited == _proposal.records_perfect_chapter_funds[id], "First perfect settles the installed bonus for " + id)
		profile = CampaignProgress.new(path)
		_check(_quiz(profile, catalog, false, id).credited == 0, "Cold replay cannot duplicate question or chapter Funds for " + id)
	_check(profile.funds() == 1560000 and profile.snapshot().encyclopaedia.first_correct.size() == 40
		and profile.records_enhancements().size() == 4, "All 40 first correct answers and four chapter bonuses total 1.55M")
	var retry_path := _seed("records-write-retry", data)
	profile = CampaignProgress.new(retry_path)
	var quiz := RecordsQuiz.new(profile, catalog)
	_check(quiz.begin(SCOUT_CHAPTER), "Begin an installed chapter for a write-failure case")
	for index in quiz.question_count():
		var question := quiz.question()
		var correct: int = question.choices.find_custom(func(choice: Dictionary) -> bool: return choice.id == question.correct_choice_id)
		_check(quiz.answer(correct), "Persist the correct answer")
		if index + 1 < quiz.question_count():
			_check(quiz.continue_after_feedback(), "Advance to the next question")
	DirAccess.make_dir_absolute(retry_path + ".tmp")
	_check(not quiz.continue_after_feedback() and profile.records_enhancements().is_empty() and profile.funds() == 310000,
		"A failed chapter settlement preserves the committed answers and leaves the bonus available")
	DirAccess.remove_absolute(retry_path + ".tmp")
	_check(quiz.continue_after_feedback() and quiz.result.credited == 50000 and not quiz.continue_after_feedback(),
		"Retry commits the chapter award and enhancement exactly once")

func _quiz(profile: CampaignProgress, catalog: EducationCatalog, miss_last: bool, id := SCOUT_CHAPTER) -> Dictionary:
	var quiz := RecordsQuiz.new(profile, catalog)
	_check(quiz.begin(id), "Actual chapter opens under the owned Records tier")
	for index in quiz.question_count():
		var question := quiz.question()
		var answer: int = question.choices.find_custom(func(choice: Dictionary) -> bool: return choice.id == question.correct_choice_id)
		if miss_last and index == quiz.question_count() - 1:
			answer = (answer + 1) % 4
		_check(quiz.answer(answer) and quiz.continue_after_feedback(), "Each runtime question saves and advances")
	return quiz.result

func _hq_and_activities() -> void:
	var data := CampaignSave.fresh()
	data.funds = FundsWallet.CAP
	data.rooms[String(ECOLOGY)] = 4
	data.rooms[String(OUTREACH)] = 4
	data.rooms[String(MECHANICAL)] = 1
	var profile := _profile("rooms", data)
	_check(profile.room_quote(ECOLOGY).error.contains("60%") and profile.room_quote(OUTREACH).error.contains("5 Best"),
		"Funds alone satisfy neither participation gate")
	for i in 3:
		var species: String = RestorationRules.SPECIES.keys()[i]
		var cycle := profile.plant_garden(i, species, TIME)
		var watered := TIME + RestorationRules.midpoint(species)
		_check(not cycle.is_empty() and profile.water_garden(i, cycle, watered) and not profile.collect_garden(i, cycle, TIME + RestorationRules.duration(species)).is_empty(),
			"Collect a legal mature cycle toward Ecology")
	_check(profile.restoration_percent() == 60 and profile.room_quote(ECOLOGY).cost == 900000
		and profile.purchase_room(ECOLOGY).is_empty(), "Third distinct mature harvest qualifies for paid Ecology Lv.5")
	var bank := EducationCatalog.load_installed()
	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var outreach := OutreachSession.new(profile, bank, rng)
	_check(outreach.refresh(TIME), "Installed bank refreshes through the runtime")
	var batch := outreach.batch()
	for index in 5:
		var id: String = batch.batch[index]
		var authored: int = bank.outreach[id].choices.find_custom(func(choice: Dictionary) -> bool: return choice.grade == "acceptable")
		_check(not outreach.submit(id, batch.choice_order[id].find(authored), TIME).is_empty(), "Acceptable response earns actual participation")
		if index == 3:
			_check(not profile.room_quote(OUTREACH).error.is_empty(), "Four qualifying answers still gate Outreach Lv.5")
	_check(profile.outreach_successes() == 5 and profile.room_quote(OUTREACH).cost == 950000
		and profile.purchase_room(OUTREACH).is_empty(), "Fifth response permits paid Outreach Lv.5")
	var rd_paid := 0
	for room: HeadquartersRoom in CampaignSave.HEADQUARTERS.rooms:
		if room.role != HeadquartersRoom.Role.RESEARCH:
			continue
		for level in range(1, 6):
			var quote := profile.room_quote(room.id)
			_check(quote.target == level and profile.purchase_room(room.id).is_empty(), "Buy R&D tier from the live schedule")
			rd_paid += int(quote.cost)
	var buffs := profile.unlocked_buffs()
	_check(buffs.size() == 15 and ProfileFile.unique_ids(Array(buffs).map(func(id: StringName) -> String: return String(id)))
		and rd_paid == 6700000, "All 15 distinct buffs unlock through the four paid R&D tracks")
	var costs: Array[int] = []
	for room: HeadquartersRoom in CampaignSave.HEADQUARTERS.rooms:
		for level in range(1, 6):
			if room.cost(level) > 0:
				costs.append(room.cost(level))
	_check(costs.size() == 52 and costs.reduce(func(a: int, b: int) -> int: return a + b, 0) == 16160000,
		"52 paid HQ levels sum to 16.16M")
	_check(DeployableLevels.cost(1, 20) == 60096 and DeployableLevels.cost(1, 40) == 191001
		and DeployableLevels.cost(1, 60) == 391287 and DeployableLevels.cost(1, 80) == 660953
		and DeployableLevels.cost(1, 100) == 1000000, "Every deployable follows the GDD milestone prices")
	_check(profile.purchase_levels(&"ranger.scout_sniper", 20).is_empty() and profile.purchase_levels(POST, 20).is_empty(),
		"The two upgrade room routes buy actual Ranger and Facility levels")
	_check(profile.deployable_level(&"ranger.scout_sniper") == 20 and profile.deployable_level(POST) == 20,
		"Purchased levels persist independently")

func _chaos_receipts() -> void:
	var data := CampaignSave.fresh()
	data.rooms[String(MECHANICAL)] = 1
	var profile := _profile("chaos", data)
	var easy := CHAOS.play(profile, _content, [2, 1])
	_check(easy.qualifies and easy.score == 1030 and easy.credited == 41200 and easy.defeated == 3
		and &"facility.skill_relay_station" in easy.unlocked, "Current three-enemy route earns 41,200 and the first threshold exactly once")
	var repeat := CHAOS.play(profile, _content, [2, 1])
	_check(repeat.credited == 41200 and repeat.unlocked.is_empty(), "Repeat earns Funds while the threshold ownership remains one-time")
	var sensitivity := CHAOS.play(_profile("chaos-sensitivity", data), _content, [2, 1], 200)
	_check(sensitivity.qualifies and sensitivity.score == 130 and sensitivity.credited == 2600 and sensitivity.unlocked.is_empty(),
		"Proposed modifier allowance keeps a small reward without granting a threshold")

func _settle(profile: CampaignProgress, operation: StoryOperation, perfect: bool) -> Dictionary:
	_check(profile.begin_attempt(operation), "Open the saved attempt for " + String(operation.stage.stage_id))
	return profile.complete(operation, perfect)

func _seed(name: String, payload: Dictionary) -> String:
	var path := "user://c32-%s-%d.json" % [name, OS.get_process_id()]
	_files.append(path)
	_check(ProfileFile.replace(path, payload, false), "Write disposable " + name + " fixture")
	return path

func _profile(name: String, payload := CampaignSave.fresh()) -> CampaignProgress:
	return CampaignProgress.new(_seed(name, payload))

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", label)
