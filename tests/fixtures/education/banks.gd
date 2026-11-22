extends RefCounted

const SOURCE := "source.c19_fixture"
const FACT := "fact.c19_fixture"

static func payload() -> Dictionary:
	var references := bank("references")
	references.sources = [{
		"id": SOURCE, "publisher": "QA fixture", "title": "Synthetic source",
		"url": "https://example.invalid/c19-fixture",
	}]
	references.facts = [{"id": FACT, "title": "Synthetic fact", "text": "This text belongs only to the test fixture.", "source_ids": [SOURCE]}]
	var pr := bank("outreach")
	pr.refresh_hours = 20
	pr.max_questions_per_batch = 5
	pr.shuffle_choices = true
	pr.questions = []
	for index in 20:
		var prompt := question("outreach.qa_%02d" % index)
		for option in 4:
			prompt.choices[option].grade = CampaignActivities.GRADES[option]
			prompt.choices[option].justification = "Synthetic %s feedback." % CampaignActivities.GRADES[option]
		pr.questions.append(prompt)
	var records := bank("records")
	records.question_timer_seconds = 15
	records.final_first_correct_funds = 30000
	records.chapters = []
	var level := 2
	for chapter_id: String in EducationCatalog.CHAPTERS:
		var ranger := chapter_id.get_slice(".", 1)
		var questions := []
		for number in 2:
			var prompt := question("records.qa_%s_%d" % [ranger, number + 1])
			prompt.correct_choice_id = prompt.choices[2].id
			prompt.explanation = "Marker three is the correct fixture response."
			prompt.fact_ids = [FACT]
			questions.append(prompt)
		records.chapters.append({
			"id": chapter_id, "records_room_level": level, "ranger_id": "ranger." + ranger,
			"topic": "Fixture chapter %d" % level, "perfect_clear_enhancement": EducationCatalog.CHAPTERS[chapter_id][1],
			"final_perfect_chapter_funds": 70000, "questions": questions,
		})
		level += 1
	return {"outreach": pr, "records": records, "references": references}

static func catalog() -> EducationCatalog:
	var data := payload()
	return EducationCatalog.from_banks(data.outreach, data.records, data.references)

static func bank(kind: String) -> Dictionary:
	return {"kind": kind, "schema_version": 1, "content_revision": 1, "editorial_status": "approved"}

static func question(id: String) -> Dictionary:
	var choices := []
	for option in 4:
		choices.append({"id": "%s.option_%d" % [id, option], "text": "Fixture marker %d" % (option + 1)})
	return {"id": id, "prompt": "Synthetic prompt %s" % id, "choices": choices, "source_ids": [SOURCE]}
