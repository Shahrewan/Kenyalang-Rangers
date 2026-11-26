class_name RecordsQuizPage
extends VBoxContainer

signal sound_requested(id: String)
signal back_requested

var progress: CampaignProgress
var catalog: EducationCatalog
var _heard_result := false
var _heard_question := 0
var quiz: RecordsQuiz
var _clock: Label
var _time_bar: ProgressBar
var _pause: Button
var _wallet: Label
var _context: VBoxContainer
var _body: VBoxContainer
var _footer: HBoxContainer
var _notice: Label

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var back := StoryUI.header(self, quiz.chapter().topic, request_back, "Funds")
	_wallet = back.get_parent().get_node("FundsSummary")
	var status := StoryUI.row(self)
	_clock = StoryUI.label("", 21, StoryUI.AMBER)
	_clock.name = "QuizTimer"
	_clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(_clock)
	_pause = EducationUI.large_action(StoryUI.action("Pause quiz"))
	_pause.name = "PauseQuiz"
	_pause.custom_minimum_size.x = 176
	_pause.pressed.connect(_toggle_pause)
	status.add_child(_pause)
	_time_bar = ProgressBar.new()
	_time_bar.name = "QuizTimeRemaining"
	_time_bar.show_percentage = false
	_time_bar.custom_minimum_size.y = 7.0
	_time_bar.max_value = CampaignActivities.QUIZ_TICKS
	_time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_time_bar)
	var columns := EducationUI.activity_body(self)
	_context = columns[0]
	_body = columns[1]
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	_notice.name = "QuizNotice"
	add_child(_notice)
	_footer = StoryUI.row(self)
	if quiz.reviewing():
		_heard_question = quiz.question_number()
	quiz.view_changed.connect(_render)
	_render()

func request_back() -> void:
	quiz.checkpoint()
	back_requested.emit()

func _toggle_pause() -> void:
	if quiz.paused:
		quiz.resume()
	else:
		quiz.pause()

func _process(delta: float) -> void:
	quiz.advance(delta)
	_update_clock()

func _exit_tree() -> void:
	if quiz != null:
		quiz.checkpoint()

func _notification(what: int) -> void:
	if is_node_ready() and (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT):
		quiz.pause()

func _update_clock() -> void:
	_time_bar.visible = quiz.result.is_empty() and quiz.can_resume() and not quiz.reviewing()
	_time_bar.value = quiz.time_left_ticks
	if quiz.result.is_empty() and quiz.can_resume():
		_clock.text = "Question %d of %d · %d s" % [quiz.question_number(), quiz.question_count(), quiz.seconds_left()]
		if quiz.reviewing():
			_clock.text = "Question %d of %d" % [quiz.question_number(), quiz.question_count()]
	else:
		_clock.text = ""

func _render() -> void:
	EducationUI.clear(_body)
	EducationUI.clear(_context)
	EducationUI.clear(_footer)
	_body.get_parent().scroll_vertical = 0
	_context.get_parent().scroll_vertical = 0
	_context.get_parent().visible = not quiz.paused and quiz.result.is_empty()
	_footer.visible = quiz.reviewing() or not quiz.result.is_empty()
	_wallet.text = "%s Funds" % StoryUI.funds(progress.funds())
	_notice.text = quiz.notice
	_notice.visible = not quiz.notice.is_empty()
	_pause.visible = quiz.result.is_empty() and quiz.can_resume() and not quiz.reviewing()
	_pause.text = "Resume quiz" if quiz.paused else "Pause quiz"
	_update_clock()
	if not quiz.result.is_empty():
		_result()
	elif quiz.paused:
		StoryUI.panel(_body).add_child(StoryUI.label("Quiz paused", 26))
	elif quiz.reviewing():
		_review()
	else:
		_ask()
	StoryUI.size_buttons(self)

func _ask() -> void:
	var item := quiz.question()
	var prompt := StoryUI.label(item.prompt, 25)
	prompt.name = "QuizPrompt"
	var context := StoryUI.panel(_context)
	var chapter_id := quiz.chapter_id().get_slice(".", 1)
	context.add_child(StoryUI.artwork(RecordsArchivePage.CHAPTER_ART.get(chapter_id), Vector2(120, 110)))
	context.add_child(prompt)
	for index in item.choices.size():
		_body.add_child(EducationUI.answer_button(item.choices[index].text, "QuizAnswer%d" % index, _answer.bind(index)))

func _answer(index: int) -> void:
	quiz.answer(index)

func _review() -> void:
	var item := quiz.question()
	var outcome := quiz.feedback()
	if _heard_question != quiz.question_number():
		_heard_question = quiz.question_number()
		var cue := "records_time_expired" if outcome.choice < 0 else ("records_correct" if outcome.correct else "records_incorrect")
		sound_requested.emit(cue)
	var card := StoryUI.panel(_body, true)
	var state := "Time expired" if outcome.choice < 0 else "Correct" if outcome.correct else "Incorrect"
	var heading := StoryUI.label(state, 26, StoryUI.INK)
	heading.name = "QuizFeedback"
	card.add_child(heading)
	StoryUI.panel(_context).add_child(StoryUI.label(item.prompt, 24))
	for choice: Dictionary in item.choices:
		if choice.id == item.correct_choice_id:
			card.add_child(StoryUI.label("Correct answer · " + choice.text, 20, StoryUI.INK))
			break
	card.add_child(StoryUI.label(item.explanation, 21, StoryUI.INK))
	var funds := StoryUI.label(EducationUI.receipt(int(outcome.get("credited", 0)), int(outcome.get("discarded", 0))), 19, StoryUI.INK)
	funds.name = "QuizQuestionFunds"
	card.add_child(funds)
	EducationUI.credit_sources(card, catalog, item.source_ids, StoryUI.INK)
	var next := EducationUI.large_action(StoryUI.action("Finish chapter" if quiz.question_number() == quiz.question_count() else "Next question", true))
	next.name = "ContinueQuiz"
	next.pressed.connect(func() -> void: quiz.continue_after_feedback())
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(next)

func _result() -> void:
	var outcome := quiz.result
	if not _heard_result:
		_heard_result = true
		sound_requested.emit("records_first_perfect" if outcome.first_perfect else "records_chapter_complete")
	var card := StoryUI.panel(_body, true)
	var heading := StoryUI.label("Perfect chapter" if outcome.correct == outcome.total else "Chapter complete", 28, StoryUI.INK)
	heading.name = "QuizResult"
	card.add_child(heading)
	card.add_child(StoryUI.label("%d of %d correct" % [outcome.correct, outcome.total], 22, StoryUI.INK))
	var amount := "Perfect chapter bonus pending" if outcome.get("pending_bonus", false) else EducationUI.receipt(int(outcome.credited), int(outcome.discarded))
	var funds := StoryUI.label(amount, 21, StoryUI.INK)
	funds.name = "QuizChapterFunds"
	card.add_child(funds)
	if outcome.first_perfect:
		var enhance: Array = EducationCatalog.CHAPTERS[outcome.chapter]
		card.add_child(StoryUI.label("%s · %s earned" % enhance, 20, StoryUI.INK))
	var done := EducationUI.large_action(StoryUI.action("Back to Records", true))
	done.name = "CloseQuizResult"
	done.pressed.connect(request_back)
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(done)
