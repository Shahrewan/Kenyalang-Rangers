class_name RecordsQuiz
extends RefCounted

signal view_changed

const TICKS_PER_SECOND := 60

var time_left_ticks := CampaignActivities.QUIZ_TICKS
var paused := false
var notice := ""
var result := {}
var _profile: CampaignProgress
var _catalog: EducationCatalog
var _attempt: Dictionary
var _questions: Dictionary[String, Dictionary] = {}
var _saved_ticks: int
var _fraction := 0.0

func _init(profile: CampaignProgress, catalog: EducationCatalog) -> void:
	_profile = profile
	_catalog = catalog
	_load_attempt()
	paused = not question().is_empty() and not reviewing()

func begin(chapter_id: String) -> bool:
	var chapter: Dictionary = _catalog.chapters.get(chapter_id, {})
	if chapter.is_empty():
		return false
	var ids: Array = chapter.questions.map(func(item: Dictionary) -> String: return item.id)
	if not _profile.begin_quiz(StringName(chapter_id), ids, _catalog.records_revision):
		return false
	_load_attempt()
	paused = false
	return true

func chapter_id() -> String:
	return _attempt.get("chapter", "")

func chapter() -> Dictionary:
	return _catalog.chapters.get(chapter_id(), {})

func can_resume() -> bool:
	return not _questions.is_empty()

func question_number() -> int:
	return _attempt.answers.size() if reviewing() else _attempt.answers.size() + 1

func question_count() -> int:
	return _questions.size()

func reviewing() -> bool:
	return _attempt.get("review_pending", false)

func question() -> Dictionary:
	if not can_resume():
		return {}
	var number := question_number()
	return _questions[_attempt.questions[number - 1]] if number <= question_count() else {}

func feedback() -> Dictionary:
	return _attempt.answers[question().id] if reviewing() and can_resume() else {}

func seconds_left() -> int:
	return ceili(float(time_left_ticks) / TICKS_PER_SECOND)

func advance(delta: float) -> void:
	if paused or reviewing() or question().is_empty() or delta <= 0.0:
		return
	_fraction += delta * TICKS_PER_SECOND
	var elapsed := floori(_fraction)
	_fraction -= elapsed
	time_left_ticks = maxi(0, time_left_ticks - elapsed)
	if time_left_ticks == 0:
		_record(-1)
	elif _saved_ticks - time_left_ticks >= TICKS_PER_SECOND and not checkpoint():
		view_changed.emit()

func checkpoint() -> bool:
	if reviewing() or question().is_empty() or _saved_ticks == time_left_ticks:
		return true
	if not _profile.save_quiz_timer(question().id, time_left_ticks):
		paused = true
		notice = "Could not save the timer. Check local storage and resume."
		return false
	_saved_ticks = time_left_ticks
	return true

func pause() -> void:
	if not reviewing() and not question().is_empty():
		paused = true
		checkpoint()
		view_changed.emit()

func resume() -> void:
	if paused and checkpoint():
		paused = false
		notice = ""
		if time_left_ticks == 0:
			_record(-1)
			return
	view_changed.emit()

func answer(index: int) -> bool:
	if paused or reviewing() or question().is_empty() or time_left_ticks <= 0 or index < 0 or index > 3:
		return false
	return _record(index)

func continue_after_feedback() -> bool:
	if not reviewing() or not can_resume():
		return false
	if question_number() == question_count():
		var bonus: Variant = chapter().final_perfect_chapter_funds
		result = _profile.finish_quiz(0 if bonus == null else int(bonus))
		if result.is_empty():
			notice = "Could not save the chapter result. Check local storage and retry."
			view_changed.emit()
			return false
		result.pending_bonus = bonus == null and result.correct == result.total
	elif not _profile.continue_quiz():
		notice = "Could not save your place. Check local storage and retry."
		view_changed.emit()
		return false
	_load_attempt()
	notice = ""
	view_changed.emit()
	return true

func _record(index: int) -> bool:
	var current := question()
	var correct: bool = index >= 0 and current.choices[index].id == current.correct_choice_id
	var receipt := _profile.record_quiz_answer(current.id, index, correct, _catalog.first_correct_funds, {
		"ticks": time_left_ticks, "fact_ids": current.fact_ids,
	})
	if receipt.is_empty():
		paused = true
		notice = "Could not save the answer. Check local storage and resume."
	else:
		_load_attempt()
		notice = ""
	view_changed.emit()
	return not receipt.is_empty()

func _load_attempt() -> void:
	_attempt = _profile.quiz_attempt()
	time_left_ticks = int(_attempt.get("time_left_ticks", CampaignActivities.QUIZ_TICKS))
	_saved_ticks = time_left_ticks
	_fraction = 0.0
	_questions.clear()
	var active_chapter := chapter()
	if active_chapter.is_empty() or int(_attempt.get("bank_revision", 0)) != _catalog.records_revision:
		return
	var order: Array = active_chapter.questions.map(func(item: Dictionary) -> String: return item.id)
	if order != _attempt.questions or not chapter_id() in _profile.records_chapters():
		return
	for item: Dictionary in active_chapter.questions:
		_questions[item.id] = item
