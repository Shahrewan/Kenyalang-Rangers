class_name CampaignProgress
extends RefCounted

enum LoadStatus { NEW, READY, MIGRATED, RECOVERED, UNREADABLE, NEWER_VERSION }

const DEFAULT_PATH := "user://campaign_progress.json"
const HEADQUARTERS := CampaignSave.HEADQUARTERS

var load_status := LoadStatus.NEW
var load_notice := ""
var _path: String
var _data: Dictionary
var _finance_dirty := false
var _chaos_attempt: ChaosRun

func _init(path := DEFAULT_PATH) -> void:
	_path = path
	_load()

func snapshot() -> Dictionary:
	return _data.duplicate(true)

func can_play() -> bool:
	return load_status not in [LoadStatus.UNREADABLE, LoadStatus.NEWER_VERSION]

func funds() -> int:
	return int(_data.funds)

func set_leader_name(value: String) -> bool:
	var cleaned := value.strip_edges().substr(0, 24)
	if cleaned.is_empty():
		return false
	var next := snapshot()
	next.leader_name = cleaned
	return _commit(next)

func room_level(id: StringName) -> int:
	return int(_data.rooms.get(String(id), 0))

func room_capacity(id: StringName) -> int:
	var room: HeadquartersRoom = HEADQUARTERS.room(id)
	return room.capacity(room_level(id)) if room != null else 0

func unlocked_buffs() -> Array[StringName]:
	var result: Array[StringName] = []
	for room: HeadquartersRoom in HEADQUARTERS.rooms:
		if room.role == HeadquartersRoom.Role.RESEARCH:
			for id in room.unlocks(room_level(room.id)):
				result.append(StringName(id))
	return result

func records_chapters() -> PackedStringArray:
	return HEADQUARTERS.room(HeadquartersCatalog.RECORDS).unlocks(room_level(HeadquartersCatalog.RECORDS))

func records_enhancements() -> Array[StringName]:
	var result: Array[StringName] = []
	for chapter: String in _data.encyclopaedia.perfect_chapters:
		result.append(StringName(chapter))
	return result

func restoration_percent() -> int:
	return CampaignActivities.restoration_percent(_data.garden)

func garden_state() -> Dictionary:
	return _data.garden.duplicate(true)

func discovered_facts() -> Array:
	return _data.encyclopaedia.discovered_facts.duplicate()

func outreach_successes() -> int:
	return int(_data.outreach.successes)

func owns(id: StringName) -> bool:
	return String(id) in _data.owned

func deployable_level(id: StringName) -> int:
	return int(_data.deployable_levels.get(String(id), 1))

func room_quote(id: StringName) -> Dictionary:
	var room: HeadquartersRoom = HEADQUARTERS.room(id)
	if room == null:
		return {"error": "Unknown room."}
	var current := room_level(id)
	var target := current + 1
	var quote := _purchase_quote(current, target, room.cost(target))
	if current >= HeadquartersCatalog.MAX_LEVEL:
		quote.error = "Room is at its maximum level."
	elif target == room.gate_level:
		if room.gate == HeadquartersRoom.Gate.RESTORATION and restoration_percent() < room.gate_minimum:
			quote.error = "Requires %d%% restoration. Reached %d%%." % [room.gate_minimum, restoration_percent()]
		elif room.gate == HeadquartersRoom.Gate.OUTREACH and outreach_successes() < room.gate_minimum:
			quote.error = "Requires %d Best or Acceptable responses. Completed %d." % [room.gate_minimum, outreach_successes()]
	return quote

func purchase_room(id: StringName) -> String:
	var quote := room_quote(id)
	if not quote.error.is_empty():
		return quote.error
	var next := snapshot()
	next.rooms[String(id)] = quote.target
	return _purchase(next, quote.cost)

func level_quote(id: StringName, target: int) -> Dictionary:
	var spec := DeployableLevels.definition(id)
	if spec == null:
		return {"error": "Unknown deployable."}
	var current := deployable_level(id)
	var quote := _purchase_quote(current, target, maxi(0, DeployableLevels.cost(current, target)))
	if not owns(id):
		quote.error = "Recruit or unlock this unit first."
	elif not spec.is_ranger() and room_level(HeadquartersCatalog.MECHANICAL) == 0:
		quote.error = "Build Mechanical to purchase Facility levels."
	elif current == DeployableLevels.MAX_LEVEL:
		quote.error = "Unit is at its maximum level."
	elif target <= current or target > DeployableLevels.MAX_LEVEL:
		quote.error = "Choose a higher level up to 100."
	return quote

