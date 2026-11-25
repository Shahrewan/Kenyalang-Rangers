extends SceneTree
## Profile-level cash flow using isolated saves and the shipping settlement APIs.

const CHAOS := preload("res://tests/balance/chaos_payout_case.gd")
const PROPOSAL_PATH := "res://docs/production/c32/rewards_proposal.json"
const DAYS := 60
const DAY_SECONDS := 86400
const START_TIME := 1700000000
const SOURCES := ["story_clear", "story_perfect", "story_completion", "story_replay", "records", "finance", "outreach", "garden", "chaos"]
const POST := &"facility.logistics_post"
const MECHANICAL := HeadquartersCatalog.MECHANICAL
const ECOLOGY := HeadquartersCatalog.ECOLOGY
const CONTROL := HeadquartersCatalog.CONTROL
const OUTREACH := HeadquartersCatalog.OUTREACH
const RECORDS := HeadquartersCatalog.RECORDS
const HR := HeadquartersCatalog.HR
const FINANCE := HeadquartersCatalog.FINANCE
const UNITS: Array[StringName] = [&"ranger.scout_sniper", POST, &"ranger.patrolman", &"ranger.guard_veteran",
	&"ranger.combat_medic", &"facility.sonic_turret", &"ranger.k9_ranger", &"facility.sentry_tower"]
const MODERATE := {"seconds": 1800, "visits": 2, "question_days": [1, 3, 5], "questions": 2,
	"menu_seconds": 160, "attempt_every": 2, "chaos_days": [3, 6], "chaos_per_day": 1, "quiz_every": 7}
const PROFILES := {
	"casual": {"seconds": 900, "visits": 1, "question_days": [2, 5], "questions": 1,
		"menu_seconds": 90, "attempt_every": 3, "chaos_days": [6], "chaos_per_day": 1, "quiz_every": 14},
	"moderate": MODERATE,
	"chaos_regular": {"seconds": 4500, "visits": 3, "question_days": [1, 2, 4, 6], "questions": 3,
		"menu_seconds": 240, "attempt_every": 1, "chaos_days": [1, 2, 3, 4, 5, 6], "chaos_per_day": 3, "quiz_every": 4},
	"rare_perfect": MODERATE,
	"hq_first": MODERATE,
	"unit_first": MODERATE,
}
const MODERATE_OUTREACH := [25000, 60000, 90000, 125000, 175000]
const SCENARIOS := {
	"c32_d": {"cap": false, "outreach": "installed"},
	"chaos_only": {"cap": true, "outreach": "installed"},
	"outreach_moderate": {"cap": false, "outreach": "moderate"},
	"outreach_proposed": {"cap": false, "outreach": "proposed"},
	"combined_moderate": {"cap": true, "outreach": "moderate"},
	"combined_proposed": {"cap": true, "outreach": "proposed"},
}

