extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const FIG := "species.strangler_fig"

var _save := "user://c34-activities-%d.json" % OS.get_process_id()
var _app: Control
var _now := 2000000
var _output := ""
var _baseline := false
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	if args.size() >= 3 and DisplayServer.get_name() != "headless":
		_output = args[0]
		var dimensions := args[1].split("x")
		root.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
		DirAccess.make_dir_recursive_absolute(_output)
	_baseline = "--baseline" in args
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	for room in [HeadquartersCatalog.OUTREACH, HeadquartersCatalog.RECORDS, HeadquartersCatalog.ECOLOGY]:
		profile.rooms[String(room)] = 2
	_check(ProfileFile.replace(_save, profile, false), "Prepare disposable activity profile")
	var rng := RandomNumberGenerator.new()
	rng.seed = 402
	var progress := CampaignProgress.new(_save)
	var session := OutreachSession.new(progress, EducationCatalog.load_installed(), rng)
	_check(session.refresh(int(Time.get_unix_time_from_system())), "Prepare the same sourced Outreach batch for comparison")
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _save
	_app.garden_time = func() -> int: return _now
	root.add_child(_app)
	_app.set_process(false)
	if not _output.is_empty():
		_app.presentation.values.text = int(args[2])
		_app._restyle()
	await _outreach()
	await _records()
	await _garden()
	await _guide()
	_app.free()
	var loaded := CampaignProgress.new(_save)
	_check(loaded.outreach_successes() == 1 and loaded.records_enhancements().has(&"records_chapter.scout_sniper")
		and loaded.restoration_percent() == 20, "Cold reload retains settled Outreach, Records and Garden progress")
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C34 activity journeys: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _outreach() -> void:
	await _room("outreach")
	await _capture("outreach")
	var page := _app._screen as OutreachPage
	var sounds: Array[String] = []
	page.sound_requested.connect(sounds.append)
	_record_size("RefreshOutreach")
	_record_size("OutreachAnswer0")
	_record_size("OutreachPrompt1")
	var batch := page._session.batch()
	var question: String = batch.batch[0]
	var order: Array = batch.choice_order[question]
	var best := 0
	for index in order.size():
		if page.catalog.outreach[question].choices[order[index]].grade == "best":
			best = index
			break
	if not _baseline:
		_check_answer_bounds("OutreachAnswer", "Outreach")
		_check(_button("OutreachPrompt1").size.x >= 120.0, "Outreach tabs share the wide display")
		_check(_button("RefreshOutreach").size.y < 100.0, "Outreach refresh fits its status row without wrapping")
	var before: int = _app._campaign_progress.funds()
	await _tap("OutreachAnswer%d" % best)
	_check(sounds == ["outreach_response_positive"], "Accepted Best answer plays one grade cue")
	_check(_app._campaign_progress.funds() == before + 60000 and _label("OutreachGrade") == "Best"
		and _label("OutreachFundsChange") == "60,000 Funds credited", "Outreach touch settles the correct graded response")
	_check(_button("RefreshOutreach").disabled and page._session.seconds_until_refresh(int(batch.refreshed_at)) == 20 * 3600
		and page._session.seconds_until_refresh(int(batch.refreshed_at) + 20 * 3600) == 0, "Outreach receipt retains the 20-hour refresh")
	await _capture("outreach-receipt")
	if not _baseline:
		await _tap("NextOutreachPrompt")
		_check(_button("OutreachAnswer0") != null and page._selected == batch.batch[1],
			"Next unanswered opens the next prompt with no further debit or receipt")

