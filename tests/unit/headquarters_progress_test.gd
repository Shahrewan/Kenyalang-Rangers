extends SceneTree

const HQ := CampaignProgress.HEADQUARTERS
const ROOM_PRICES := [
	[0, 20000, 80000, 300000, 900000], [0, 25000, 110000, 350000, 1000000],
	[0, 15000, 75000, 250000, 750000], [20000, 25000, 110000, 350000, 1000000],
	[20000, 20000, 90000, 300000, 900000], [15000, 20000, 100000, 330000, 950000],
	[15000, 20000, 100000, 300000, 900000], [25000, 25000, 120000, 360000, 1050000],
	[25000, 25000, 120000, 360000, 1050000], [25000, 25000, 120000, 360000, 1050000],
	[30000, 30000, 150000, 450000, 1300000],
]

var _prefix := "user://c15-economy-%d" % OS.get_process_id()
var _paths: Array[String]
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_room_catalog()
	_economy()
	_all_rooms()
	_leveling()
	_activities()
	_migration_and_recovery()
	for path in _paths:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".reset", ".reset.tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	print("Headquarters progression: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _room_catalog() -> void:
	var total := 0
	var free := 0
	_check(HQ.rooms.size() == ROOM_PRICES.size(), "The complete HQ has eleven rooms")
	for i in HQ.rooms.size():
		var room: HeadquartersRoom = HQ.rooms[i]
		_check(Array(room.costs) == ROOM_PRICES[i], "%s has all five exact GDD prices" % room.label)
		for price in room.costs:
			total += price
		if room.starts_built():
			free += 1
	_check(free == 3 and total == 16160000, "Three free rooms and a 16,160,000 Funds maximum")
	_check(Array(HQ.room(HeadquartersCatalog.HR).capacities) == [3, 4, 5, 6, 8], "HR slots follow the five GDD tiers")
	_check(Array(HQ.room(HeadquartersCatalog.MECHANICAL).capacities) == [2, 3, 4, 5, 6], "Mechanical slots follow the five GDD tiers")
	_check(Array(HQ.room(HeadquartersCatalog.ECOLOGY).capacities) == [2, 3, 4, 5, 6], "Ecology locks extra plots to room level")
	var finance: HeadquartersRoom = HQ.room(HeadquartersCatalog.FINANCE)
	_check(Array(finance.income_rates) == [2, 4, 7, 10, 15] and Array(finance.storage_limits) == [12000, 25000, 50000, 90000, 160000], "Finance uses the exact rates and storage capacities")

func _economy() -> void:
	var path := _path("wallet")
	var profile := CampaignProgress.new(path)
	_check(profile.load_status == CampaignProgress.LoadStatus.NEW and profile.funds() == 10000, "A clean profile has the trial starting wallet")
	_check(profile.room_level(HeadquartersCatalog.CONTROL) == 1 and profile.room_capacity(HeadquartersCatalog.HR) == 3 and profile.finance_rate() == 2, "Control, HR and Finance start active")
	_check(profile.room_capacity(HeadquartersCatalog.MECHANICAL) == 0 and profile.room_capacity(HeadquartersCatalog.ECOLOGY) == 0, "Unbuilt rooms grant zero capacity")
	_check(profile.room_quote(HeadquartersCatalog.MECHANICAL).shortfall == 10000 and not profile.purchase_room(HeadquartersCatalog.MECHANICAL).is_empty() and profile.funds() == 10000, "Unaffordable construction preserves the wallet")
	_check(not profile.level_quote(&"ranger.strike_team", 2).error.is_empty(), "Unrecruited Rangers cannot buy levels")
	_check(not profile.level_quote(&"facility.logistics_post", 2).error.is_empty(), "An owned Facility still requires Mechanical to upgrade")
	_check(not profile.level_quote(&"ranger.scout_sniper", 101).error.is_empty() and not profile.level_quote(&"ranger.scout_sniper", 1).error.is_empty(), "Out-of-range and same-level purchases are rejected")
	profile.advance_finance(5000.25)
	_check(profile.finance_stored() == 10000 and profile.claim_finance() and is_equal_approx(profile.snapshot().finance, 0.5), "Claim preserves fractional Finance production")
	_check(profile.purchase_room(HeadquartersCatalog.MECHANICAL).is_empty() and profile.funds() == 0 and profile.room_capacity(HeadquartersCatalog.MECHANICAL) == 2, "A funded 20,000 purchase builds Mechanical immediately")
	profile.advance_finance(1000000.0)
	_check(profile.finance_stored() == 12000, "Active production clamps to the separate Finance storage cap")
	profile.flush_finance()
	var loaded := CampaignProgress.new(path)
	_check(loaded.funds() == 0 and loaded.finance_stored() == 12000 and loaded.room_capacity(HeadquartersCatalog.MECHANICAL) == 2, "Cash, stored Funds and room purchases survive reload")

	path = _path("overflow")
	profile = _funded(path, 9990000)
	profile.purchase_room(HeadquartersCatalog.FINANCE)
	# Use the storyboard amount against its exact held-balance fixture.
	var quote := FundsWallet.quote(9990000, 54000)
	_check(quote.credited == 9999 and quote.discarded == 44001 and quote.balance == FundsWallet.CAP, "Wallet arithmetic matches S58's 54,000 Funds overflow")
	profile.advance_finance(8000.0)
	var claim := profile.finance_preview()
	_check(profile.finance_stored() == 25000 and claim.credited == 24999 and claim.discarded == 1, "Upgraded Finance previews both credit and discard")
	_check(profile.claim_finance() and profile.funds() == FundsWallet.CAP and profile.finance_stored() == 0, "An overflow claim permanently empties its approved storage amount")
	var operation := CampaignContent.new().operation(&"C1-01").duplicate() as StoryOperation
	operation.rewards = {"first_clear_funds": FundsWallet.CAP + 1, "first_perfect_funds": 0, "replay_funds": 0}
	profile.begin_attempt(operation)
	var settled := profile.complete(operation, true)
	_check(settled.credited == 0 and settled.discarded == FundsWallet.CAP + 1 and profile.record_for(&"C1-01").perfect, "A stage grant above cap settles its one-time flag and reports the discarded Funds")