var _proposal := ProfileFile.read(PROPOSAL_PATH)
var _content := CampaignContent.new()
var _rng := RandomNumberGenerator.new()
var _path := "user://c32-ledger-%d.json" % OS.get_process_id()
var _wallet: CampaignProgress
var _education: EducationCatalog
var _policy: Dictionary
var _variant: String
var _profile: String
var _failures := 0
var _checks := 0
var _day := 0
var _remaining := 0
var _gross: Dictionary
var _discarded: Dictionary
var _spending: Dictionary
var _actions: Dictionary
var _milestones: Dictionary
var _active_seconds := 0
var _time_by_activity: Dictionary
var _story_index := 0
var _attempts_for_stage := 0
var _records_attempts: Dictionary
var _outreach_deducted := 0
var _finance_unstored := 0
var _daily := false
var _replay_days := 0
var _long_chaos_spacing := 0
var _last_long_chaos_day := 0
var _chaos_examples := {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_daily = "--daily" in args
	_long_chaos_spacing = 2 if "--long-chaos-mix=2" in args else (3 if "--long-chaos-mix" in args else 0)
	_check(_content.error.is_empty() and _proposal.get("status") == "approved_for_playtest", "Loaded the active schedule and comparison values")
	if _failures == 0:
		_reference()
		if _long_chaos_spacing > 0:
			_simulate("combined_moderate", "chaos_regular")
		else:
			for variant: String in SCENARIOS:
				if not args.has("--variant=" + variant) and Array(args).any(func(arg: String) -> bool: return arg.begins_with("--variant=")):
					continue
				for key: String in PROFILES:
					if args.has("--profile=" + key) or not Array(args).any(func(arg: String) -> bool: return arg.begins_with("--profile=")):
						_simulate(variant, key)
		print("CHAOS ", JSON.stringify(_chaos_examples))
	_cleanup()
	print("C32 economy simulation: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _simulate(variant: String, key: String) -> void:
	_cleanup()
	_wallet = CampaignProgress.new(_path)
	_education = EducationCatalog.load_installed()
	_check(_education.outreach.size() == 20 and _education.chapters.size() == 4, "Installed C31-C education banks")
	_profile = key
	_variant = variant
	_policy = PROFILES[key]
	_rng.seed = 32
	_active_seconds = 0
	_time_by_activity = {}
	_story_index = 0
	_attempts_for_stage = 0
	_outreach_deducted = 0
	_finance_unstored = 0
	_replay_days = 0
	_last_long_chaos_day = 0
	_records_attempts = {}
	_milestones = {}
	_gross = {}
	_discarded = {}
	_spending = {"hq": 0, "rangers": 0, "facilities": 0}
	_actions = {}
	for source in SOURCES:
		_gross[source] = 0
		_discarded[source] = 0
	var outreach_room: HeadquartersRoom = CampaignSave.HEADQUARTERS.room(OUTREACH)
	var original_grades := outreach_room.best_response.duplicate()
	match SCENARIOS[variant].outreach:
		"moderate":
			outreach_room.best_response = PackedInt32Array(MODERATE_OUTREACH)
		"proposed":
			outreach_room.best_response = PackedInt32Array(_proposal.sensitivity_only.outreach_best_by_level)
	for day in range(1, DAYS + 1):
		_day = day
		_remaining = int(_policy.seconds)
		var day_start := _snapshot() if _daily else {}
		_simulate_day()
		var cold := CampaignProgress.new(_path)
		_check(cold.load_status == CampaignProgress.LoadStatus.READY and JSON.parse_string(JSON.stringify(cold.snapshot())) == JSON.parse_string(JSON.stringify(_wallet.snapshot())),
			"%s %s cold reload day %d" % [variant, key, day])
		_wallet = cold
		var snapshot := _snapshot()
		var earned := _sum(_gross)
		_check(_wallet.funds() == CampaignSave.STARTING_FUNDS + earned - _sum(_discarded) - _sum(_spending) - _outreach_deducted,
			"%s %s reconciles day %d" % [variant, key, day])
		_check(_sum(_time_by_activity) == _active_seconds and _active_seconds <= day * int(_policy.seconds),
			"%s %s respects the active-time budget on day %d" % [variant, key, day])
		if _daily:
			var deltas := snapshot.duplicate(true)
			for field in ["gross", "discarded", "spending", "activities", "time_by_activity"]:
				for category in deltas[field]:
					deltas[field][category] -= int(day_start[field].get(category, 0))
			for field in ["active_seconds", "outreach_deducted", "finance_unstored"]:
				deltas[field] -= int(day_start[field])
			print("DAY ", JSON.stringify(deltas))
		if day in [7, 30, 60]:
			print("CHECKPOINT ", JSON.stringify(snapshot))
	outreach_room.best_response = original_grades

func _simulate_day() -> void:
	var morning := START_TIME + (_day - 1) * DAY_SECONDS
	_time(int(_policy.menu_seconds), "menu")
	_shop()
	_garden(morning)
	if _story_index >= _content.operations.size() or (_day - 1) % int(_policy.attempt_every) == 0:
		_story()
	if _day % 7 in _policy.question_days:
		_outreach(morning)
	if _day % int(_policy.quiz_every) == 0:
		_records()
	if _day % 7 in _policy.chaos_days and _wallet.room_level(MECHANICAL) > 0:
		for run in int(_policy.chaos_per_day):
			_chaos()
	for visit in range(1, int(_policy.visits)):
		_garden(morning + int(visit * DAY_SECONDS / int(_policy.visits)))
	var finance := _wallet.finance_preview()
	if _wallet.claim_finance():
		_credit("finance", finance)
	_shop()
	_track_milestones()
	_check(_wallet.flush_finance(), "Finance checkpoint")

func _story() -> void:
	if _story_index >= _content.operations.size():
		if _day % 7 == 1:
			_play_story(_content.operations.back(), false, true)
		return
	var operation := _content.operations[_story_index]
	if not _wallet.access_error(operation).is_empty() or not _plan(operation).can_start():
		_count("story_blocked")
		# One optional short replay in weeks when the next operation is locked.
		if _story_index > 0 and _day % 7 <= 2 and _day / 7 > _replay_days:
			if _play_story(_content.operations[0], false, true):
				_replay_days = _day / 7
		return
	var wins := _attempts_for_stage != 0 or (_story_index + 1) % (4 if _profile == "casual" else 5) != 0
	if not _play_story(operation, wins and _perfect(String(operation.stage.stage_id)), wins):
		return
	if wins:
		_story_index += 1
		_attempts_for_stage = 0
		_shop_story_gate()
	else:
		_attempts_for_stage += 1

func _plan(operation: StoryOperation) -> OperationPlan:
	var plan := OperationPlan.new(operation, [])
	plan.configure_campaign(_wallet)
	return plan

func _perfect(id: String) -> bool:
	if _profile == "rare_perfect":
		return id == "C1-01"
	if _profile == "casual":
		return id in ["C1-01", "C1-05", "C2-04"]
	return id in _proposal.reference_first_perfects

func _play_story(source: StoryOperation, perfect: bool, wins: bool) -> bool:
	var id := String(source.stage.stage_id)
	var combat := int(_proposal.story_active_seconds_at_2x[id])
	var duration := (combat if wins else ceili(combat * 0.65)) + 180
	if not _time(duration, "story", combat if wins else ceili(combat * 0.65)) or not _wallet.begin_attempt(source):
		return false
	if not wins:
		_check(_wallet.abandon_attempt(), "Clear failed-attempt marker")
		_count("story_defeats")
		return true
	var receipt := _wallet.complete(source, perfect)
	_check(not receipt.is_empty(), "Story settlement " + id)
	if receipt.is_empty():
		return false
	_count("story_first_clear" if receipt.first_clear else "story_replays")
	if receipt.first_perfect:
		_count("story_first_perfect")
	var available := int(receipt.credited)
	for field in ["first_clear_funds", "first_perfect_funds", "story_completion_funds", "replay_funds"]:
		if not receipt.awards.has(field):
			continue
		var amount := int(receipt.awards[field])
		var credited := mini(amount, available)
		available -= credited
		var tag: String = {"first_clear_funds": "story_clear", "first_perfect_funds": "story_perfect",
			"story_completion_funds": "story_completion", "replay_funds": "story_replay"}[field]
		_credit(tag, {"credited": credited, "discarded": amount - credited})
	_check(available == 0, "Every Story credit attributed")
	_track_milestones()
	return true

func _outreach(now: int) -> void:
	if _wallet.room_level(OUTREACH) == 0 or not _time(15, "outreach"):
		return
	var session := OutreachSession.new(_wallet, _education, _rng)
	if not session.refresh(now):
		return
	var batch := session.batch()
	for i in mini(batch.batch.size(), int(_policy.questions)):
		if not _time(35, "outreach"):
			break
		var id: String = batch.batch[i]
		var grades := ["acceptable", "best", "best", "poor", "acceptable", "best", "harmful", "best"]
		var grade: String = grades[(_day + i) % grades.size()]
		var choices: Array = _education.outreach[id].choices
		var authored := choices.find_custom(func(choice: Dictionary) -> bool: return choice.grade == grade)
		var index: int = batch.choice_order[id].find(authored)
		var receipt := session.submit(id, index, now)
		_check(not receipt.is_empty(), "Outreach submission")
		_credit("outreach", receipt)
		_outreach_deducted += int(receipt.get("deducted", 0))
		_count("outreach_answers")

func _records() -> void:
	for id in _wallet.records_chapters():
		if id in _wallet.snapshot().encyclopaedia.perfect_chapters:
			continue
		if not _time(220, "records"):
			return
		var quiz := RecordsQuiz.new(_wallet, _education)
		_check(quiz.begin(id), "Start installed Records quiz")
		var first_try := not _records_attempts.has(id)
		_records_attempts[id] = int(_records_attempts.get(id, 0)) + 1
		for n in quiz.question_count():
			var item := quiz.question()
			var correct: int = item.choices.find_custom(func(choice: Dictionary) -> bool: return choice.id == item.correct_choice_id)
			if first_try and _profile in ["casual", "moderate", "rare_perfect", "hq_first", "unit_first"] and n == 9:
				correct = (correct + 1) % 4
			_check(quiz.answer(correct), "Submit Records answer")
			_credit("records", quiz.feedback())
			_check(quiz.continue_after_feedback(), "Continue Records result")
		_credit("records", quiz.result)
		_count("records_attempts")
		return

func _garden(now: int) -> void:
	for slot in _wallet.room_capacity(ECOLOGY):
		var state := _wallet.garden_state()
		var plot: Dictionary = state.plots.get(RestorationRules.plot_id(slot), {})
		if RestorationRules.needs_water(plot, now):
			if _time(8, "garden"):
				_check(_wallet.water_garden(slot, plot.cycle_id, now), "Water eligible plant")
			continue
		if RestorationRules.stage(plot, now) == RestorationRules.Stage.MATURE:
			if not _time(10, "garden"):
				continue
			var receipt := _wallet.collect_garden(slot, plot.cycle_id, now)
			_check(not receipt.is_empty(), "Harvest eligible plant")
			_credit("garden", receipt)
			_count("garden_harvests")
			if not receipt.is_empty():
				_count("garden_milestone_receipts", int(receipt.milestone_funds > 0))
			state = _wallet.garden_state()
		if not state.plots.has(RestorationRules.plot_id(slot)) and _time(10, "garden"):
			var species := "species.mengaris"
			for candidate: String in RestorationRules.SPECIES:
				if candidate not in state.collected_species and not state.plots.values().any(func(item: Dictionary) -> bool: return item.species == candidate):
					species = candidate
					break
			_check(not _wallet.plant_garden(slot, species, now).is_empty(), "Plant a free slot")

func _chaos() -> void:
	# The default models one threshold attempt. The supplemental mix uses a larger
	# challenge every two or three days, within the same session and run budgets.
	var larger_due := _last_long_chaos_day == 0 or (_long_chaos_spacing > 0 and _day - _last_long_chaos_day >= _long_chaos_spacing)
	var team_ready := _wallet.room_level(HR) >= 2 and _wallet.owns(CHAOS.GUARD) and _wallet.owns(CHAOS.MEDIC)
	var larger := larger_due and _day >= 21 and team_ready
	var reserve := 720 if larger else 150
	if _remaining < reserve:
		return
	var receipt := CHAOS.play(_wallet, _content, [50, 50, 50, 50, 50] if larger else [2, 1], SCENARIOS[_variant].cap)
	_check(not receipt.has("error") and not receipt.is_empty(), "Legal Chaos setup and result")
	if receipt.has("error") or receipt.is_empty():
		return
	if larger:
		_last_long_chaos_day = _day
		_count("chaos_long_attempts")
	_count("chaos_runs")
	_count("chaos_clears", int(receipt.qualifies))
	var active := ceili(float(receipt.ticks) / (CombatClock.TICKS_PER_SECOND * 2))
	_check(_time(60 + active, "chaos"), "Chaos consumed planned active time")
	_credit("chaos", receipt)
	var label := _variant + ("_long" if larger else "_short")
	if not _chaos_examples.has(label) or (receipt.qualifies and not _chaos_examples[label].qualifies):
		_chaos_examples[label] = receipt

func _shop_story_gate() -> void:
	if _wallet.room_level(MECHANICAL) == 0:
		_buy_room(MECHANICAL)
	if _story_index < _content.operations.size():
		var target := _content.operations[_story_index].min_control_level
		if _wallet.room_level(CONTROL) < target:
			_buy_room(CONTROL)

func _shop() -> void:
	_shop_story_gate()
	if _wallet.room_level(MECHANICAL) == 0:
		return
	for id in [ECOLOGY, OUTREACH, RECORDS]:
		if _wallet.room_level(id) == 0:
			_buy_room(id)
	if _wallet.room_level(RECORDS) == 1:
		_buy_room(RECORDS)
	var keeper := _reserve()
	if _profile == "unit_first":
		_buy_levels(keeper, 100, 3)
	elif _profile != "hq_first":
		_buy_levels(keeper, 20 if _day < 15 else 40, 3)
	for iteration in 60:
		var cheapest: HeadquartersRoom
		var cost := FundsWallet.CAP
		for room: HeadquartersRoom in CampaignSave.HEADQUARTERS.rooms:
			var quote := _wallet.room_quote(room.id)
			if quote.error.is_empty() and int(quote.cost) < cost and _wallet.funds() - int(quote.cost) >= keeper:
				cheapest = room
				cost = int(quote.cost)
		if cheapest == null or not _buy_room(cheapest.id):
			break
		if _profile == "casual" or (_profile == "unit_first" and _day < 30):
			break
	if _profile != "hq_first" or _at_level(_wallet.snapshot().rooms, 5) == 11:
		_buy_levels(_reserve(), 100 if _day >= 15 else 40, 8)

func _reserve() -> int:
	if _story_index >= _content.operations.size():
		return 0
	var wanted := _content.operations[_story_index].min_control_level
	var room: HeadquartersRoom = CampaignSave.HEADQUARTERS.room(CONTROL)
	return room.cost(_wallet.room_level(CONTROL) + 1) if _wallet.room_level(CONTROL) < wanted else 0

func _buy_room(id: StringName) -> bool:
	var quote := _wallet.room_quote(id)
	if not quote.error.is_empty() or not _time(10, "shopping"):
		return false
	var error := _wallet.purchase_room(id)
	_check(error.is_empty(), "Execute quoted room purchase")
	if not error.is_empty():
		return false
	_spending.hq += int(quote.cost)
	_count("room_purchases")
	_track_milestones()
	return true

func _buy_levels(keeper: int, target: int, count: int) -> void:
	for id in UNITS.slice(0, count):
		var current := _wallet.deployable_level(id)
		for tier in [20, 40, 60, 80, 100]:
			if tier <= current or tier > target:
				continue
			var quote := _wallet.level_quote(id, tier)
			if not quote.error.is_empty() or _wallet.funds() - int(quote.cost) < keeper or not _time(10, "shopping"):
				break
			var error := _wallet.purchase_levels(id, tier)
			_check(error.is_empty(), "Execute quoted deployable purchase")
			if not error.is_empty():
				break
			_spending["rangers" if DeployableLevels.definition(id).is_ranger() else "facilities"] += int(quote.cost)
			_count("level_purchases")

func _track_milestones() -> void:
	var state := _wallet.snapshot()
	var gates := { "mechanical": _wallet.room_level(MECHANICAL) > 0, "control_2": _wallet.room_level(CONTROL) >= 2,
		"control_3": _wallet.room_level(CONTROL) >= 3, "control_4": _wallet.room_level(CONTROL) >= 4,
		"control_5": _wallet.room_level(CONTROL) >= 5, "story_complete": _wallet.record_for(&"C2-10").get("cleared", false),
		"restoration_60": _wallet.restoration_percent() >= 60, "outreach_5_answers": _wallet.outreach_successes() >= 5,
		"ecology_5": _wallet.room_level(ECOLOGY) == 5, "outreach_5": _wallet.room_level(OUTREACH) == 5,
		"all_rnd": _wallet.unlocked_buffs().size() == 15, "hq_max": _at_level(state.rooms, 5) == 11,
		"eight_max": _at_level(state.deployable_levels, 100) >= 8, "chaos_tier_3": _wallet.chaos_personal_best() >= 3000 }
	for gate in gates:
		if gates[gate] and not _milestones.has(gate):
			_milestones[gate] = _day

func _snapshot() -> Dictionary:
	var data := _wallet.snapshot()
	return {"variant": _variant, "profile": _profile, "day": _day, "gross": _gross.duplicate(),
		"discarded": _discarded.duplicate(), "spending": _spending.duplicate(),
		"outreach_deducted": _outreach_deducted, "finance_unstored": _finance_unstored, "balance": _wallet.funds(),
		"active_seconds": _active_seconds, "time_by_activity": _time_by_activity.duplicate(), "session_budget_seconds": _policy.seconds, "activities": _actions.duplicate(),
		"rooms": data.rooms, "units": data.deployable_levels, "max_units": _at_level(data.deployable_levels, 100),
		"restoration_percent": _wallet.restoration_percent(), "outreach_successes": _wallet.outreach_successes(),
		"owned": data.owned.size(), "rd_unlocked": _wallet.unlocked_buffs().size(), "chaos_best": _wallet.chaos_personal_best(),
		"milestones": _milestones.duplicate()}

func _reference() -> void:
	var goals: Dictionary = _proposal.gdd_60_day_source_targets
	var costs: Array[int] = []
	for room: HeadquartersRoom in CampaignSave.HEADQUARTERS.rooms:
		for level in range(1, 6):
			if room.cost(level) > 0:
				costs.append(room.cost(level))
	_check(costs.size() == 52 and costs.reduce(func(a: int, b: int) -> int: return a + b, 0) == 16160000, "HQ budget precedes eight deployables")
	for i in 8:
		costs.append(DeployableLevels.TOTAL_COST)
	for delayed in [false, true]:
		var wallet := {"funds": CampaignSave.STARTING_FUNDS}
		var paid := 0
		var lost := 0
		var index := 0
		var completed := 0
		for day in range(1, DAYS + 1):
			var gross := {}
			for source in goals:
				var cumulative := int(goals[source]) * day / DAYS
				gross[source] = cumulative
				lost += int(FundsWallet.apply(wallet, cumulative - int(goals[source]) * (day - 1) / DAYS).discarded)
			if not delayed or day == DAYS:
				while index < costs.size() and wallet.funds >= costs[index]:
					paid += costs[index]
					FundsWallet.apply(wallet, -costs[index])
					index += 1
			if index == costs.size() and completed == 0:
				completed = day
			if day in [7, 30, 60]:
				print("REFERENCE ", JSON.stringify({"delayed": delayed, "day": day, "gross": gross, "spent": paid,
					"balance": wallet.funds, "discarded": lost, "completion_day": completed}))
		_check(lost == (15030001 if delayed else 0) and wallet.funds == (9999 if delayed else 870000), "Reproduce C23 GDD cap experiment")

func _time(seconds: int, activity: String, finance_seconds := -1) -> bool:
	if _remaining < seconds:
		return false
	_remaining -= seconds
	_active_seconds += seconds
	_time_by_activity[activity] = int(_time_by_activity.get(activity, 0)) + seconds
	var accrued := _wallet.finance_rate() * (seconds if finance_seconds < 0 else finance_seconds)
	_finance_unstored += maxi(0, _wallet.finance_stored() + accrued - _wallet.finance_capacity())
	_wallet.advance_finance(seconds if finance_seconds < 0 else finance_seconds)
	return true

func _count(key: String, amount := 1) -> void:
	_actions[key] = int(_actions.get(key, 0)) + amount

func _credit(source: String, receipt: Dictionary) -> void:
	var loss := int(receipt.get("discarded", 0))
	_gross[source] += int(receipt.get("credited", 0)) + loss
	_discarded[source] += loss

func _at_level(values: Dictionary, level: int) -> int:
	return values.values().filter(func(value: Variant) -> bool: return int(value) == level).size()

func _sum(values: Dictionary) -> int:
	return values.values().reduce(func(a: int, b: int) -> int: return a + b, 0)

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", label)
