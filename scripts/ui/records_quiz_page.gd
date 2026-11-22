class_name RecordsQuizPage
extends VBoxContainer

signal back_requested

var progress: CampaignProgress
var catalog: EducationCatalog
var quiz: RecordsQuiz
var _clock: Label
var _pause: Button
var _wallet: Label
var _body: VBoxContainer
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
	_pause = StoryUI.action("Pause quiz")
	_pause.name = "PauseQuiz"
	_pause.pressed.connect(_toggle_pause)
	status.add_child(_pause)
	_body = StoryUI.scroll_column(self)
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	_notice.name = "QuizNotice"
	add_child(_notice)
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
	if quiz.result.is_empty() and quiz.can_resume():
		_clock.text = "Question %d of %d · %d s" % [quiz.question_number(), quiz.question_count(), quiz.seconds_left()]
		if quiz.reviewing():
			_clock.text = "Question %d of %d" % [quiz.question_number(), quiz.question_count()]
	else:
		_clock.text = ""

func _render() -> void:
	EducationUI.clear(_body)
	_wallet.text = "%s Funds" % StoryUI.funds(progress.funds())
	_notice.text = quiz.notice
	_pause.visible = quiz.result.is_empty() and quiz.can_resume() and not quiz.reviewing()
	_pause.text = "Resume quiz" if quiz.paused else "Pause quiz"
	_update_clock()
	if not quiz.result.is_empty():
		_result()
	elif quiz.paused:
		_body.add_child(StoryUI.label("Quiz paused", 26))
	elif quiz.reviewing():
		_review()
	else:
		_ask()
	StoryUI.size_buttons(self)

func _ask() -> void:
	var item := quiz.question()
	var prompt := StoryUI.label(item.prompt, 25)
	prompt.name = "QuizPrompt"
	_body.add_child(prompt)
	for index in item.choices.size():
		_body.add_child(EducationUI.answer_button(item.choices[index].text, "QuizAnswer%d" % index, _answer.bind(index)))

func _answer(index: int) -> void:
	quiz.answer(index)

func _review() -> void:
	var item := quiz.question()
	var outcome := quiz.feedback()
	var card := StoryUI.panel(_body, true)
	var state := "Time expired" if outcome.choice < 0 else "Correct" if outcome.correct else "Incorrect"
	var heading := StoryUI.label(state, 26, StoryUI.INK)
	heading.name = "QuizFeedback"
	card.add_child(heading)
	card.add_child(StoryUI.label(item.prompt, 20, StoryUI.INK))
	for choice: Dictionary in item.choices:
		if choice.id == item.correct_choice_id:
			card.add_child(StoryUI.label("Correct answer · " + choice.text, 20, StoryUI.INK))
			break
	card.add_child(StoryUI.label(item.explanation, 21, StoryUI.INK))
	var funds := StoryUI.label(EducationUI.receipt(int(outcome.get("credited", 0)), int(outcome.get("discarded", 0))), 19, StoryUI.INK)
	funds.name = "QuizQuestionFunds"
	card.add_child(funds)
	EducationUI.credit_sources(card, catalog, item.source_ids, StoryUI.INK)
	var next := StoryUI.action("Finish chapter" if quiz.question_number() == quiz.question_count() else "Next question", true)
	next.name = "ContinueQuiz"
	next.pressed.connect(func() -> void: quiz.continue_after_feedback())
	_body.add_child(next)

func _result() -> void:
	var outcome := quiz.result
	var card := StoryUI.panel(_body, true)
	var heading := StoryUI.label("Perfect chapter" if outcome.correct == outcome.total else "Chapter complete", 28, StoryUI.INK)
	heading.name = "QuizResult"
	card.add_child(heading)
	card.add_child(StoryUI.label("%d of %d correct" % [outcome.correct, outcome.total], 22, StoryUI.INK))
	var funds := StoryUI.label(EducationUI.receipt(int(outcome.credited), int(outcome.discarded)), 21, StoryUI.INK)
	funds.name = "QuizChapterFunds"
	card.add_child(funds)
	if outcome.first_perfect:
		var enhance: Array = EducationCatalog.CHAPTERS[outcome.chapter]
		card.add_child(StoryUI.label("%s · %s earned" % enhance, 20, StoryUI.INK))
	var done := StoryUI.action("Back to Records", true)
	done.name = "CloseQuizResult"
	done.pressed.connect(request_back)
	_body.add_child(done)