func purchase_levels(id: StringName, target: int) -> String:
	var quote := level_quote(id, target)
	if not quote.error.is_empty():
		return quote.error
	var next := snapshot()
	next.deployable_levels[String(id)] = target
	return _purchase(next, quote.cost)

func _purchase_quote(current: int, target: int, cost: int) -> Dictionary:
	var shortfall := maxi(0, cost - funds())
	var error := "Need %d more Funds." % shortfall if shortfall > 0 else ""
	return {"current": current, "target": target, "cost": cost, "balance": funds() - cost, "shortfall": shortfall, "error": error}

func _purchase(next: Dictionary, cost: int) -> String:
	FundsWallet.apply(next, -cost)
	return "" if _commit(next) else "Could not save the purchase. Check local storage."

func is_visible(operation: StoryOperation) -> bool:
	return room_level(HeadquartersCatalog.CONTROL) >= operation.min_control_level

func record_for(id: StringName) -> Dictionary:
	var record: Dictionary = _data.records.get(String(id), {})
	return record.duplicate()

func access_error(operation: StoryOperation) -> String:
	if not is_visible(operation):
		return "Requires Control Lv.%d" % operation.min_control_level
	if not operation.prerequisite.is_empty() and not record_for(operation.prerequisite).get("cleared", false):
		return "Clear %s first" % operation.prerequisite
	return ""

func begin_attempt(operation: StoryOperation) -> bool:
	if _chaos_attempt != null or not access_error(operation).is_empty():
		return false
	var id := String(operation.stage.stage_id)
	if not _data.pending_attempt.is_empty() and _data.pending_attempt != id:
		return false
	var next := snapshot()
	next.pending_attempt = id
	return _commit(next)

func abandon_attempt() -> bool:
	if _data.pending_attempt.is_empty():
		return true
	var next := snapshot()
	next.pending_attempt = ""
	return _commit(next)

func complete(operation: StoryOperation, perfect: bool) -> Dictionary:
	var id := String(operation.stage.stage_id)
	if _data.pending_attempt != id or not access_error(operation).is_empty():
		return {}
	var next := snapshot()
	var previous := record_for(operation.stage.stage_id)
	var first_clear: bool = not previous.get("cleared", false)
	var first_perfect: bool = perfect and not previous.get("perfect", false)
	var awards := {}
	var pending: Array[String] = []
	if first_clear:
		_add_award(operation.rewards, "first_clear_funds", awards, pending)
		if operation.rewards.get("story_completion_reward_present", false):
			_add_award(operation.rewards, "story_completion_funds", awards, pending)
	else:
		_add_award(operation.rewards, "replay_funds", awards, pending)
	if first_perfect:
		_add_award(operation.rewards, "first_perfect_funds", awards, pending)
	var total := 0
	for value: int in awards.values():
		total += value
	var credit := FundsWallet.apply(next, total)
	next.records[id] = {"cleared": true, "perfect": perfect or previous.get("perfect", false)}
	var unlocked: Array[StringName] = []
	for entry in operation.clear_unlock_ids:
		if String(entry) not in next.owned:
			next.owned.append(String(entry))
			unlocked.append(entry)
	next.pending_attempt = ""
	if not _commit(next):
		return {}
	return {
		"first_clear": first_clear, "first_perfect": first_perfect, "awards": awards,
		"pending_awards": pending, "unlocked": unlocked, "credited": credit.credited,
		"discarded": credit.discarded,
	}

func chaos_personal_best() -> int:
	return int(_data.chaos.personal_best)

func pending_chaos_configuration() -> Dictionary:
	return _data.chaos.pending_configuration.duplicate(true)

func begin_chaos(configuration: ChaosConfiguration, plan: ModifierResolution, selected_ids: Array[StringName], modifiers: Array[StringName]) -> ChaosRun:
	if not can_play() or _chaos_attempt != null or plan == null or not plan.can_start():
		return null
	var draft := configuration.save_data()
	draft.loadout = selected_ids.map(func(id: StringName) -> String: return String(id))
	draft.modifiers = modifiers.map(func(id: StringName) -> String: return String(id))
	var next := snapshot()
	next.chaos.pending_configuration = draft
	if not _commit(next):
		return null
	_chaos_attempt = ChaosRun.new(configuration.route_label(), plan)
	return _chaos_attempt

