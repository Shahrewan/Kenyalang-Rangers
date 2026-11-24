extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const PLANTED := 1700000000
var now := PLANTED
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else ""
	var education := "--education" in args
	var app := LAUNCHER.instantiate()
	# The host runner also isolates the entire user directory for each install path.
	app.save_path = "user://c24-legacy.json"
	app.campaign_save_path = "user://c24-campaign.json"
	app.garden_time = func() -> int: return now
	root.add_child(app)
	app.set_process(false)
	await process_frame
	var profile: CampaignProgress = app._campaign_progress
	if mode == "seed":
		_check(app._route == &"name", "Fresh launch opens Leader naming")
		var input: LineEdit = app._screen.find_child("LeaderName", true, false)
		input.text = "Lina"
		input.text_changed.emit(input.text)
		_press(app, "SaveName")
		_check(app._route == &"menu" and profile.funds() == 10000, "Naming opens the 10,000 Funds profile")
		# Six full Finance claims fund the test through the normal wallet.
		for claim in 6:
			profile.advance_finance(6000.0)
			_check(profile.claim_finance(), "Claim stored active Finance %d" % (claim + 1))
		for id in ["ecology", "outreach", "records", "records"]:
			_open_room(app, id)
			var room: HeadquartersRoomPage = app._screen
			room._purchase.pressed.emit()
			room._dialog.hide()
			room._dialog.confirmed.emit()
		_check(profile.room_level(HeadquartersCatalog.RECORDS) == 2 and profile.funds() == 12000, "Room builds and Records upgrade settle")
		app.show_menu()
		_press(app, "Garden")
		for action in ["Plot1", "ChooseSeed", "Plant_strangler_fig"]:
			_press(app, action)
		_check(profile.garden_state().plots.has("garden_plot.01"), "Growing fig saved from the Garden")
	elif mode == "resume":
		_check(app._route == &"menu" and profile.snapshot().leader_name == "Lina" and profile.funds() == 12000, "Returning process restores Leader and wallet")
		_check(profile.room_level(HeadquartersCatalog.ECOLOGY) == 1 and profile.room_level(HeadquartersCatalog.RECORDS) == 2, "Room purchase and upgrade persist")
		now += 9 * 3600
		_press(app, "Garden")
		_press(app, "Plot1")
		_press(app, "WaterPlot")
		now += 9 * 3600
		app.show_menu()
		_press(app, "Garden")
		_press(app, "Plot1")
		_press(app, "CollectPlot")
		_check(profile.restoration_percent() == 20 and profile.funds() == 65000, "Returning Garden waters and collects a single 53,000 Funds award")
		for id in ["outreach", "records"]:
			_open_room(app, id)
			_press(app, "RoomActivity")
			if id == "outreach":
				if education:
					var choice := app._screen.find_child("OutreachAnswer0", true, false) as Button
					_check(app._screen is OutreachPage and choice != null and not choice.disabled
						and profile.outreach_state().batch.size() == 5, "Returning save opens an installed Outreach batch")
				else:
					_check(app._screen is OutreachPage and _has_text(app._screen, "Outreach questions await an approved bank."), "Installed Outreach reports its approval gate")
			else:
				var chapter: Button = app._screen.find_child("Chapter_scout_sniper", true, false)
				_check(app._screen is RecordsArchivePage and chapter != null and chapter.disabled == (not education),
					"Installed Records follows the player bank and existing Lv.2 room gate")
	elif mode == "verify":
		_check(profile.funds() == 65000 and profile.restoration_percent() == 20 and profile.garden_state().plots.is_empty(), "Second relaunch retains the settled harvest")
		_check(profile.load_status == CampaignProgress.LoadStatus.READY, "Primary profile opens without recovery")
		if education:
			_check(profile.outreach_state().batch.size() == 5, "Second relaunch keeps the installed Outreach rotation")
	else:
		_check(false, "Use seed, resume or verify from the package checker")
	app.free()
	await process_frame
	quit(1 if failures else 0)

func _open_room(app: Control, id: String) -> void:
	app.show_menu()
	_press(app, "OpenHeadquarters")
	_press(app, "Room_" + id)

func _press(app: Control, id: String) -> void:
	var button: Button = app._screen.find_child(id, true, false)
	if button == null or button.disabled:
		_check(false, "Expected available action " + id)
		return
	button.pressed.emit()

func _has_text(page: Control, fragment: String) -> bool:
	for label: Label in page.find_children("*", "Label", true, false):
		if fragment in label.text:
			return true
	return false

func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		failures += 1
		push_error(message)
