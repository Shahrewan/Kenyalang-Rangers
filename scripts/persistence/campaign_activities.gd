class_name CampaignActivities
extends RefCounted

const GRADES := ["best", "acceptable", "poor", "harmful"]
const OUTREACH_INTERVAL := 20 * 60 * 60
const QUIZ_TICKS := 15 * 60
const LAST_TIMESTAMP := 253402300799
const SPECIES := ["species.strangler_fig", "species.belian", "species.red_meranti", "species.mengaris"]

static func new_outreach() -> Dictionary:
	return {"rotation": [], "batch": [], "choice_order": {}, "responses": {}, "refreshed_at": 0, "successes": 0}

static func new_encyclopaedia() -> Dictionary:
	return {"first_correct": [], "perfect_chapters": [], "discovered_facts": [], "attempt": {}}

static func new_garden() -> Dictionary:
	return {
		"plots": {}, "scenery": {}, "collected_species": [], "extra_collection": false,
		"milestones": [], "nest_box_seen": false, "settled_awards": [],
	}

static func restoration_percent(garden: Dictionary) -> int:
	return garden.collected_species.size() * 20 + (20 if garden.extra_collection else 0)

static func valid_outreach(state: Variant) -> bool:
	if not state is Dictionary or not ProfileFile.unique_ids(state.get("rotation")) or not ProfileFile.unique_ids(state.get("batch")):
		return false
	if not ProfileFile.whole_between(state.get("refreshed_at"), 0, LAST_TIMESTAMP) or not ProfileFile.whole_between(state.get("successes"), 0, LAST_TIMESTAMP):
		return false
	if not state.get("choice_order") is Dictionary or not state.get("responses") is Dictionary:
		return false
	if state.refreshed_at == 0:
		return state.rotation.is_empty() and state.batch.is_empty() and state.choice_order.is_empty() and state.responses.is_empty() and state.successes == 0
	if state.rotation.size() != 20 or state.batch.is_empty() or state.batch.size() > 5 or state.choice_order.size() != state.batch.size():
		return false
	for id: String in state.batch:
		var order: Variant = state.choice_order.get(id)
		if not id in state.rotation or not order is Array or order.size() != 4:
			return false
		var positions := {}
		for value in order:
			if not ProfileFile.whole_between(value, 0, 3):
				return false
			positions[int(value)] = true
		if positions.size() != 4:
			return false
	for id: String in state.responses:
		var response: Variant = state.responses[id]
		if not id in state.batch or not response is Dictionary or not response.get("grade") in GRADES:
			return false
		if not ProfileFile.whole_between(response.get("choice"), 0, 3):
			return false
		if not ProfileFile.whole_between(response.get("change"), -FundsWallet.CAP, FundsWallet.CAP):
			return false
	return true

static func valid_encyclopaedia(state: Variant, available_chapters: PackedStringArray) -> bool:
	if not state is Dictionary or not ProfileFile.unique_ids(state.get("first_correct")) or not ProfileFile.unique_ids(state.get("perfect_chapters")) or not ProfileFile.unique_ids(state.get("discovered_facts")):
		return false
	for id: String in state.perfect_chapters:
		if not id in available_chapters:
			return false
	var attempt: Variant = state.get("attempt")
	if not attempt is Dictionary or (not attempt.is_empty() and not attempt.get("chapter") in available_chapters):
		return false
	if attempt.is_empty():
		return true
	if not ProfileFile.unique_ids(attempt.get("questions")) or attempt.questions.is_empty():
		return false
	if not ProfileFile.whole_between(attempt.get("time_left_ticks"), 0, QUIZ_TICKS) or not attempt.get("answers") is Dictionary:
		return false
	if attempt.answers.size() > attempt.questions.size():
		return false
	for i in attempt.answers.size():
		var answer: Variant = attempt.answers.get(attempt.questions[i])
		if not answer is Dictionary or not ProfileFile.whole_between(answer.get("choice"), -1, 3) or not answer.get("correct") is bool:
			return false
		if answer.choice < 0 and answer.correct:
			return false
	return true

static func valid_garden(state: Variant, capacity: int) -> bool:
	if not state is Dictionary or not state.get("plots") is Dictionary or not state.get("scenery") is Dictionary:
		return false
	if not ProfileFile.unique_ids(state.get("collected_species")) or not ProfileFile.unique_ids(state.get("milestones")) or not ProfileFile.unique_ids(state.get("settled_awards")):
		return false
	if not state.get("extra_collection") is bool or not state.get("nest_box_seen") is bool:
		return false
	for id: String in state.collected_species:
		if not id in SPECIES:
			return false
	if (state.extra_collection or state.nest_box_seen) and state.collected_species.size() < SPECIES.size():
		return false
	for id: String in state.milestones:
		if not id in ["restoration_milestone.20", "restoration_milestone.40", "restoration_milestone.60", "restoration_milestone.80", "restoration_milestone.100"]:
			return false
		if int(id.get_slice(".", 1)) > restoration_percent(state):
			return false
	var plot_ids := PackedStringArray()
	for index in range(1, capacity + 1):
		plot_ids.append("garden_plot.%02d" % index)
	var active_cycles := {}
	for id: String in state.plots:
		var plot: Variant = state.plots[id]
		if not id in plot_ids or not plot is Dictionary or not plot.get("species") in SPECIES:
			return false
		var cycle: Variant = plot.get("cycle_id")
		if not cycle is String or cycle.is_empty() or active_cycles.has(cycle):
			return false
		active_cycles[cycle] = true
		if not ProfileFile.whole_between(plot.get("planted_at"), 1, LAST_TIMESTAMP) or not ProfileFile.whole_between(plot.get("watered_at"), 0, LAST_TIMESTAMP):
			return false
		if plot.watered_at > 0 and plot.watered_at < plot.planted_at:
			return false
	for id: String in state.scenery:
		if not id in plot_ids or not state.scenery[id] in SPECIES:
			return false
	return true
