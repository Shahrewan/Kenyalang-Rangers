extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
var _path := "user://c34-lifecycle-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rima"
	profile.rooms[String(HeadquartersCatalog.RECORDS)] = 2
	_check(ProfileFile.replace(_path, profile, false), "Write an isolated lifecycle fixture")
	var app := _launch()
	await process_frame
	_check_finance(app)
	_check_battle(app)
	await _check_quiz(app)
	await _check_settings_and_recovery(app)
	for suffix in ["", ".tmp", ".bak", ".bak.tmp", ".settings", ".settings.tmp", ".reset"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C34 Android lifecycle rehearsal: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _launch() -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	app.save_path = _path + ".legacy"
	root.add_child(app)
	app.set_process(false)
	return app

func _check_finance(app: Control) -> void:
	var progress: CampaignProgress = app._campaign_progress
	app._process(2.0)
	var stored := progress.finance_stored()
	_check(stored == progress.finance_rate() * 2, "Finance accrues active foreground time")
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app._process(120.0)
	_check(progress.finance_stored() == stored and CampaignProgress.new(_path).finance_stored() == stored,
		"Background checkpoints Finance and blocks suspended income")
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	app._process(120.0)
	_check(progress.finance_stored() == stored and app.presentation._away, "Focus alone leaves a suspended Activity held")
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	app._process(1.0)
	_check(progress.finance_stored() == stored + progress.finance_rate() and not app.presentation._away,
		"Active time and audio resume after both lifecycle flags clear")

func _check_battle(app: Control) -> void:
	_press(app._screen, "OpenCampaign")
	_press(app._screen, "Operation_C1_01")
	_press(app._screen, "StartOperation")
	var field := app._screen as CampaignBattle
	_check(field != null, "Start First Contact through the launcher")
	if field == null:
		return
	field.set_physics_process(false)
	var clock := field.battle.clock
	clock.set_speed(2)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	clock.advance_frame()
	_check(clock.dialogue_open and not clock.paused and clock.tick == 0 and app.presentation._held,
		"Interrupting dialogue preserves the briefing and its hold")
	field.get_node("%Skip").pressed.emit()
	app._process(0.0)
	clock.advance_frame()
	_check(clock.tick == 2 and not app.presentation._held, "Explicit Skip opens the original 2× operation")
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	clock.advance_frame()
	_check(clock.tick == 2 and clock.paused and field.get_node("%PauseOverlay").visible,
		"Background holds combat even if Android Back arrives while suspended")
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(app.presentation._held and not app.presentation._away and clock.paused,
		"Resume immediately reconciles the music hold before the next launcher process step")
	_press(field, "PauseSettings")
	_check(is_instance_valid(app._battle_settings) and not field.visible, "Paused operation opens Settings over the original field")
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(app.presentation._away and app.presentation._held, "Resume alone waits for focus on Android")
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	clock.advance_frame()
	_check(field.visible and clock.paused and clock.tick == 2 and app.presentation._held,
		"Android Back returns Settings to the same paused combat tick")
	_press(field, "ResumeOperation")
	clock.advance_frame()
	app._process(0.0)
	_check(clock.tick == 4 and not app.presentation._held and field.battle.integrity == 100,
		"Explicit Resume restores the same battle and 2× speed")
	_press(field.get_node("%Header"), "Pause")
	_press(field, "AskAbandon")
	_press(field, "ConfirmAbandon")
	_check(app._route == &"plan" and str(app._campaign_progress.snapshot().pending_attempt).is_empty(),
		"Closing the rehearsal clears the saved attempt without resetting progress")

func _check_quiz(app: Control) -> void:
	app._show_records(CampaignProgress.HEADQUARTERS.room(HeadquartersCatalog.RECORDS))
	_press(app._screen, "Chapter_scout_sniper")
	var page := app._screen as RecordsQuizPage
	_check(page != null, "Open an installed Records chapter")
	if page == null:
		return
	page.set_process(false)
	var quiz := page.quiz
	quiz.advance(0.4)
	var before := quiz.time_left_ticks
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	quiz.advance(120)
	_check(quiz.paused and quiz.time_left_ticks == before, "Quiz timer remains exact during a simulated Activity interruption")
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(app.presentation._held and quiz.paused, "Returning to a quiz leaves its timer and audio held")
	var archive := CampaignProgress.new(_path)
	_check(RecordsQuiz.new(archive, app.education_catalog).time_left_ticks == before, "The interrupted timer survives a separate save reload")
	app.show_menu()
	await process_frame

func _check_settings_and_recovery(app: Control) -> void:
	_press(app._screen, "OpenSettings")
	var page := app._screen as ProfileSettingsPage
	_press(page, "TextSize130")
	_press(page, "ResetProgress")
	await process_frame
	_check(page._dialog.visible and page._dialog.get_cancel_button().has_focus(), "The destructive confirmation initially focuses Cancel")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not page._dialog.visible and app._screen == page and CampaignProgress.new(_path).snapshot().leader_name == "Rima",
		"Android Back dismisses the prompt while protecting local progress")
	_check(app.presentation.values.text == 130 and ProfileFile.read(_path + ".settings").text == 130,
		"Text size is persisted independently from Campaign progress")
	app.free()
	var corrupt := FileAccess.open(_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	app = _launch()
	_check(app._route == &"recovery" and app._campaign_progress.load_status == CampaignProgress.LoadStatus.RECOVERED
		and app._campaign_progress.snapshot().leader_name == "Rima" and app.presentation.values.text == 130,
		"Cold launch after a damaged primary restores the valid backup and saved text size")
	_press(app._screen, "RecoveryContinue")
	_check(app._route == &"menu", "Recovery Continue opens the saved Leader menu")
	app.free()
	await process_frame

func _press(parent: Node, id: String) -> void:
	var button := parent.find_child(id, true, false) as BaseButton
	_check(button != null and not button.disabled, "Open available control " + id)
	if button != null and not button.disabled:
		button.pressed.emit()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