func _records() -> void:
	await _room("records")
	await _capture("records")
	var articles := _app._screen.find_children("Article_*", "Button", true, false) as Array[Node]
	if not _baseline:
		var first := articles[0] as Button
		var list := first.get_parent().get_parent().get_parent().get_parent() as ScrollContainer
		await _swipe(first, Vector2(0, -130))
		_check(list.scroll_vertical > 0 and not is_instance_valid(_app._guide),
			"Swiping a long article list scrolls without opening the article under the finger")
	await _tap(String(articles[0].name))
	_check(is_instance_valid(_app._guide), "An article opens from Records through touch")
	await _capture("records-article")
	_app._go_back()
	await _tap("Chapter_scout_sniper")
	var page := _app._screen as RecordsQuizPage
	var sounds: Array[String] = []
	page.sound_requested.connect(sounds.append)
	page.set_process(false)
	if not _baseline:
		_check_answer_bounds("QuizAnswer", "Records")
	await _capture("records-question")
	_record_size("QuizAnswer0")
	_record_size("PauseQuiz")
	_check(page.quiz.seconds_left() == 15, "Chapter starts at the authored 15-second duration")
	page.quiz.advance(2.0)
	await _tap("PauseQuiz")
	page.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	page.quiz.advance(3600.0)
	_check(page.quiz.paused and page.quiz.seconds_left() == 13 and _button("QuizAnswer0") == null,
		"Paused and backgrounded quiz freezes the timer and hides answer controls")
	await _tap("PauseQuiz")
	var answer_count := page.quiz.question_count()
	var before: int = _app._campaign_progress.funds()
	for index in answer_count:
		var question := page.quiz.question()
		var answer := 0
		for slot in question.choices.size():
			if question.choices[slot].id == question.correct_choice_id:
				answer = slot
				break
		await _tap("QuizAnswer%d" % answer)
		_check(_label("QuizQuestionFunds") == "30,000 Funds credited", "Records question %d credits once" % (index + 1))
		if index == 0:
			await _capture("records-feedback")
			_record_size("ContinueQuiz")
			if not _baseline:
				_check(_button("ContinueQuiz").size.x >= 700.0, "Records keeps Next question in a full-width footer")
		await _tap("ContinueQuiz")
	_check(_label("QuizResult") == "Perfect chapter" and _label("QuizChapterFunds") == "50,000 Funds credited"
		and _app._campaign_progress.funds() == before + 30000 * answer_count + 50000, "Records settles the perfect chapter and all correct answers")
	_check(sounds.count("records_correct") == answer_count and sounds.count("records_first_perfect") == 1,
		"Each accepted answer and the persisted first perfect emit one cue")
	await _capture("records-result")
	await _tap("CloseQuizResult")
	_check(_app._screen is RecordsArchivePage, "Results return to Records")

func _garden() -> void:
	_app.show_menu()
	await _tap("Garden")
	var page := _app._screen as HeadquartersGarden
	var sounds: Array[String] = []
	page.sound_requested.connect(sounds.append)
	await _capture("garden")
	_record_size("Plot2")
	_record_size("ChooseSeed")
	var plot := _button("Plot2")
	if not _baseline:
		_check(plot.size.x >= 100.0 and plot.size.y >= 80.0 and not plot.get_global_rect().intersects(_button("Plot1").get_global_rect()),
			"Garden presents enlarged plot hitboxes without overlap")
		await _tap("Plot2", Vector2(0.5, 0.2))
		_check(page._slot == 1, "Tapping the upper illustrated bed selects its plot")
	else:
		await _tap("Plot2")
	await _tap("ChooseSeed")
	await _capture("garden-seeds")
	_record_size("Plant_strangler_fig")
	if not _baseline:
		_check(not _button("Plot2").is_visible_in_tree(), "Seed selection hides the plot targets while the chosen bed is outlined")
		_check(_button("Plant_strangler_fig").size.y >= 115.0, "Garden seed cards have tall touch targets")
		_check(_visible_hit(_button("Plant_mengaris")).size.y >= 65.0, "The bottom seed option stays reachable above the footer")
		await _tap("CancelSeed")
		_check(page._view == HeadquartersGarden.View.PLOT and page._plot().is_empty() and _button("Plot2").is_visible_in_tree(),
			"Cancel seed selection restores the plot targets and preserves the empty plot")
		await _tap("ChooseSeed")
	var before: int = _app._campaign_progress.funds()
	await _tap("Plant_strangler_fig")
	_check(page._plot().species == FIG and _app._campaign_progress.funds() == before, "Planting a seed from the large card is free")
	page.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_now += RestorationRules.midpoint(FIG)
	await _settle_layout()
	_check(not sounds.has("restoration_growth_ready"), "Catching up growth after suspension stays quiet")
	await _capture("garden-water")
	_record_size("WaterPlot")
	var water := page._plot().duplicate()
	await _tap("WaterPlot")
	_check(water.watered_at == 0 and page._plot().watered_at == _now, "The Water action resumes the due cycle")
	_now += RestorationRules.midpoint(FIG)
	await _settle_layout()
	await _capture("garden-collect")
	await _tap("CollectPlot")
	_check(page._plot().is_empty() and _app._campaign_progress.restoration_percent() == 20
		and _app._campaign_progress.funds() == before + 53000, "Collect settles the cycle and milestone exactly once")
	_check(sounds.count("restoration_plant") == 1 and sounds.count("water") == 1
		and sounds.count("restoration_milestone") == 1 and not sounds.has("restoration_collect"),
		"Garden settlement dispatches plant, water and milestone without a stacked collection")
	await _capture("garden-receipt")

