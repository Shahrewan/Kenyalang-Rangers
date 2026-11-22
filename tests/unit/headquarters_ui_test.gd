extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")

var _path := "user://c15-ui-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var fixture := CampaignSave.fresh()
	fixture.funds = 186500
	fixture.leader_name = "Mira"
	fixture.records = {"C1-01": {"cleared": true, "perfect": true}}
	ProfileFile.replace(_path, fixture, false)
	var app := _launcher()
	var progress: CampaignProgress = app._campaign_progress
	_check(app._route == &"menu", "A valid saved Leader reaches the main menu")
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	await process_frame
	await process_frame
	var overview := app._screen as HeadquartersOverview
	var rooms := overview.find_children("Room_*", "Button", true, false)
	_check(rooms.size() == 11 and rooms.all(func(room: Button) -> bool: return not room.disabled), "The office cross-section has eleven selectable rooms")
	for room: Button in rooms:
		var status := room.find_child("RoomLevel", true, false) as Label
		var interior := room.find_child("OfficeInterior", true, false) as Control
		_check(overview.get_global_rect().encloses(room.get_global_rect()) and status.get_line_count() == 1 and interior.size.y >= 35.0, "%s fits its label and illustration at 960×540" % room.name)
	var hr := _open_room(app, "human_resources")
	_check("3 Ranger loadout slots" in hr._benefits.text, "Human Resources shows live capacity")
	hr._activity.pressed.emit()
	_check(app._screen is HeadquartersRosterPage and app._screen.find_children("Unit_*", "Button", true, false).size() == 12, "HR opens the twelve-Ranger catalogue")
	_button(app, "Unit_scout_sniper").pressed.emit()
	var scout := app._screen as DeployableUpgradePage
	scout._milestones[20].pressed.emit()
	scout._buy.pressed.emit()
	_check("60,096 Funds" in scout._dialog.dialog_text and "126,404 Funds" in scout._dialog.dialog_text, "Level confirmation itemizes the exact cost and remaining wallet")
	scout._dialog.hide()
	scout._dialog.canceled.emit()
	_check(progress.funds() == 186500 and progress.deployable_level(&"ranger.scout_sniper") == 1, "Cancelling a purchase leaves the level and wallet intact")
	_confirm_levels(scout)
	_check(progress.funds() == 126404 and progress.deployable_level(&"ranger.scout_sniper") == 20, "Confirming commits the selected milestone")
	scout.back_requested.emit()
	(app._screen as HeadquartersRosterPage).back_requested.emit()
	hr = app._screen as HeadquartersRoomPage
	_confirm_room(hr)
	_check("4 Ranger loadout slots" in hr._benefits.text, "The HR card refreshes immediately after purchase")
	hr.back_requested.emit()

	var finance := _open_room(app, "finance_room")
	_confirm_room(finance)
	app._focused = false
	app._process(5.0)
	_check(progress.finance_stored() == 0, "Focus loss halts Finance")
	app._focused = true
	app._suspended = true
	app._process(5.0)
	_check(progress.finance_stored() == 0, "App suspension halts Finance")
	app._suspended = false
	app._process(5.0)
	_check(progress.finance_stored() == 20 and "25,000" in finance._benefits.text, "Upgraded Finance uses 4/s while active")
	finance.back_requested.emit()

	var mechanical := _open_room(app, "mechanical")
	_confirm_room(mechanical)
	mechanical._activity.pressed.emit()
	_check(app._screen.find_children("Unit_*", "Button", true, false).size() == 13, "Mechanical opens the thirteen-Facility catalogue")
	_button(app, "Unit_sentry_tower").pressed.emit()
	var tower := app._screen as DeployableUpgradePage
	_check(tower._buy.disabled and "clearance above" in tower._footprint(), "Locked Sentry Tower keeps its footprint and purchase gate visible")
	tower.back_requested.emit()
	_button(app, "Unit_logistics_post").pressed.emit()
	var post := app._screen as DeployableUpgradePage
	post._milestones[20].pressed.emit()
	_check("10.96 Tokens" in post._preview.text, "Logistics Post preview shows fractional gain at Lv.20")
	_confirm_levels(post)
	app.show_story()
	_button(app, "Operation_C1_02").pressed.emit()
	var plan: OperationPlan = app._screen.plan
	_check(plan.ranger_limit == 4 and plan.facility_limit == 2 and plan.can_start(), "The ordinary planner consumes purchased HQ capacity")
	_button(app, "StartOperation").pressed.emit()
	var battle := app._screen as CampaignBattle
	battle.set_physics_process(false)
	battle.get_node("%Skip").pressed.emit()
	var entries := battle.operation_plan.deployment_entries().filter(func(spec: DeploymentSpec) -> bool: return spec.logistics_post)
	var field_post := entries[0] as DeploymentSpec
	_check(field_post.level == 20 and battle.battle.deployment.deploy(field_post, Vector2i(1, 0), 1).is_empty(), "An ordinary Post is deployed at its purchased level")
	for i in LogisticsRules.PAYOUT_TICKS * 2:
		battle.battle.clock.advance_frame()
	_check(battle.battle.deployment.tokens == 21, "Post generation carries its fractional Lv.20 remainder across payouts")
	var pending := progress.snapshot()
	app.free()
	await process_frame

	ProfileFile.replace(_path + ".bak", pending, false)
	ProfileFile.replace(_path, {"version": 2}, false)
	app = _launcher()
	_check(app._route == &"recovery", "Backup recovery surfaces a local-save notice")
	var resume: Button = app._screen.find_children("*", "Button", true, false)[0]
	resume.pressed.emit()
	_check(app._route == &"plan" and app._screen.plan.operation.stage.stage_id == &"C1-02", "Recovered interrupted battle opens its planning screen")
	_check(app._campaign_progress.room_capacity(HeadquartersCatalog.HR) == 4 and app._campaign_progress.deployable_level(&"facility.logistics_post") == 20, "Recovered planner keeps room and deployable purchases")
	app.free()
	await process_frame
	ProfileFile.replace(_path, {"version": 2}, false)
	ProfileFile.replace(_path + ".bak", {"version": 2}, false)
	var legacy := FirstContactProgress.new(_path + ".legacy")
	legacy.set_leader_name("Legacy name")
	app = _launcher()
	_check(app._route == &"recovery" and app._screen.find_children("*", "Button", true, false).size() == 1, "Two corrupt copies expose Settings as the recovery route")
	_button(app, "RecoverySettings").pressed.emit()
	var settings := app._screen as ProfileSettingsPage
	_button(app, "ResetProgress").pressed.emit()
	settings._dialog.hide()
	settings._dialog.canceled.emit()
	var unreadable := ProfileFile.read(_path)
	_check(app._route == &"settings" and unreadable.size() == 1 and unreadable.version == 2 and FileAccess.file_exists(_path + ".bak"), "Cancelling reset preserves both unreadable copies")
	_button(app, "ResetProgress").pressed.emit()
	settings._dialog.hide()
	settings._dialog.confirmed.emit()
	_check(app._route == &"name" and app._campaign_progress.funds() == 10000 and not FileAccess.file_exists(_path + ".bak"), "Confirmed Settings reset starts naming and invalidates the prior backup")
	app.free()
	await process_frame
	app = _launcher()
	_check(app._route == &"name" and app._campaign_progress.snapshot().leader_name.is_empty(), "Cold launch after reset keeps the name cleared")
	app.free()
	await process_frame
	await _overflow_and_garden()
	_cleanup()
	print("Headquarters UI: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _overflow_and_garden() -> void:
	var fixture := CampaignSave.fresh()
	fixture.leader_name = "Rina"
	fixture.funds = 9990000
	fixture.rooms[String(HeadquartersCatalog.FINANCE)] = 4
	fixture.finance = 54000
	ProfileFile.replace(_path, fixture, false)
	var app := _launcher()
	app._screen.get_node("%Garden").pressed.emit()
	_check(app._screen is HeadquartersGarden and _labels(app._screen).contains("Build Ecology"), "Garden shortcut shows the shared Ecology requirement")
	app._go_back()
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	var ecology := _open_room(app, "ecology")
	_confirm_room(ecology)
	ecology._activity.pressed.emit()
	_check(app._screen is HeadquartersGarden and _labels(app._screen).contains("2 available plots") and _labels(app._screen).contains("Plot 6"), "Built Ecology reaches the same Garden with two open plots")
	app._go_back()
	app._go_back()
	app.free()
	await process_frame

	ProfileFile.replace(_path, fixture, false)
	app = _launcher()
	var progress: CampaignProgress = app._campaign_progress
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	var finance := _open_room(app, "finance_room")
	finance._claim.pressed.emit()
	_check("9,999 Funds" in finance._dialog.dialog_text and "44,001 Funds" in finance._dialog.dialog_text, "Manual overflow warns before permanently discarding")
	finance._dialog.hide()
	finance._dialog.canceled.emit()
	_check(progress.funds() == 9990000 and progress.finance_stored() == 54000, "Cancelling overflow preserves both balances")
	finance._claim.pressed.emit()
	finance._dialog.hide()
	finance._dialog.confirmed.emit()
	_check(progress.funds() == FundsWallet.CAP and progress.finance_stored() == 0 and "44,001" in finance._notice.text, "Confirming overflow reports the discarded amount and leaves wallet capped")
	app.free()
	await process_frame

func _launcher() -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	app.save_path = _path + ".legacy"
	root.add_child(app)
	app.set_process(false)
	return app

func _open_room(app: Control, id: String) -> HeadquartersRoomPage:
	_button(app, "Room_" + id).pressed.emit()
	return app._screen as HeadquartersRoomPage

func _button(app: Control, name: String) -> Button:
	return app._screen.find_child(name, true, false)

func _labels(page: Control) -> String:
	var labels := PackedStringArray()
	for label: Label in page.find_children("*", "Label", true, false):
		labels.append(label.text)
	return "\n".join(labels)

func _confirm_room(room: HeadquartersRoomPage) -> void:
	room._purchase.pressed.emit()
	room._dialog.hide()
	room._dialog.confirmed.emit()

func _confirm_levels(page: DeployableUpgradePage) -> void:
	page._buy.pressed.emit()
	page._dialog.hide()
	page._dialog.confirmed.emit()

func _cleanup() -> void:
	for base in [_path, _path + ".legacy"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".reset", ".reset.tmp"]:
			if FileAccess.file_exists(base + suffix):
				DirAccess.remove_absolute(base + suffix)

func _check(ok: bool, text: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", text)