func abandon_chaos(run: ChaosRun) -> bool:
	if run != null and _chaos_attempt == run:
		if not close_chaos_configuration():
			return false
		_chaos_attempt = null
	return true

func close_chaos_configuration() -> bool:
	if _data.chaos.pending_configuration.is_empty():
		return true
	var next := snapshot()
	next.chaos.pending_configuration = {}
	return _commit(next)

func settle_chaos(run: ChaosRun) -> Dictionary:
	if run == null or _chaos_attempt != run or not run.finished:
		return {}
	var unlocked: Array[StringName] = []
	var previous := chaos_personal_best()
	var score := run.score.points()
	var funds_earned := ChaosScore.payout(score) if run.qualifies() else 0
	if funds_earned == 0:
		if not close_chaos_configuration():
			return {}
		_chaos_attempt = null
		return {"credited": 0, "discarded": 0, "unlocked": unlocked, "new_best": false}

	var next := snapshot()
	next.chaos.pending_configuration = {}
	next.chaos.personal_best = maxi(previous, score)
	for facility in ChaosScore.tier_facilities():
		var threshold := facility.chaos_threshold
		var tier := ChaosScore.tier_id(threshold)
		if score < threshold or tier in next.chaos.earned_thresholds:
			continue
		next.chaos.earned_thresholds.append(tier)
		if String(facility.id) not in next.owned:
			next.owned.append(String(facility.id))
			unlocked.append(facility.id)
	var credit := FundsWallet.apply(next, funds_earned)
	if not _commit(next):
		return {}
	_chaos_attempt = null
	return {
		"credited": credit.credited, "discarded": credit.discarded, "unlocked": unlocked,
		"new_best": next.chaos.personal_best > previous,
	}

func finance_rate() -> int:
	return HEADQUARTERS.room(HeadquartersCatalog.FINANCE).income(room_level(HeadquartersCatalog.FINANCE))

func finance_capacity() -> int:
	return HEADQUARTERS.room(HeadquartersCatalog.FINANCE).storage(room_level(HeadquartersCatalog.FINANCE))

func finance_stored() -> int:
	return floori(_data.finance)

func advance_finance(active_seconds: float) -> void:
	if not can_play() or not is_finite(active_seconds) or active_seconds <= 0.0:
		return
	var cap := finance_capacity()
	if _data.finance >= cap:
		return
	_data.finance = minf(cap, float(_data.finance) + finance_rate() * active_seconds)
	_finance_dirty = true

func flush_finance() -> bool:
	return not _finance_dirty or _commit(snapshot())

func finance_preview(amount := -1) -> Dictionary:
	var stored := finance_stored()
	return FundsWallet.quote(funds(), stored if amount < 0 else mini(amount, stored))

func claim_finance(amount := -1) -> bool:
	var stored := finance_stored()
	var available := stored if amount < 0 else mini(amount, stored)
	if available <= 0:
		return false
	var next := snapshot()
	FundsWallet.apply(next, available)
	next.finance = float(next.finance) - available
	return _commit(next)

func outreach_state() -> Dictionary:
	return _data.outreach.duplicate(true)

func open_outreach_batch(rotation: Array, questions: Array, choice_order: Dictionary, refreshed_at: int, bank_revision := 0) -> bool:
	if room_level(HeadquartersCatalog.OUTREACH) == 0 or refreshed_at <= 0:
		return false
	var last := int(_data.outreach.refreshed_at)
	if last > 0 and refreshed_at - last < CampaignActivities.OUTREACH_INTERVAL:
		return false
	var batch := {
		"rotation": rotation.duplicate(), "batch": questions.duplicate(),
		"choice_order": choice_order.duplicate(true), "responses": {},
		"refreshed_at": refreshed_at, "successes": outreach_successes(), "bank_revision": bank_revision,
	}
	if not CampaignActivities.valid_outreach(batch):
		return false
	var next := snapshot()
	next.outreach = batch
	return _commit(next)

