extends SceneTree

const Fixture := preload("res://tests/fixtures/education/banks.gd")
const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
var _path := "user://c19-ui-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Education QA"
	profile.rooms[String(HeadquartersCatalog.OUTREACH)] = 1
	profile.rooms[String(HeadquartersCatalog.RECORDS)] = 2
	ProfileFile.replace(_path, profile, false)
	var app := _open(EducationCatalog.new())
	await process_frame
	_room(app, "outreach")
	_check(app._screen is OutreachPage and _has_text(app, "Outreach questions await an approved bank."), "Player Outreach identifies the missing approved bank")
	_check(_button(app, "OutreachAnswer0") == null and app._campaign_progress.outreach_state().batch.is_empty(), "The player build serves no synthetic or draft questions")
	_room(app, "records")
	_check(app._screen is RecordsArchivePage and _button(app, "Chapter_scout_sniper").disabled, "The player Records page keeps unapproved quizzes unavailable")
	app.free()
	await process_frame

	app = _open(Fixture.catalog())
	await process_frame
	_room(app, "outreach")
	_check(app._screen.find_children("OutreachPrompt?", "Button", true, false).size() == 5 and "Next batch in" in _label(app, "OutreachTimer"), "The live Outreach page opens five prompts and a 20-hour countdown")
	_check(app._screen.find_children("OutreachAnswer*", "Button", true, false).size() == 4, "Outreach displays four available response buttons")
	var batch: Dictionary = app._campaign_progress.outreach_state()
	var first: String = batch.batch[0]
	var best: int = batch.choice_order[first].find(0)
	var selected := _button(app, "OutreachAnswer%d" % best)
	_check(selected.tooltip_text == "Fixture marker 1", "The shuffled button shows the authored response it will submit")
	selected.pressed.emit()
	_check(_label(app, "OutreachGrade") == "Best" and _label(app, "OutreachFundsChange") == "25,000 Funds credited", "Response feedback reports the grade and actual award")
	_check(_has_text(app, "Synthetic best feedback.") and _has_text(app, "Synthetic source"), "Outreach displays the selected explanation and offline attribution")
	_check(_button(app, "OutreachAnswer0") == null and "1 Best or Acceptable" in _label(app, "OutreachParticipation"), "An answered prompt becomes review-only and advances participation")
	app.free()
	await process_frame
	app = _open(Fixture.catalog())
	await process_frame
	_room(app, "outreach")
	_press(app, "OutreachPrompt1")
	_check(_label(app, "OutreachGrade") == "Best" and app._campaign_progress.funds() == 35000, "Relaunch reopens the saved prompt and award without paying again")

	_room(app, "records")
	_check(app._screen is RecordsArchivePage and _has_text(app, "Synthetic fact") and _has_text(app, "Synthetic source"), "Approved-format facts render with offline sources")
	_check(not _button(app, "Chapter_scout_sniper").disabled and _button(app, "Chapter_patrolman").disabled and _has_text(app, "Requires Records Lv.5"), "Records exposes the four named chapters and actual room gates")
	_press(app, "Chapter_scout_sniper")
	var page := app._screen as RecordsQuizPage
	page.set_process(false)
	_check("Question 1 of 2 · 15 s" == _label(app, "QuizTimer") and _button(app, "QuizAnswer3") != null, "Quiz opens with 15 seconds and four choices")
	page.quiz.advance(2.75)
	_press(app, "PauseQuiz")
	page.quiz.advance(45)
	_check(page.quiz.time_left_ticks == 735 and _button(app, "QuizAnswer0") == null, "Pause conceals the question and holds the countdown")
	_press(app, "PauseQuiz")
	page.quiz.advance(0.50)
	_check(page.quiz.time_left_ticks == 705, "Resume continues at the stored remaining time")
	app.free()
	await process_frame
	app = _open(Fixture.catalog())
	await process_frame
	_room(app, "records")
	_check(_button(app, "Chapter_scout_sniper").text == "Resume chapter", "Cold boot offers the saved quiz in Records")
	_press(app, "Chapter_scout_sniper")
	page = app._screen as RecordsQuizPage
	page.set_process(false)
	_check(page.quiz.paused and page.quiz.time_left_ticks == 705, "Exiting mid-question checkpoints the remaining ticks and resumes paused")
	_press(app, "PauseQuiz")
	page.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	page.quiz.advance(3)
	_check(page.quiz.paused and page.quiz.time_left_ticks == 705, "Backgrounding the app pauses the quiz")
	_press(app, "PauseQuiz")
	page.quiz.advance(11.75)
	_check(_label(app, "QuizFeedback") == "Time expired" and _label(app, "QuizQuestionFunds") == "0 Funds credited", "Timeout shows the explanation with zero award")
	_check(_has_text(app, "Marker three is the correct fixture response."), "Timeout shows the sourced answer explanation")
	_press(app, "ContinueQuiz")
	_press(app, "QuizAnswer2")
	_check(_label(app, "QuizFeedback") == "Correct" and _label(app, "QuizQuestionFunds") == "30,000 Funds credited", "A correct answer immediately settles its first reward")
	_press(app, "ContinueQuiz")
	_check(_label(app, "QuizResult") == "Chapter complete" and _label(app, "QuizChapterFunds") == "0 Funds credited", "The imperfect result displays zero chapter award")
	_press(app, "CloseQuizResult")
	_press(app, "Chapter_scout_sniper")
	page = app._screen as RecordsQuizPage
	page.set_process(false)
	_press(app, "QuizAnswer2")
	_press(app, "ContinueQuiz")
	_press(app, "QuizAnswer2")
	_check(_label(app, "QuizQuestionFunds") == "0 Funds credited", "The replayed correct answer earns zero")
	_press(app, "ContinueQuiz")
	_check(_label(app, "QuizResult") == "Perfect chapter" and _label(app, "QuizChapterFunds") == "70,000 Funds credited" and _has_text(app, "Steady Aim and Focus earned"), "First perfect result shows the persisted named enhancement")
	_press(app, "CloseQuizResult")
	_check(_has_text(app, "Enhancement earned") and app._campaign_progress.funds() == 165000, "Archive and wallet reflect the completed reward")
	app.free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Education UI: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _open(catalog: EducationCatalog = null) -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	app.education_catalog = catalog
	root.add_child(app)
	app.set_process(false)
	return app

func _room(app: Control, id: String) -> void:
	app.show_menu()
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	_press(app, "Room_" + id)
	_press(app, "RoomActivity")

func _button(app: Control, id: String) -> Button:
	return app._screen.find_child(id, true, false)

func _press(app: Control, id: String) -> void:
	_button(app, id).pressed.emit()

func _label(app: Control, id: String) -> String:
	var found := app._screen.find_child(id, true, false) as Label
	return found.text if found != null else ""

func _has_text(app: Control, value: String) -> bool:
	for label: Label in app._screen.find_children("*", "Label", true, false):
		if value in label.text:
			return true
	return false

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