func _all_rooms() -> void:
	var path := _path("rooms")
	var profile := _funded(path, FundsWallet.CAP)
	var total := 0
	for room: HeadquartersRoom in HQ.rooms:
		for target in range(profile.room_level(room.id) + 1, HeadquartersCatalog.MAX_LEVEL + 1):
			var price := room.cost(target)
			_top_up(profile, price)
			if room.gate != HeadquartersRoom.Gate.NONE and target == room.gate_level:
				_check(not profile.room_quote(room.id).error.is_empty() and not profile.purchase_room(room.id).is_empty(), "%s Lv.5 requires participation with enough Funds" % room.label)
				if room.gate == HeadquartersRoom.Gate.RESTORATION:
					for species: String in RestorationRules.SPECIES.keys().slice(0, 3):
						var cycle := profile.plant_garden(0, species, 400000)
						profile.water_garden(0, cycle, 400000 + RestorationRules.midpoint(species))
						profile.collect_garden(0, cycle, 400000 + RestorationRules.duration(species))
					_check(profile.restoration_percent() == 60, "Three distinct mature species reach the Ecology gate")
				else:
					_outreach_batch(profile, 90000)
					for question: String in profile.snapshot().outreach.batch:
						profile.record_outreach_response(question, 0, &"acceptable")
					_check(profile.outreach_successes() == 5, "Five submitted Best or Acceptable responses qualify")
			var balance := profile.funds()
			var error := profile.purchase_room(room.id)
			_check(error.is_empty() and profile.room_level(room.id) == target and profile.funds() == balance - price, "%s becomes Lv.%d and deducts the exact price" % [room.label, target])
			total += price
	_check(total == 16160000, "Actual transactions spend exactly 16,160,000 on every room")
	profile = CampaignProgress.new(path)
	_check(profile.room_capacity(HeadquartersCatalog.HR) == 8 and profile.room_capacity(HeadquartersCatalog.MECHANICAL) == 6 and profile.room_capacity(HeadquartersCatalog.ECOLOGY) == 6, "Maximum capacities persist across a cold load")
	_check(profile.records_chapters().size() == 4 and profile.unlocked_buffs().size() == 15 and &"B15" in profile.unlocked_buffs(), "Records and the four R&D rooms expose their distinct unlocks")
	_check(not profile.purchase_room(HeadquartersCatalog.CONTROL).is_empty(), "An already maxed room rejects another purchase")
	var finale := CampaignContent.new().operation(&"C2-10")
	_check(profile.is_visible(finale) and profile.access_error(finale) == "Clear C2-09 first", "Control reveals the finale while preserving ordered Campaign clears")