func record_outreach_response(question: String, displayed_choice: int, grade: StringName) -> Dictionary:
	var level := room_level(HeadquartersCatalog.OUTREACH)
	var current: Dictionary = _data.outreach
	if level == 0 or question not in current.batch or current.responses.has(question) or displayed_choice < 0 or displayed_choice >= 4 or String(grade) not in CampaignActivities.GRADES:
		return {}
	var next := snapshot()
	var room: HeadquartersRoom = HEADQUARTERS.room(HeadquartersCatalog.OUTREACH)
	var settlement := FundsWallet.apply(next, room.outreach_change(level, grade))
	next.outreach.responses[question] = {
		"choice": int(current.choice_order[question][displayed_choice]), "grade": String(grade),
		"change": settlement.credited - settlement.deducted, "discarded": settlement.discarded,
	}
	if grade in [&"best", &"acceptable"]:
		next.outreach.successes = outreach_successes() + 1
	settlement.grade = String(grade)
	return settlement if _commit(next) else {}

func quiz_attempt() -> Dictionary:
	return _data.encyclopaedia.attempt.duplicate(true)

func begin_quiz(chapter: StringName, questions: Array, bank_revision := 0) -> bool:
	if not ProfileFile.whole_between(bank_revision, 0, ProfileFile.MAX_EXACT_INTEGER):
		return false
	if not _data.encyclopaedia.attempt.is_empty() or String(chapter) not in records_chapters() or not ProfileFile.unique_ids(questions) or questions.is_empty():
		return false
	var next := snapshot()
	next.encyclopaedia.attempt = {
		"chapter": String(chapter), "questions": questions.duplicate(), "answers": {},
		"time_left_ticks": CampaignActivities.QUIZ_TICKS, "bank_revision": bank_revision, "review_pending": false,
	}
	return _commit(next)

func save_quiz_timer(question: String, time_left_ticks: int) -> bool:
	var attempt: Dictionary = _data.encyclopaedia.attempt
	if not _is_current_question(attempt, question) or time_left_ticks < 0 or time_left_ticks > attempt.time_left_ticks:
		return false
	var next := snapshot()
	next.encyclopaedia.attempt.time_left_ticks = time_left_ticks
	return _commit(next)

func record_quiz_answer(question: String, choice: int, correct: bool, reward: int, review := {}) -> Dictionary:
	var records: Dictionary = _data.encyclopaedia
	var attempt: Dictionary = records.attempt
	if not _is_current_question(attempt, question) or choice < -1 or choice >= 4 or reward < 0:
		return {}
	var ticks: Variant = review.get("ticks", attempt.time_left_ticks)
	if not ProfileFile.whole_between(ticks, 0, int(attempt.time_left_ticks)) or (choice == -1) != (ticks == 0) or (choice == -1 and correct):
		return {}
	var discovered: Variant = review.get("fact_ids", [])
	if not ProfileFile.unique_ids(discovered):
		return {}
	var next := snapshot()
	var first_correct: bool = correct and question not in records.first_correct
	var settlement := FundsWallet.apply(next, reward if first_correct else 0)
	if first_correct:
		next.encyclopaedia.first_correct.append(question)
	if correct:
		for id: String in discovered:
			_discover_fact(next, id)
	next.encyclopaedia.attempt.answers[question] = {
		"choice": choice, "correct": correct, "credited": settlement.credited, "discarded": settlement.discarded,
	}
	next.encyclopaedia.attempt.review_pending = not review.is_empty()
	next.encyclopaedia.attempt.time_left_ticks = CampaignActivities.QUIZ_TICKS
	settlement.first_correct = first_correct
	return settlement if _commit(next) else {}

func finish_quiz(reward: int) -> Dictionary:
	var attempt: Dictionary = _data.encyclopaedia.attempt
	if attempt.is_empty() or attempt.answers.size() != attempt.questions.size() or reward < 0:
		return {}
	var next := snapshot()
	var perfect: bool = attempt.answers.values().all(func(answer: Dictionary) -> bool: return answer.correct)
	var first_perfect: bool = perfect and attempt.chapter not in next.encyclopaedia.perfect_chapters
	if first_perfect:
		next.encyclopaedia.perfect_chapters.append(attempt.chapter)
	var settlement := FundsWallet.apply(next, reward if first_perfect else 0)
	next.encyclopaedia.attempt = {}
	settlement.first_perfect = first_perfect
	settlement.correct = attempt.answers.values().filter(func(answer: Dictionary) -> bool: return answer.correct).size()
	settlement.total = attempt.questions.size()
	settlement.chapter = attempt.chapter
	return settlement if _commit(next) else {}

