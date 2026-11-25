extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const SCOUT := "records_chapter.scout_sniper"
const FACT := "fact.hornbill_casque"

var _path := "user://c31c-education-%d.json" % OS.get_process_id()
var _checks := 0
var _failures := 0
var _captures := ""
var _text_size := 100

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(960, 540)
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		_captures = args[0]
		var frame := args[1].split("x")
		root.size = Vector2i(int(frame[0]), int(frame[1]))
		_text_size = int(args[2])
		DirAccess.make_dir_recursive_absolute(_captures)
	var bank := EducationCatalog.load_installed()
	_check(bank.outreach_revision == 2 and bank.outreach.size() == 20, "Player package serves 20 revision-2 Outreach scenarios")
	_check(bank.records_revision == 2 and bank.chapters.size() == 4 and bank.facts.has(FACT), "Player package serves all four Records chapters and the cited archive")
	var question_ids := []
	for chapter: Dictionary in bank.chapters.values():
		_check(chapter.questions.size() == 10, "Each chapter supplies ten four-choice questions")
		question_ids.append_array(chapter.questions.map(func(item: Dictionary) -> String: return item.id))
	_check(question_ids.size() == 40 and "records.sarawak_emblem" in question_ids and "records.rhinoceros_clutch" in question_ids,
		"Forty questions include distinct adaptations from the supplied hornbill quiz")
	if _failures > 0:
		quit(1)
		return
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.rooms[String(HeadquartersCatalog.OUTREACH)] = 1
	profile.rooms[String(HeadquartersCatalog.RECORDS)] = 2
	ProfileFile.replace(_path, profile, false)
	var app := _launcher()
	await process_frame
	_room(app, "outreach")
	var batch: Dictionary = app._campaign_progress.outreach_state()
	_check(batch.batch.size() == 5 and app._screen.find_children("OutreachAnswer*", "Button", true, false).size() == 4,
		"Headquarters Outreach opens an offline batch with four response buttons")
	await _capture("outreach")
	var first := String(batch.batch[0])
	var choices: Array = bank.outreach[first].choices
	var option := choices.find_custom(func(choice: Dictionary) -> bool: return choice.grade == "best")
	_press(app, "OutreachAnswer%d" % batch.choice_order[first].find(option))
	_check(_find(app, "OutreachGrade").text == "Best" and app._campaign_progress.funds() == 35000,
		"Real Outreach scenario records its best grade and existing payout")
	await _capture("outreach-feedback")
	app.free()

	app = _launcher()
	await process_frame
	_room(app, "outreach")
	_press(app, "OutreachPrompt1")
	_check(_find(app, "OutreachGrade").text == "Best" and app._campaign_progress.funds() == 35000,
		"Cold restart restores the answer without paying it twice")
	_room(app, "records")
	_check(not _find(app, "Chapter_scout_sniper").disabled and _find(app, "Chapter_patrolman").disabled,
		"The archive exposes live quizzes under the existing room gates")
	await _capture("records")
	_press(app, "Article_hornbill_casque")
	_check(app._guide is FieldGuide and app._guide.initial_page == FACT, "Read article opens the documented fact in the offline guide")
	app._guide.back()
	_press(app, "Chapter_scout_sniper")
	var quiz_page := app._screen as RecordsQuizPage
	quiz_page.set_process(false)
	var timer := _find(app, "QuizTimeRemaining") as ProgressBar
	_check(timer.value == CampaignActivities.QUIZ_TICKS, "The actual visual timer starts with 15 seconds")
	quiz_page.quiz.advance(1.5)
	_press(app, "PauseQuiz")
	var held := timer.value
	quiz_page.quiz.advance(10.0)
	_check(quiz_page.quiz.paused and held == CampaignActivities.QUIZ_TICKS - 90 and timer.value == held,
		"Pause holds the real timer and its gauge")
	_press(app, "PauseQuiz")
	await _capture("records-question")
	for index in 10:
		_answer(app, quiz_page.quiz)
		if index == 0:
			await _capture("records-first-correct")
		_press(app, "ContinueQuiz")
	var after: int = app._campaign_progress.funds()
	_check(after == 385000, "Ten first-correct responses and the first perfect earn 350,000 Funds")
	_check(_find(app, "QuizResult").text == "Perfect chapter" and _find(app, "QuizChapterFunds").text.contains("50,000"),
		"Perfect chapter records its enhancement and displays the 50,000 bonus")
	_check(StringName(SCOUT) in app._campaign_progress.records_enhancements(), "The actual Campaign profile owns the earned Records enhancement")
	await _capture("records-result")
	_press(app, "CloseQuizResult")
	_press(app, "Chapter_scout_sniper")
	quiz_page = app._screen
	quiz_page.set_process(false)
	_answer(app, quiz_page.quiz)
	_check(app._campaign_progress.funds() == after, "A correct replay answer earns zero repeat Funds")
	app.free()
	for stem in [_path, _path + ".settings"]:
		for suffix in ["", ".bak", ".bak.tmp", ".tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C31-C player education: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _launcher() -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	app.presentation.values.text = _text_size
	app._restyle()
	return app

func _room(app: Control, id: String) -> void:
	app.show_menu()
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	_press(app, "Room_" + id)
	_press(app, "RoomActivity")

func _answer(app: Control, quiz: RecordsQuiz) -> void:
	var question := quiz.question()
	var index: int = question.choices.find_custom(func(choice: Dictionary) -> bool: return choice.id == question.correct_choice_id)
	_press(app, "QuizAnswer%d" % index)

func _find(app: Control, id: String) -> Control:
	return app._screen.find_child(id, true, false)

func _press(app: Control, id: String) -> void:
	_find(app, id).pressed.emit()

func _capture(id: String) -> void:
	if _captures.is_empty():
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	_check(frame.get_size() == root.size and frame.save_png(_captures.path_join(id + ".png")) == OK, "Saved native " + id)

func _check(check: bool, message: String) -> void:
	_checks += 1
	if not check:
		_failures += 1
		printerr("FAIL ", message)