func _leveling() -> void:
	var expected := [0, 60096, 191001, 391287, 660953, 1000000]
	var levels := [1] + DeployableLevels.MILESTONES
	for i in levels.size():
		_check(DeployableLevels.cumulative(levels[i]) == expected[i], "Cumulative pricing matches Lv.%d" % levels[i])
	var total := 0
	var previous := 0
	for level in range(2, 101):
		var price := DeployableLevels.cost(level - 1, level)
		_check(price > previous, "Lv.%d raises the incremental cost" % level)
		total += price
		previous = price
	_check(total == DeployableLevels.TOTAL_COST, "Ninety-nine individual costs total exactly 1,000,000")
	var roster := DeployableLevels.catalog(true) + DeployableLevels.catalog(false)
	_check(DeployableLevels.catalog(true).size() == 12 and DeployableLevels.catalog(false).size() == 13, "All 25 IDs are listed for permanent progression")
	var path := _path("levels")
	var fixture := CampaignSave.fresh()
	fixture.funds = FundsWallet.CAP
	fixture.rooms[String(HeadquartersCatalog.MECHANICAL)] = 5
	fixture.rooms[String(HeadquartersCatalog.HR)] = 5
	fixture.rooms[String(HeadquartersCatalog.FINANCE)] = 5
	fixture.rooms["room.r_d_combat"] = 2
	fixture.owned = roster.map(func(entry: DeploymentSpec) -> String: return String(entry.id))
	ProfileFile.replace(path, fixture, false)
	var profile := CampaignProgress.new(path)
	for spec: DeploymentSpec in roster:
		_top_up(profile, 1000000)
		var before := profile.funds()
		_check(profile.purchase_levels(spec.id, 20).is_empty() and profile.purchase_levels(spec.id, 100).is_empty() and profile.deployable_level(spec.id) == 100 and profile.funds() == before - 1000000, "%s purchases both checkpoints for exactly one million" % spec.label)
	profile = CampaignProgress.new(path)
	_check(profile.snapshot().deployable_levels.size() == 25 and profile.deployable_level(&"facility.sentry_tower") == 100, "All 25 purchased levels survive reload")

	var source := DeployableLevels.definition(&"ranger.scout_sniper").duplicate() as RangerSpec
	source.growth = DeployableGrowth.new()
	source.growth.hp = 200
	source.growth.attack_damage = 48
	source.growth.skill_damage = 48
	var next := DeployableLevels.effective(source, 20) as RangerSpec
	_check(next.max_hp == 119 and next.attack_damage == 29 and next.active_skill.damage == 29, "A test endpoint interpolates only authored integer raw outputs")
	_check(source.level == 1 and source.attack_damage == 24 and source.active_skill.damage == 24, "Effective stats leave base resources unchanged")
	_check(next.block_capacity == source.block_capacity and next.attack_seconds == source.attack_seconds and next.footprint(Vector2i.ZERO) == source.footprint(Vector2i.ZERO) and next.active_skill.max_charges == source.active_skill.max_charges and next.active_skill.recharge_seconds == source.active_skill.recharge_seconds, "Leveling keeps geometry, cadence, block, charges and cooldowns")
	var facility := DeployableLevels.definition(&"facility.medic_cabin").duplicate() as FacilitySpec
	facility.growth = DeployableGrowth.new()
	facility.growth.healing = 130
	var upgraded := DeployableLevels.effective(facility, 100) as FacilitySpec
	_check(upgraded.heal_per_kit == 130 and upgraded.build_seconds == facility.build_seconds and upgraded.work_seconds == facility.work_seconds and upgraded.attack_damage == 0, "Facility healing uses its endpoint and the original build, stock and combat behavior")
	var content := CampaignContent.new()
	var plan := OperationPlan.new(content.operation(&"C1-02"), [])
	plan.configure_campaign(profile)
	_check(plan.ranger_limit == 8 and plan.facility_limit == 6 and plan.selected_count(true) == 7 and plan.selected_count(false) == 6, "Planning consumes HQ limits while pending kits stay out of the field roster")
	var chosen := plan.deployment_entries().filter(func(spec: DeploymentSpec) -> bool: return spec.logistics_post)
	var post := chosen[0] as FacilitySpec
	var state := DeploymentState.new(plan.operation.stage.map, CombatClock.new(), 0, plan.operation.opening_rules)
	_check(post.level == 100 and post.build_seconds == 6.0 and state.deploy(post, Vector2i(1, 0), -1).is_empty(), "Purchased Post level reaches actual deployment with the free first drop")
	for i in LogisticsRules.PAYOUT_TICKS:
		state.clock.advance_frame()
	_check(state.tokens == 15, "A deployed Lv.100 Post yields exactly 15 after ten combat seconds")
	_check(plan.set_modifier(BattleModifiers.CATALOG.definition(&"B05"), true), "R&D Combat Lv.2 unlocks the playable B05 effect")
	plan = OperationPlan.new(content.operation(&"C1-01"), [])
	plan.configure_campaign(profile)
	chosen = plan.deployment_entries().filter(func(spec: DeploymentSpec) -> bool: return spec.logistics_post)
	_check(chosen[0].level == 1 and plan.selected_ids.is_empty(), "Tutorial supply keeps its authored base levels outside ordinary slots")

