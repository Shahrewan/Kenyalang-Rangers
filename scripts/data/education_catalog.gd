class_name EducationCatalog
extends RefCounted

const DIRECTORY := "res://data/education"
const CHAPTERS := {
	"records_chapter.scout_sniper": ["Scout Sniper", "Steady Aim and Focus"],
	"records_chapter.patrolman": ["Patrolman", "Reinforced Patrol"],
	"records_chapter.combat_medic": ["Combat Medic", "Emergency Treatment"],
	"records_chapter.woods_tracker": ["Woods Tracker", "Improved HP and reduced redeployment cooldown"],
}

var outreach_revision := 0
var records_revision := 0
var first_correct_funds := 0
var outreach: Dictionary[String, Dictionary] = {}
var chapters: Dictionary[String, Dictionary] = {}
var facts: Dictionary[String, Dictionary] = {}
var sources: Dictionary[String, Dictionary] = {}

static func load_installed(directory := DIRECTORY) -> EducationCatalog:
	return from_banks(
		ProfileFile.read(directory.path_join("outreach.json")),
		ProfileFile.read(directory.path_join("records.json")),
		ProfileFile.read(directory.path_join("references.json")),
	)

static func from_banks(pr_bank: Dictionary, records_bank: Dictionary, references: Dictionary) -> EducationCatalog:
	var catalog := EducationCatalog.new()
	if not catalog._read_references(references):
		return catalog
	catalog._read_outreach(pr_bank)
	catalog._read_records(records_bank)
	return catalog

func source_lines(ids: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for id: String in ids:
		var source: Dictionary = sources[id]
		result.append("%s · %s\n%s" % [source.publisher, source.title, source.url])
	return result

func _read_references(bank: Dictionary) -> bool:
	if not _approved(bank, "references"):
		return false
	var source_rows := _indexed(bank.get("sources"))
	var fact_rows := _indexed(bank.get("facts"))
	if source_rows.is_empty() or (fact_rows.is_empty() and bank.get("facts") != []):
		return false
	for source: Dictionary in source_rows.values():
		if not _has_text(source, ["publisher", "title", "url"]):
			return false
		if not source.url.begins_with("https://") and not source.url.begins_with("http://"):
			return false
	for fact: Dictionary in fact_rows.values():
		if not _has_text(fact, ["title", "text"]) or not _known_links(fact.get("source_ids"), source_rows):
			return false
	sources = source_rows
	facts = fact_rows
	return true

func _read_outreach(bank: Dictionary) -> void:
	if not _approved(bank, "outreach") or bank.get("refresh_hours") != 20 or bank.get("max_questions_per_batch") != 5 or bank.get("shuffle_choices") != true:
		return
	var rows := _indexed(bank.get("questions"))
	if rows.size() != 20:
		return
	var prompts := {}
	for question: Dictionary in rows.values():
		if not _valid_question(question):
			return
		var prompt: String = question.prompt.strip_edges().to_lower()
		if prompts.has(prompt):
			return
		prompts[prompt] = true
		var grades: Array = []
		for choice: Dictionary in question.choices:
			var grade: Variant = choice.get("grade")
			if not grade in CampaignActivities.GRADES or grade in grades or not _has_text(choice, ["justification"]):
				return
			grades.append(grade)
	outreach = rows
	outreach_revision = int(bank.content_revision)

func _read_records(bank: Dictionary) -> void:
	if not _approved(bank, "records") or bank.get("question_timer_seconds") != 15 or not _funds_value(bank.get("final_first_correct_funds")):
		return
	var rows := _indexed(bank.get("chapters"))
	if rows.size() != CHAPTERS.size():
		return
	var pending_bonus: bool = bank.get("payout_status") == "prototype_gdd_question_rewards"
	var seen := {}
	var index := 0
	for id: String in CHAPTERS:
		var chapter: Dictionary = rows.get(id, {})
		if chapter.get("records_room_level") != index + 2 or chapter.get("ranger_id") != "ranger." + id.get_slice(".", 1):
			return
		index += 1
		var bonus: Variant = chapter.get("final_perfect_chapter_funds")
		if not _has_text(chapter, ["topic", "perfect_clear_enhancement"]):
			return
		if not _funds_value(bonus) and not (pending_bonus and chapter.has("final_perfect_chapter_funds") and bonus == null):
			return
		var questions := _indexed(chapter.get("questions"))
		if questions.is_empty():
			return
		for question: Dictionary in questions.values():
			if seen.has(question.id) or not _valid_question(question) or not _has_text(question, ["explanation"]):
				return
			if not _known_links(question.get("fact_ids"), facts, true):
				return
			if not question.choices.any(func(choice: Dictionary) -> bool: return choice.id == question.get("correct_choice_id")):
				return
			seen[question.id] = true
	chapters = rows
	records_revision = int(bank.content_revision)
	first_correct_funds = int(bank.final_first_correct_funds)

func _valid_question(question: Dictionary) -> bool:
	var choices := _indexed(question.get("choices"))
	if choices.size() != 4 or not _has_text(question, ["prompt"]) or not _known_links(question.get("source_ids"), sources):
		return false
	var labels: Array[String] = []
	for choice: Dictionary in choices.values():
		if not _has_text(choice, ["text"]) or not choice.id.begins_with(question.id + "."):
			return false
		var label: String = choice.text.strip_edges().to_lower()
		if label in labels:
			return false
		labels.append(label)
	return true

static func _indexed(rows: Variant) -> Dictionary[String, Dictionary]:
	var result: Dictionary[String, Dictionary] = {}
	if not rows is Array:
		return result
	for row: Variant in rows:
		if not row is Dictionary or not _has_text(row, ["id"]) or result.has(row.id):
			result.clear()
			return result
		result[row.id] = row.duplicate(true)
	return result

static func _approved(bank: Dictionary, kind: String) -> bool:
	return (
		bank.get("kind") == kind and bank.get("schema_version") == 1 and bank.get("editorial_status") == "approved"
		and ProfileFile.whole_between(bank.get("content_revision"), 1, ProfileFile.MAX_EXACT_INTEGER)
	)

static func _known_links(ids: Variant, index: Dictionary, allow_empty := false) -> bool:
	return ProfileFile.unique_ids(ids) and (allow_empty or not ids.is_empty()) and ids.all(func(id: String) -> bool: return index.has(id))

static func _has_text(row: Dictionary, keys: Array) -> bool:
	for key: String in keys:
		var value: Variant = row.get(key)
		if not value is String or value.strip_edges().is_empty():
			return false
	return true

static func _funds_value(value: Variant) -> bool:
	return ProfileFile.whole_between(value, 0, ProfileFile.MAX_EXACT_INTEGER)