func _guide() -> void:
	_app.show_menu()
	await _tap("OpenFAQ")
	await _capture("field-guide")
	var buttons: Array[Node] = _app._guide.find_children("*", "Button", true, false)
	for node in buttons:
		var button := node as Button
		if button.text != FieldGuide.DEPLOY_TOPIC:
			continue
		await _tap(String(button.name))
		break
	if not _baseline:
		var guidance := FieldGuide.TOPICS[FieldGuide.DEPLOY_TOPIC] as String
		_check("Face left or Face right" in guidance and "Deploy" in guidance and "Cancel" in guidance,
			"The Field Guide documents explicit facing and confirmation")
	_app._go_back()
	_app._go_back()
	_check(not is_instance_valid(_app._guide) and _app._route == &"menu", "Back restores the Main Menu from the guide")

func _room(id: String) -> void:
	_app.show_menu()
	await _tap("OpenHeadquarters")
	await _tap("Room_" + id)
	await _tap("RoomActivity")

func _check_answer_bounds(prefix: String, activity: String) -> void:
	var previous: Rect2
	for index in 4:
		var button := _button(prefix + str(index))
		var hit := button.get_global_rect()
		_check(_visible_hit(button).size.y >= 50.0 and hit.size.y >= 70.0 and hit.size.x >= 350.0
			and (index == 0 or hit.position.y - previous.end.y >= 10.0)
			and not button.accessibility_name.is_empty(), "%s answer %s has a large area and finger separation" % [activity, index + 1])
		previous = hit

func _visible_hit(button: Button) -> Rect2:
	var hit := button.get_global_rect()
	var node := button.get_parent()
	while node != null:
		if node is ScrollContainer:
			hit = hit.intersection(node.get_global_rect())
		node = node.get_parent()
	return hit

func _button(id: String) -> Button:
	var page: Control = _app._guide if is_instance_valid(_app._guide) else _app._screen
	return page.find_child(id, true, false)

func _label(id: String) -> String:
	var label := _app._screen.find_child(id, true, false) as Label
	return label.text if label != null else ""

func _tap(id: String, relative := Vector2(0.5, 0.5)) -> void:
	await _settle_layout()
	var button := _button(id)
	_check(button != null and not button.disabled and button.is_visible_in_tree(), "Available touch control %s" % id)
	if button == null or button.disabled or not button.is_visible_in_tree():
		return
	var scroll := button.get_parent()
	while scroll != null and not scroll is ScrollContainer:
		scroll = scroll.get_parent()
	if scroll is ScrollContainer:
		scroll.ensure_control_visible(button)
		await _settle_layout()
	var point := root.get_final_transform() * (button.get_global_rect().position + button.size * relative)
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	touch = touch.duplicate()
	touch.pressed = false
	Input.parse_input_event(touch)
	await _settle_layout()

func _settle_layout() -> void:
	await process_frame
	await process_frame
	await process_frame

func _swipe(button: Button, distance: Vector2) -> void:
	# Desktop ScrollContainer only enables its touch drag path on a touch-capable display.
	var previous_emulation := Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	var from := root.get_final_transform() * button.get_global_rect().get_center()
	var current := from
	var touch := InputEventScreenTouch.new()
	touch.position = from
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	for step in range(1, 7):
		var drag := InputEventScreenDrag.new()
		drag.position = from + distance * (float(step) / 6.0)
		drag.relative = drag.position - current
		drag.screen_relative = drag.relative
		current = drag.position
		Input.parse_input_event(drag)
		await process_frame
	touch = touch.duplicate()
	touch.position = current
	touch.pressed = false
	Input.parse_input_event(touch)
	await _settle_layout()
	Input.emulate_touch_from_mouse = previous_emulation

func _record_size(id: String) -> void:
	if _output.is_empty():
		return
	var local := _button(id).get_global_rect()
	var pixels := root.get_final_transform() * local
	print("%s target %.0f×%.0f host pixels" % [id, pixels.size.x, pixels.size.y])
	await process_frame

func _capture(name: String) -> void:
	if _output.is_empty():
		return
	await _settle_layout()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size and image.save_png(_output.path_join(name + ".png")) == OK,
		"Native activity screenshot %s" % name)

func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", description)