func continue_quiz() -> bool:
	var attempt: Dictionary = _data.encyclopaedia.attempt
	if not attempt.get("review_pending", false) or attempt.answers.size() >= attempt.questions.size():
		return false
	var next := snapshot()
	next.encyclopaedia.attempt.review_pending = false
	return _commit(next)

func close_quiz() -> bool:
	if _data.encyclopaedia.attempt.is_empty():
		return true
	var next := snapshot()
	next.encyclopaedia.attempt = {}
	return _commit(next)

func _is_current_question(attempt: Dictionary, question: String) -> bool:
	return (
		not attempt.is_empty() and not attempt.get("review_pending", false)
		and attempt.answers.size() < attempt.questions.size() and attempt.questions[attempt.answers.size()] == question
	)

func plant_garden(slot: int, species: String, now: int) -> String:
	var id := RestorationRules.plot_id(slot)
	if slot < 0 or slot >= room_capacity(HeadquartersCatalog.ECOLOGY) or not RestorationRules.SPECIES.has(species) or not _valid_garden_time(now):
		return ""
	if _data.garden.plots.has(id):
		return ""
	var next := snapshot()
	var garden: Dictionary = next.garden
	var used: Array = garden.settled_awards.duplicate()
	for plot: Dictionary in garden.plots.values():
		used.append(plot.cycle_id)
	var serial := int(garden.get("cycle_serial", 0))
	var cycle := "garden_cycle.%d" % (serial + 1)
	while cycle in used:
		serial += 1
		cycle = "garden_cycle.%d" % (serial + 1)
	if serial >= ProfileFile.MAX_EXACT_INTEGER:
		return ""
	garden.cycle_serial = serial + 1
	garden.plots[id] = {"cycle_id": cycle, "species": species, "planted_at": now, "watered_at": 0, "reached_seconds": 0}
	return cycle if _commit(next) else ""

func water_garden(slot: int, cycle: String, now: int) -> bool:
	var id := RestorationRules.plot_id(slot)
	var plot: Dictionary = _data.garden.plots.get(id, {})
	if not _valid_garden_time(now) or plot.get("cycle_id") != cycle or not RestorationRules.needs_water(plot, now):
		return false
	var next := snapshot()
	next.garden.plots[id].watered_at = now
	next.garden.plots[id].reached_seconds = RestorationRules.midpoint(plot.species)
	return _commit(next)

func collect_garden(slot: int, cycle: String, now: int) -> Dictionary:
	var id := RestorationRules.plot_id(slot)
	var plot: Dictionary = _data.garden.plots.get(id, {})
	if not _valid_garden_time(now) or plot.get("cycle_id") != cycle or cycle in _data.garden.settled_awards:
		return {}
	if RestorationRules.stage(plot, now) != RestorationRules.Stage.MATURE:
		return {}
	var next := snapshot()
	var garden: Dictionary = next.garden
	var species: String = plot.species
	var before := restoration_percent()
	var first: bool = species not in garden.collected_species
	if first:
		garden.collected_species.append(species)
	elif garden.collected_species.size() == RestorationRules.SPECIES.size():
		garden.extra_collection = true
	var species_fact: String = RestorationRules.SPECIES[species].fact
	if first:
		_discover_fact(next, species_fact)
	var visitor: bool = first and garden.collected_species.size() == RestorationRules.SPECIES.size() and not garden.nest_box_seen
	if visitor:
		garden.nest_box_seen = true
		_discover_fact(next, RestorationRules.NEST_FACT)
	var milestone := CampaignActivities.restoration_percent(garden)
	var milestone_id := "restoration_milestone.%d" % milestone
	var milestone_funds := 0
	if milestone > before and milestone_id not in garden.milestones:
		garden.milestones.append(milestone_id)
		milestone_funds = RestorationRules.MILESTONES[milestone]
	garden.plots.erase(id)
	garden.scenery[id] = species
	garden.settled_awards.append(cycle)
	var cycle_funds: int = RestorationRules.SPECIES[species].funds
	var settlement := FundsWallet.apply(next, cycle_funds + milestone_funds)
	settlement.merge({
		"species": species, "cycle_funds": cycle_funds, "milestone_funds": milestone_funds, "milestone": milestone,
		"fact": species_fact if first else "", "visitor": visitor,
	})
	return settlement if _commit(next) else {}

