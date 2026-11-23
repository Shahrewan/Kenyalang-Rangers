extends SceneTree

# The reference credits are a budget experiment. Only the installed-content column
# goes through real profile transactions and combat eligibility.
const DAYS := 60
const TARGETS := {"campaign": 7420000, "outreach": 5000000, "garden": 5300000,
	"chaos": 5200000, "records": 1550000, "finance_replay": 550000}
const SOURCES := [&"campaign", &"outreach", &"garden", &"chaos", &"records", &"finance_replay"]
const MECHANICAL := HeadquartersCatalog.MECHANICAL
const ECOLOGY := HeadquartersCatalog.ECOLOGY
const LOADOUT: Array[StringName] = [&"ranger.patrolman", &"facility.logistics_post"]
const DEBUFFS: Array[StringName] = [&"D02", &"D03", &"D05", &"D07", &"D08", &"D12", &"D13", &"D15"]
var content := CampaignContent.new()
var path := "user://c23-economy-%d.json" % OS.get_process_id()
var profile: CampaignProgress
var failures := 0
var totals := {}
var spent := 0
var clipped := 0
var cleared := 0
var farm_config := ChaosConfiguration.new()
var farm_runs := 0
var mechanical_day := 0
var garden_cycles := 0
var education := EducationCatalog.load_installed()
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = 23
	profile = CampaignProgress.new(path)
	var costs: Array[int] = []
	for room in CampaignSave.HEADQUARTERS.rooms:
		for level in range(1, 6):
			if room.cost(level) > 0:
				costs.append(room.cost(level))
	var hq := costs.reduce(func(a: int, b: int) -> int: return a + b, 0) as int
	for i in 8:
		costs.append(DeployableLevels.cost(1, 100))
	_check(hq == 16160000 and costs.size() == 60, "52 HQ purchases and eight max-level purchases")
	var regular := _reference(costs, 1)
	var delayed := _reference(costs, DAYS)
	_check(regular.spent == 24160000 and regular.clipped == 0 and regular.balance == 870000, "Staged spending reconciles the GDD totals and starting balance")
	_check(delayed.clipped == 15030001 and delayed.spent < regular.spent, "Saving all GDD receipts until day 60 permanently loses overflow")
	var best_rate := 0.0
	for species: Dictionary in RestorationRules.SPECIES.values():
		best_rate = maxf(best_rate, float(species.funds) / species.hours)
	var milestones: int = RestorationRules.MILESTONES.values().reduce(func(a: int, b: int) -> int: return a + b, 0)
	var plots := CampaignSave.HEADQUARTERS.room(ECOLOGY).capacity(5)
	var garden_bound := floori(plots * DAYS * 24 * best_rate) + milestones
	print("GDD targets ", JSON.stringify(TARGETS), " expenses ", hq + 8 * DeployableLevels.TOTAL_COST)
	print("GDD staged ", JSON.stringify(regular), " day-60 spend ", JSON.stringify(delayed), " garden upper bound ", garden_bound)
	for source in SOURCES:
		totals[source] = 0
	farm_config.select_route(&"T01")
	farm_config.set_quantity(0, &"E01", 2)
	farm_config.set_quantity(1, &"E01", 1)
	print("day,campaign,outreach,garden,chaos,records,finance_replay,spent,discarded,balance")
	for day in range(1, DAYS + 1):
		var previous := totals.duplicate()
		var previous_spent := spent
		var previous_clipped := clipped
		_day(day)
		var row := PackedStringArray([str(day)])
		for source in SOURCES:
			row.append(str(totals[source] - previous[source]))
		row.append_array(PackedStringArray([str(spent - previous_spent), str(clipped - previous_clipped), str(profile.funds())]))
		print(",".join(row))
		var cold := CampaignProgress.new(path)
		_check(cold.load_status == CampaignProgress.LoadStatus.READY and JSON.parse_string(JSON.stringify(cold.snapshot())) == JSON.parse_string(JSON.stringify(profile.snapshot())), "cold reload day %d" % day)
		profile = cold
	var gross: int = totals.values().reduce(func(a: int, b: int) -> int: return a + b, 0)
	_check(profile.funds() == CampaignSave.STARTING_FUNDS + gross - clipped - spent, "All daily income, spend and discard reconciles")
	_check(farm_runs > 0 and mechanical_day > 0 and garden_cycles > 0, "Installed route reaches Mechanical, qualifying Chaos and Garden")
	print("INSTALLED ", JSON.stringify({"gross": totals, "spent": spent, "discarded": clipped,
		"balance": profile.funds(), "mechanical_day": mechanical_day, "stages": cleared,
		"chaos_clears": farm_runs, "garden_cycles": garden_cycles, "rooms": profile.snapshot().rooms,
		"deployables": profile.snapshot().deployable_levels, "outreach_available": not education.outreach.is_empty(),
		"records_available": not education.chapters.is_empty()}))
	for suffix in ["", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	print("Economy audit failures ", failures)
	quit(1 if failures else 0)

func _reference(costs: Array[int], first_spend_day: int) -> Dictionary:
	var wallet := {"funds": CampaignSave.STARTING_FUNDS}
	var index := 0
	var paid := 0
	var discarded := 0
	var completion := 0
	for day in range(1, DAYS + 1):
		for total: int in TARGETS.values():
			var amount := (total * day) / DAYS - (total * (day - 1)) / DAYS
			discarded += int(FundsWallet.apply(wallet, amount).discarded)
		if day >= first_spend_day:
			while index < costs.size() and costs[index] <= wallet.funds:
				FundsWallet.apply(wallet, -costs[index])
				paid += costs[index]
				index += 1
			if index == costs.size() and completion == 0:
				completion = day
	return {"balance": wallet.funds, "spent": paid, "clipped": discarded, "completion_day": completion}

func _day(day: int) -> void:
	profile.advance_finance(600)
	var quote := profile.finance_preview()
	if profile.claim_finance():
		_receipt(&"finance_replay", quote)
	var base_time := 1700000000 + (day - 1) * 86400
	_garden(base_time)
	_shop(day)
	if cleared < content.operations.size():
		var op := content.operations[cleared]
		var plan := OperationPlan.new(op, [])
		plan.configure_campaign(profile)
		if profile.access_error(op).is_empty() and plan.can_start() and profile.begin_attempt(op):
			var receipt := profile.complete(op, true)
			if not receipt.is_empty():
				_receipt(&"campaign", receipt)
				cleared += 1
	if profile.room_level(MECHANICAL) > 0:
		_farm()
	if day % 7 == 0:
		_study(base_time)
	_garden(base_time + 43200)
	_shop(day)

func _study(now: int) -> void:
	var outreach := OutreachSession.new(profile, education, rng)
	if outreach.refresh(now):
		var batch := outreach.batch()
		for id: String in batch.batch:
			for index in 4:
				var choice: int = batch.choice_order[id][index]
				if education.outreach[id].choices[choice].grade == "best":
					_receipt(&"outreach", outreach.submit(id, index, now))
					break
	for chapter in profile.records_chapters():
		if chapter in profile.snapshot().encyclopaedia.perfect_chapters:
			continue
		var quiz := RecordsQuiz.new(profile, education)
		if not quiz.begin(chapter):
			continue
		while not quiz.question().is_empty():
			var item := quiz.question()
			var correct: int = item.choices.find_custom(func(choice: Dictionary) -> bool: return choice.id == item.correct_choice_id)
			if not quiz.answer(correct):
				_check(false, "scheduled Records answer")
				return
			_receipt(&"records", quiz.feedback())
			if not quiz.continue_after_feedback():
				_check(false, "scheduled Records review")
				return
		_receipt(&"records", quiz.result)
		break

func _shop(day: int) -> void:
	# Save first for Mechanical, then the first two garden plots.
	for id: StringName in [MECHANICAL, ECOLOGY]:
		if profile.room_level(id) == 0:
			if not _buy_room(id):
				return
			if id == MECHANICAL:
				mechanical_day = day
	# Upgrade the cheapest eligible room first. Use catalog order to break ties.
	while true:
		var next: HeadquartersRoom
		var price := FundsWallet.CAP
		for room in CampaignSave.HEADQUARTERS.rooms:
			var quote := profile.room_quote(room.id)
			if quote.error.is_empty() and quote.cost < price:
				price = quote.cost
				next = room
		if next == null or not _buy_room(next.id):
			break
	# Prefer the first eight owned, combat-ready entries in roster order.
	var preferred := 0
	for spec in content.roster.entries:
		if not profile.owns(spec.id):
			continue
		preferred += 1
		if preferred > 8:
			break
		var quote := profile.level_quote(spec.id, 100)
		if quote.error.is_empty() and profile.purchase_levels(spec.id, 100).is_empty():
			spent += int(quote.cost)

func _buy_room(id: StringName) -> bool:
	var quote := profile.room_quote(id)
	if not quote.error.is_empty() or not profile.purchase_room(id).is_empty():
		return false
	spent += int(quote.cost)
	return true

func _garden(now: int) -> void:
	for slot in profile.room_capacity(ECOLOGY):
		var state := profile.garden_state()
		var plot: Dictionary = state.plots.get(RestorationRules.plot_id(slot), {})
		if not plot.is_empty():
			if RestorationRules.needs_water(plot, now):
				_check(profile.water_garden(slot, plot.cycle_id, now), "water")
			elif RestorationRules.stage(plot, now) == RestorationRules.Stage.MATURE:
				var receipt := profile.collect_garden(slot, plot.cycle_id, now)
				_check(not receipt.is_empty(), "harvest")
				_receipt(&"garden", receipt)
				garden_cycles += 1
			else:
				continue
		if not profile.garden_state().plots.has(RestorationRules.plot_id(slot)):
			var species: String = RestorationRules.SPECIES.keys()[slot % 4]
			if profile.restoration_percent() == 100:
				species = "species.mengaris"
			_check(not profile.plant_garden(slot, species, now).is_empty(), "plant")

func _farm() -> void:
	var op := StoryOperation.new()
	op.campaign_spec = true
	op.roster = content.roster
	op.stage = farm_config.build_stage()
	op.opening_rules = LogisticsRules.new()
	var plan := OperationPlan.new(op, [], true)
	plan.configure_campaign(profile, LOADOUT)
	plan.restore_modifier_selection(DEBUFFS)
	var resolution := plan.resolved()
	var run := profile.begin_chaos(farm_config, resolution, plan.selected_ids, DEBUFFS)
	if run == null:
		_check(false, "farm opening: " + resolution.selection_error)
		return
	# Exercise each scheduled clear through the combat clock and settlement.
	var spec := resolution.entries[0]
	var farm_battle := BattleSimulation.new(resolution.stage)
	farm_battle.deployment = DeploymentState.new(resolution.stage.map, farm_battle.clock,
		resolution.tokens, resolution.opening, [], farm_battle.effects)
	_check(farm_battle.deployment.deploy(spec, Vector2i(2, 1), -1).is_empty(), "legal actual farm placement")
	for frame in 18000:
		if farm_battle.outcome != BattleSimulation.Outcome.RUNNING:
			break
		farm_battle.clock.advance_frame()
	if farm_runs == 0:
		print("FARM level=", spec.level, " ticks=", farm_battle.clock.tick, " score=", run.score.points(),
			" defeated=", farm_battle.configured_defeated, " escaped=", farm_battle.escaped)
	run.record_outcome(farm_battle)
	_check(run.qualifies(), "farm qualifies without manual damage or clock overrides")
	var receipt := profile.settle_chaos(run)
	if not receipt.is_empty():
		_receipt(&"chaos", receipt)
		farm_runs += int(run.qualifies())

func _receipt(source: StringName, receipt: Dictionary) -> void:
	totals[source] += int(receipt.credited) + int(receipt.discarded)
	clipped += int(receipt.discarded)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