func _activities() -> void:
	var path := _path("activities")
	var profile := _funded(path, 21249)
	profile.purchase_room(HeadquartersCatalog.OUTREACH)
	_check(_outreach_batch(profile, 200000), "Outreach saves a 20-item rotation and active choices")
	var batch: Dictionary = profile.snapshot().outreach
	var first: String = batch.batch[0]
	var response := profile.record_outreach_response(first, 0, &"harmful")
	_check(response.deducted == 6249 and profile.funds() == 0, "Harmful deducts only the held balance")
	_check(profile.record_outreach_response(first, 0, &"best").is_empty() and profile.funds() == 0, "An answered Outreach question cannot award again in its batch")
	_check(not _outreach_batch(profile, 199000) and not _outreach_batch(profile, 271999), "Clock rollback and early refresh retain the batch")
	profile = CampaignProgress.new(path)
	_check(profile.snapshot().outreach.responses[first].grade == "harmful" and profile.snapshot().outreach.responses[first].choice == 3, "Shuffled choice, grade and reply survive cold load")
	for i in range(1, 5):
		profile.record_outreach_response(batch.batch[i], 1, &"best")
	_check(_outreach_batch(profile, 272000) and profile.outreach_successes() == 4, "One new batch opens at 20 hours and retains successful participation")
	_check(not _outreach_batch(profile, 272000), "Refreshing at the same time cannot create another batch")
	profile.purchase_room(HeadquartersCatalog.RECORDS)
	profile.purchase_room(HeadquartersCatalog.RECORDS)
	var chapter := &"records_chapter.scout_sniper"
	_check(not profile.begin_quiz(&"records_chapter.woods_tracker", ["test.q1"]), "Inactive Records chapter cannot start")
	_check(profile.begin_quiz(chapter, ["test.q1", "test.q2"]) and profile.save_quiz_timer("test.q1", 450), "Opened Records chapter saves session order and remaining time")
	profile = CampaignProgress.new(path)
	_check(profile.snapshot().encyclopaedia.attempt.time_left_ticks == 450, "Quiz timer survives cold load")
	var first_correct := profile.record_quiz_answer("test.q1", 1, true, 300)
	profile.record_quiz_answer("test.q2", 2, true, 300)
	var completion := profile.finish_quiz(600)
	_check(first_correct.credited == 300 and completion.credited == 600 and chapter in profile.records_enhancements(), "First correct and first perfect commit award flags and the named enhancement")
	profile.begin_quiz(chapter, ["test.q1", "test.q2"])
	var again := profile.record_quiz_answer("test.q1", 1, true, 300)
	profile.save_quiz_timer("test.q2", 0)
	var timeout := profile.record_quiz_answer("test.q2", -1, false, 300)
	_check(again.credited == 0 and not again.first_correct and timeout.credited == 0 and profile.finish_quiz(600).credited == 0, "Replay and timeout preserve prior rewards without reissuing them")

	profile.purchase_room(HeadquartersCatalog.ECOLOGY)
	var cycle := profile.plant_garden(0, "species.strangler_fig", 400000)
	_check(profile.water_garden(0, cycle, 432401), "Ecology stores planted and watered timestamps")
	profile = CampaignProgress.new(path)
	_check(profile.snapshot().garden.plots["garden_plot.01"].watered_at == 432401, "Garden timer anchors survive cold load")
	_check(profile.plant_garden(2, "species.strangler_fig", 400000).is_empty(), "Cannot persist planting in a locked plot")
	var collection := profile.collect_garden(0, cycle, 464801)
	_check(collection.credited == 53000 and profile.restoration_percent() == 20 and profile.collect_garden(0, cycle, 464801).is_empty(), "Restoration event and wallet commit together with repeat protection")