func checkpoint_garden(now: int) -> bool:
	if not _valid_garden_time(now):
		return false
	var next := snapshot()
	var changed := false
	for plot: Dictionary in next.garden.plots.values():
		var elapsed := RestorationRules.elapsed(plot, now)
		if elapsed <= int(plot.get("reached_seconds", 0)):
			continue
		if not plot.has("reached_seconds") and plot.watered_at > 0:
			var early_water_end := int(plot.planted_at) + RestorationRules.midpoint(plot.species)
			if plot.watered_at < early_water_end:
				if now < early_water_end:
					continue
				plot.watered_at = early_water_end
		plot.reached_seconds = elapsed
		changed = true
	return not changed or _commit(next)

func visit_garden_guide() -> bool:
	if room_capacity(HeadquartersCatalog.ECOLOGY) == 0:
		return false
	var next := snapshot()
	return not _discover_fact(next, RestorationRules.GUIDE_FACT) or _commit(next)

static func _discover_fact(profile: Dictionary, id: String) -> bool:
	if id in profile.encyclopaedia.discovered_facts:
		return false
	profile.encyclopaedia.discovered_facts.append(id)
	return true

static func _valid_garden_time(now: int) -> bool:
	return now >= 1 and now <= CampaignActivities.LAST_TIMESTAMP

func reset_profile() -> bool:
	if not _reset_confirmed() and not ProfileFile.replace(_path + ".reset", {"confirmed": true}, false):
		return false
	var empty := CampaignSave.fresh()
	if not ProfileFile.finish_reset(_path, empty):
		load_status = LoadStatus.UNREADABLE
		load_notice = "Could not finish the confirmed reset. Check local storage and retry."
		return false
	_data = empty
	_chaos_attempt = null
	_finance_dirty = false
	load_status = LoadStatus.READY
	load_notice = ""
	return true

func _load() -> void:
	_data = CampaignSave.fresh()
	if _reset_confirmed():
		reset_profile()
		return
	var primary := ProfileFile.read(_path)
	var backup := ProfileFile.read(_path + ".bak")
	var resolved := CampaignSave.load_data(primary)
	if not resolved.is_empty():
		_data = resolved
		load_status = LoadStatus.READY
		if primary.version != CampaignSave.VERSION:
			load_status = LoadStatus.MIGRATED
			load_notice = "Campaign save upgraded to the Headquarters profile."
			if not _commit(_data):
				load_notice = "Campaign save loaded. Saving the upgrade needs writable storage."
		return
	if _newer(primary):
		_block_newer_save()
		return
	resolved = CampaignSave.load_data(backup)
	if not resolved.is_empty():
		_data = resolved
		load_status = LoadStatus.RECOVERED
		load_notice = "Loaded the last valid backup."
		if not _commit(_data):
			load_notice = "Loaded the last valid backup. Check local storage to save changes."
		return
	if _newer(backup):
		_block_newer_save()
	elif FileAccess.file_exists(_path) or FileAccess.file_exists(_path + ".bak"):
		load_status = LoadStatus.UNREADABLE
		load_notice = "Neither local save copy could be read. Open Settings to review recovery options."

func _block_newer_save() -> void:
	load_status = LoadStatus.NEWER_VERSION
	load_notice = "This save needs a newer version of Kenyalang Rangers."

func _reset_confirmed() -> bool:
	return ProfileFile.read(_path + ".reset").get("confirmed") == true

func _commit(next: Dictionary) -> bool:
	if not can_play():
		return false
	var primary_is_valid := not CampaignSave.load_data(ProfileFile.read(_path)).is_empty()
	if not ProfileFile.replace(_path, next, primary_is_valid):
		return false
	_data = next
	_finance_dirty = false
	return true

static func _newer(raw: Dictionary) -> bool:
	return ProfileFile.whole_between(raw.get("version"), CampaignSave.VERSION + 1, CampaignSave.MAX_EXACT_INTEGER)

static func _add_award(rewards: Dictionary, key: String, awards: Dictionary, pending: Array[String]) -> void:
	var amount: Variant = rewards.get(key)
	if ProfileFile.whole_between(amount, 0, CampaignSave.MAX_EXACT_INTEGER):
		awards[key] = int(amount)
	else:
		pending.append(key)
