extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")

var _path := "user://c15-ui-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0
var _output := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		root.size = Vector2i(960, 540)
	else:
		_output = args[0]
		DirAccess.make_dir_recursive_absolute(_output)
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
	_assert_layout(overview)
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
	await _illustrated_headquarters()
	_cleanup()
	print("Headquarters UI: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _illustrated_headquarters() -> void:
	var fixture := CampaignSave.fresh()
	fixture.leader_name = "C29 review"
	ProfileFile.replace(_path, fixture, false)
	var app := _launcher()
	var progress: CampaignProgress = app._campaign_progress
	var overview := await _open_headquarters(app)
	for room in CampaignProgress.HEADQUARTERS.rooms:
		var office := overview._rooms[room.id]
		_check((office.staff != null) == room.starts_built() and office.stage.has_node("EmptyRoom") != room.starts_built(),
			"%s follows its authored starting state" % room.label)
	_check(overview._lobby.name == "TrophyTier0" and overview._lobby.has_node("Mount") and not overview._lobby.has_node("Emblem"),
		"Opening day shows the registered unranked mount")
	await _capture("fresh-headquarters")
	var workshop := await _tap_room(app, &"room.mechanical")
	_check(workshop._purchase.disabled and workshop._art.staff == null and workshop._art.stage.has_node("EmptyRoom"),
		"Unbuilt Mechanical uses the empty art and shows the existing Funds gate")
	await _capture("mechanical-unbuilt")
	progress.adjust_developer_funds(30000)
	workshop._refresh()
	_confirm_room(workshop)
	_check(workshop._art.staff != null and workshop._art.stage.has_node("RoomBack") and workshop._art.stage.has_node("RoomFront")
		and workshop._status.text == "Level 1 of 5" and workshop._balance.text == "20,000 Funds",
		"Building Mechanical refreshes its same room page, staff, level and wallet")
	await _capture("mechanical-built")
	workshop.back_requested.emit()
	await _layout_frames()
	overview = app._screen
	_check(overview._rooms[&"room.mechanical"].player != null and overview._rooms[&"room.r_d_eco"].player == null,
		"An established profile shows the purchased room while unopened modules stay empty")
	await _capture("established-headquarters")
	app.free()
	await process_frame

	fixture.funds = 1350000
	fixture.chaos.personal_best = 3300
	for index in CampaignProgress.HEADQUARTERS.rooms.size():
		var room := CampaignProgress.HEADQUARTERS.rooms[index]
		fixture.rooms[String(room.id)] = 4 if room.id in [HeadquartersCatalog.ECOLOGY, HeadquartersCatalog.OUTREACH] else index % 5 + 1
	ProfileFile.replace(_path, fixture, false)
	app = _launcher()
	overview = await _open_headquarters(app)
	_check(overview._rooms.size() == 11 and overview._rooms.values().all(func(office: HeadquartersOfficeArt) -> bool:
		return office.player != null and office.player.current_animation == &"Work"), "Eleven constructed departments each play their own Work loop")
	await _capture("developed-headquarters")
	_check(overview._lobby.name == "TrophyTier3" and overview._lobby.get_node("Emblem").texture.resource_path.ends_with("tier_3000.png"),
		"Saved score above 3000 uses the approved third trophy")
	_check(overview._lobby.get_node("Mount").position.is_equal_approx(
		HeadquartersArt.point(overview._catalog.data.trophy_anchor) - Vector2(24, 48 * 154.0 / 160.0)),
		"The trophy is centered on the W29 lobby anchor")
	for office: HeadquartersOfficeArt in overview._rooms.values():
		_check_work_animation(office, overview._catalog.rooms[office.room_id].staff)
	if not _output.is_empty():
		await create_timer(0.55).timeout
	await _capture("staff-at-work")
	var current := overview._rooms[&"room.control_room"]
	overview.hide()
	_check(not current.player.active, "Hidden Headquarters pauses its Work animations")
	overview.show()
	_check(current.player.active, "Visible Headquarters resumes Work playback")
	current.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(not current.player.active, "App pause suspends staff")
	current.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(current.player.active, "App resume restores visible staff playback")
	app.presentation.values.text = 130
	app._restyle()
	await _layout_frames()
	_assert_layout(overview)
	await _capture("developed-headquarters-130-percent")
	var last_size := root.size
	if _output.is_empty():
		root.size = Vector2i(1280, 720)
		await _layout_frames()
		_assert_layout(overview)
	for room in CampaignProgress.HEADQUARTERS.rooms:
		var page := await _tap_room(app, room.id)
		if page == null:
			break
		var actual: CampaignProgress = app._campaign_progress
		_check(page._status.text == "Level %d of 5" % actual.room_level(room.id) and page._art.room_id == room.id,
			"Room page keeps the saved level and the selected artwork for %s" % room.label)
		if room.id in [HeadquartersCatalog.ECOLOGY, HeadquartersCatalog.OUTREACH]:
			_check(page._purchase.disabled and "Requires" in page._requirement.text, "%s retains the participation gate" % room.label)
		if room.id in [&"room.control_room", &"room.records", &"room.r_d_crisis"]:
			await _capture(String(room.id).get_slice(".", 1) + "-detail")
		if page._activity != null and page._activity.visible:
			var target := _activity_route(room)
			page._activity.pressed.emit()
			_check(app._route == target, "%s opens its existing activity" % room.label)
			app._go_back()
			page = app._screen as HeadquartersRoomPage
		page.back_requested.emit()
		await _layout_frames()
	root.size = last_size
	await _layout_frames()
	_button(app, "HeadquartersChaos").pressed.emit()
	_check(app._route == &"chaos_routes", "The registered lobby control opens Rainforest Chaos")
	app._go_back()
	_check(app._screen is HeadquartersOverview and app._screen._lobby.name == "TrophyTier3",
		"Returning from Chaos reconstructs the living lobby from the same saved score")
	await _layout_frames()
	await _capture("trophy-lobby", Rect2(app._screen._lobby.get_node("Mount").get_global_transform_with_canvas().origin - Vector2(80, 35), Vector2(275, 126)))
	await _scrolled_touch(app)
	app.free()
	await process_frame
	for score in [999, 1000, 2000, 3000]:
		fixture.chaos.personal_best = score
		ProfileFile.replace(_path, fixture, false)
		app = _launcher()
		overview = await _open_headquarters(app)
		var tier := ChaosScore.tier(score)
		_check(overview._lobby.name == "TrophyTier%d" % tier and (tier == 0 or
			overview._lobby.get_node("Emblem").texture.resource_path.ends_with("tier_%d.png" % score)),
			"Reload shows the existing trophy tier at %d" % score)
		app.free()
		await process_frame

func _assert_layout(overview: HeadquartersOverview) -> void:
	for id: StringName in overview._rooms:
		var button: Button = overview.find_child("Room_" + String(id).get_slice(".", 1), true, false)
		var office := overview._rooms[id]
		var hitbox := button.get_global_rect()
		var canonical := HeadquartersArt.rectangle(overview._catalog.rooms[id].rect)
		var art_bounds := overview._shell.get_global_transform() * canonical
		var status: Label = button.find_child("RoomLevel", true, false)
		_check(hitbox.is_equal_approx(art_bounds) and hitbox.is_equal_approx(office.get_global_rect())
			and overview.get_global_rect().encloses(hitbox) and status.get_line_count() == 1,
			"%s keeps a registered, readable hit area" % id)

func _check_work_animation(office: HeadquartersOfficeArt, meta: Dictionary) -> void:
	var player := office.player
	var staff := office.staff
	var path := "Facing/Skeleton/"
	var hand: Bone2D = staff.get_node(path + "torso/hand")
	var feet: Bone2D = staff.get_node(path + "legs")
	var duration := player.current_animation_length
	player.seek(0.0, true)
	var stable := feet.transform
	player.advance(duration * 0.25)
	var pose := hand.rotation
	player.advance(duration * 0.80)
	_check(absf(pose) > 0.01 and player.current_animation_position < duration * 0.1
		and feet.transform.is_equal_approx(stable) and staff.position == HeadquartersArt.point(meta.anchor_in_room)
		and staff.scale == Vector2.ONE * float(meta.scale) and office.stage.get_node("RoomFront").z_index > hand.z_index,
		"%s works in a loop behind its foreground with feet planted" % office.room_id)

func _scrolled_touch(app: Control) -> void:
	var overview := app._screen as HeadquartersOverview
	overview.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	overview.size = Vector2(780, 396)
	await _layout_frames()
	var destination := _button(app, "Room_r_d_crisis")
	overview._scroll.ensure_control_visible(destination)
	await _layout_frames()
	_check(overview._scroll.scroll_vertical > 0 and overview._scroll.get_global_rect().has_point(destination.get_global_rect().get_center()),
		"A constrained Headquarters scrolls the registered room into reach")
	await _tap_room(app, &"room.r_d_crisis")

func _open_headquarters(app: Control) -> HeadquartersOverview:
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	await _layout_frames()
	return app._screen as HeadquartersOverview

func _layout_frames() -> void:
	await process_frame
	await process_frame

func _tap_room(app: Control, id: StringName) -> HeadquartersRoomPage:
	var button := _button(app, "Room_" + String(id).get_slice(".", 1))
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.pressed = pressed
		root.push_input(touch, true)
	Input.flush_buffered_events()
	await _layout_frames()
	var page := app._screen as HeadquartersRoomPage
	_check(page != null and page.definition.id == id, "Touch inside %s opens the right department" % id)
	return page

func _activity_route(room: HeadquartersRoom) -> StringName:
	match room.role:
		HeadquartersRoom.Role.CONTROL:
			return &"story"
		HeadquartersRoom.Role.HR, HeadquartersRoom.Role.MECHANICAL:
			return &"hq_roster"
		HeadquartersRoom.Role.ECOLOGY:
			return &"hq_garden"
		HeadquartersRoom.Role.OUTREACH:
			return &"outreach"
		_:
			return &"records"

func _capture(name: String, bounds := Rect2()) -> void:
	if _output.is_empty():
		return
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if bounds.has_area():
		var display := Vector2(frame.get_size()) / root.get_visible_rect().size
		frame = frame.get_region(Rect2i(bounds.position * display, bounds.size * display))
	_check(frame.save_png(_output.path_join(name + ".png")) == OK, "Captured " + name)

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
	app._screen.find_child("Plot6", true, false).pressed.emit()
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