func _migration_and_recovery() -> void:
	var path := _path("migration")
	var v1 := {
		"version": 1, "leader_name": "Rina", "funds": 42750, "control": 3, "mechanical": true,
		"finance": 4321.5, "records": {"C1-01": {"cleared": true, "perfect": true}},
		"owned": ["ranger.scout_sniper", "ranger.patrolman", "facility.logistics_post"],
		"pending_attempt": "C1-02",
	}
	ProfileFile.replace(path, v1, false)
	var profile := CampaignProgress.new(path)
	_check(profile.load_status == CampaignProgress.LoadStatus.MIGRATED and ProfileFile.read(path).version == 2 and ProfileFile.read(path + ".bak").version == 1, "V1 migration atomically writes v2 and retains its source backup")
	_check(profile.snapshot().leader_name == "Rina" and profile.funds() == 42750 and profile.room_level(HeadquartersCatalog.CONTROL) == 3 and profile.room_level(HeadquartersCatalog.MECHANICAL) == 1, "Migration retains name, wallet and equivalent rooms")
	_check(profile.finance_stored() == 4321 and profile.record_for(&"C1-01").perfect and profile.snapshot().pending_attempt == "C1-02", "Migration retains the Finance fraction, Story flags and pending operation")
	ProfileFile.replace(path, {"version": 2}, false)
	profile = CampaignProgress.new(path)
	_check(profile.load_status == CampaignProgress.LoadStatus.RECOVERED and profile.funds() == 42750 and ProfileFile.read(path).version == 2, "Unreadable primary heals from the valid migrated backup")
	ProfileFile.replace(path, {"version": 99}, false)
	profile = CampaignProgress.new(path)
	_check(profile.load_status == CampaignProgress.LoadStatus.NEWER_VERSION and not profile.can_play() and not profile.set_leader_name("Overwrite") and ProfileFile.read(path).version == 99, "A newer profile blocks downgrade and preserves the newer data")
	ProfileFile.replace(path, {"version": 2}, false)
	ProfileFile.replace(path + ".bak", {"version": 2}, false)
	profile = CampaignProgress.new(path)
	profile.advance_finance(6000)
	_check(profile.load_status == CampaignProgress.LoadStatus.UNREADABLE and profile.finance_stored() == 0 and not profile.set_leader_name("Overwrite"), "Two invalid copies require recovery and block writes")
	_check(profile.reset_profile() and not FileAccess.file_exists(path + ".bak") and profile.snapshot().leader_name.is_empty(), "Confirmed reset writes a fresh primary and invalidates its backup")
	ProfileFile.replace(path + ".bak", v1, false)
	ProfileFile.replace(path + ".reset", {"confirmed": true}, false)
	profile = CampaignProgress.new(path)
	_check(profile.snapshot().leader_name.is_empty() and profile.funds() == 10000 and not FileAccess.file_exists(path + ".bak") and not FileAccess.file_exists(path + ".reset"), "Restart completes an interrupted confirmed reset without reviving the old save")
	DirAccess.make_dir_absolute(path + ".tmp")
	_check(not profile.set_leader_name("Cannot write") and profile.snapshot().leader_name.is_empty() and ProfileFile.read(path).leader_name.is_empty(), "A failed primary write preserves both in-memory and disk state")
	DirAccess.remove_absolute(path + ".tmp")

func _outreach_batch(profile: CampaignProgress, now: int) -> bool:
	var rotation: Array[String] = []
	var choices := {}
	for index in 20:
		rotation.append("test.outreach.%02d" % index)
	var questions := rotation.slice(0, 5)
	for id: String in questions:
		choices[id] = [3, 1, 0, 2]
	return profile.open_outreach_batch(rotation, questions, choices, now)

func _top_up(profile: CampaignProgress, amount: int) -> void:
	while profile.funds() < amount:
		profile.advance_finance(1000000.0)
		if not profile.claim_finance():
			_check(false, "A scripted Finance claim can fund the next verified purchase")
			return

func _funded(path: String, amount: int) -> CampaignProgress:
	var seed := CampaignSave.fresh()
	seed.funds = amount
	ProfileFile.replace(path, seed, false)
	return CampaignProgress.new(path)

func _path(suffix: String) -> String:
	var path := _prefix + "-" + suffix + ".json"
	_paths.append(path)
	return path

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
