extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const SCOUT := &"ranger.scout_sniper"
const POST := &"facility.logistics_post"

var _path := "user://c34-mobile-menus-%d.json" % OS.get_process_id()
var _checks := 0
var _failures := 0
var _app: Control
var _text_percent := 130

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and DisplayServer.get_name() != "headless":
		var dimensions := args[0].split("x")
		root.size = Vector2i(dimensions[0].to_int(), dimensions[1].to_int())
		_text_percent = args[1].to_int()
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.funds = 300000
	profile.records["C1-01"] = {"cleared": true, "perfect": true}
	_check(ProfileFile.replace(_path, profile, false), "Seed an isolated profile after First Contact")
	_launch()
	await _story_journey()
	await _headquarters_journey()
	_app.free()
	await process_frame
	for suffix in ["", ".tmp", ".bak", ".bak.tmp", ".settings", ".settings.tmp", ".settings.bak"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C34 mobile menus: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _launch() -> void:
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _path
	_app.save_path = _path + ".legacy"
	root.add_child(_app)
	_app.set_process(false)
	_app.presentation.values.text = _text_percent
	_app._restyle()

func _story_journey() -> void:
	await _tap_named("OpenCampaign", Vector2(0.34, 0.25))
	_check(_app._screen is CampaignStoryPage, "Tap the illustrated Story card away from its label")
	var page := _app._screen as CampaignStoryPage
	if page == null:
		return
	var map_nodes := page.find_children("Operation_*", "BaseButton", true, false)
	_check(map_nodes.size() == 15, "Story map shows all 15 positions")
	for index in range(1, map_nodes.size()):
		var first: Rect2 = map_nodes[index - 1].get_global_rect()
		var second: Rect2 = map_nodes[index].get_global_rect()
		_check(not first.intersects(second) and second.size.x >= 84.0 and second.size.y >= 84.0,
			"%s remains at least 84 logical units and does not overlap" % map_nodes[index].name)
	await _tap_named("ToggleStoryView")
	var later := _button("Operation_C1_03") as Button
	_check(later.disabled and later.text.contains("C1-02"), "List shows the previous-operation gate on the card itself")
	var fog := _button("Operation_C2_01") as Button
	_check(fog.disabled and not fog.text.contains("Misty Approach"), "List keeps Control-fogged titles concealed")
	_check(_button("Operation_C1_02").size.y >= 80.0, "Story list uses a full-height action row")
	await _tap_named("Operation_C1_02")
	_check(_app._screen is Control and _app._route == &"plan", "Tap the available full-width mission row")
	var start := _button("StartOperation")
	var modifiers := _button("OpenModifiers")
	_check(start.size.y >= 76.0 and modifiers.size.y >= 68.0 and start.get_parent() == modifiers.get_parent(),
		"Start and modifiers stay together in the larger planning footer")
	await _tap_back()
	await _tap_back()

func _headquarters_journey() -> void:
	await _tap_named("OpenHeadquarters", Vector2(0.45, 0.30))
	_check(_app._screen is HeadquartersOverview, "Tap the illustrated Headquarters card away from its label")
	var rooms: Array[Node] = _app._screen.find_children("Room_*", "Button", true, false)
	_check(rooms.size() == 11, "All 11 headquarters departments have individual touch targets")
	for room: HeadquartersRoom in CampaignProgress.HEADQUARTERS.rooms:
		var name := "Room_" + String(room.id).get_slice(".", 1)
		var target := _button(name)
		_check(target.size.x >= 84 and target.size.y >= 72 and target.accessibility_name.contains(room.label),
			"%s has a sizable accessible illustrated hit area" % room.label)
		await _tap_named(name, Vector2(0.45, 0.68))
		var room_page := _app._screen as HeadquartersRoomPage
		_check(room_page != null and room_page.definition.id == room.id, "Tap inside %s to open its exact department" % room.label)
		await _tap_back()
	await _tap_named("Room_mechanical")
	var mechanical := _app._screen as HeadquartersRoomPage
	var funds: int = _app._campaign_progress.funds()
	var room_cost: int = _app._campaign_progress.room_quote(HeadquartersCatalog.MECHANICAL).cost
	await _tap_named("RoomPurchase")
	await _layout()
	_check(mechanical._dialog.visible and mechanical._dialog.get_cancel_button().has_focus(),
		"Mechanical build confirmation initially focuses Cancel")
	await _tap(mechanical._dialog.get_cancel_button(), Vector2(0.5, 0.5), mechanical._dialog)
	_check(_app._campaign_progress.funds() == funds and _app._campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) == 0,
		"Cancel leaves the saved wallet and unbuilt department intact")
	await _tap_named("RoomPurchase")
	await _tap(mechanical._dialog.get_ok_button(), Vector2(0.5, 0.5), mechanical._dialog)
	_check(_app._campaign_progress.funds() == funds - room_cost and _app._campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) == 1,
		"Confirm creates one Mechanical level and spends the exact cost")
	if _app._campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) != 1:
		return
	await _buy_level(POST, "Unit_logistics_post")
	await _tap_back()
	await _tap_back()
	await _tap_back()
	await _tap_named("Room_human_resources")
	await _buy_level(SCOUT, "Unit_scout_sniper")
	var balance: int = _app._campaign_progress.funds()
	_app.free()
	await process_frame
	_launch()
	await _layout()
	_check(_app._campaign_progress.funds() == balance and _app._campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) == 1
		and _app._campaign_progress.deployable_level(POST) == 20
		and _app._campaign_progress.deployable_level(SCOUT) == 20, "Cold launch restores both upgrades, room and exact balance")
	await _tap_named("OpenCampaign")
	await _tap_named("Operation_C1_02")
	await _tap_named("StartOperation")
	var battle := _app._screen as CampaignBattle
	_check(battle != null, "Start the newly available ordinary Story mission")
	if battle == null:
		return
	battle.set_physics_process(false)
	var controller := battle.get_node("%DeploymentController")
	await _tap(battle.get_node("%Skip"))
	_check(controller._offered[SCOUT].level == 20 and controller._offered[POST].level == 20,
		"Ordinary Story deployment uses both persisted upgrade tracks")
	await _drop(battle, POST, Vector2i(1, 0))
	for frame in 1200:
		if battle.battle.clock.dialogue_open:
			battle.get_node("%Skip").pressed.emit()
		battle.battle.clock.advance_frame()
	await _drop(battle, SCOUT, Vector2i(5, 2))
	var state := battle.battle.deployment
	_check(state.placed.has(SCOUT) and state.placed[SCOUT].spec.level == 20
		and state.placed.has(state.interaction_id(Vector2i(1, 0)))
		and state.placed[state.interaction_id(Vector2i(1, 0))].spec.level == 20,
		"Gameplay places the upgraded Post and Scout with tap-and-drag after restart")

func _buy_level(id: StringName, button_name: String) -> void:
	await _tap_named("RoomActivity")
	var card := _button(button_name)
	_check(card.size.y >= 108 and card.text.contains("Level 1"), "%s has a full-card owned and level action" % button_name)
	await _tap_named(button_name, Vector2(0.82, 0.78))
	var upgrade := _app._screen as DeployableUpgradePage
	if upgrade == null:
		_check(false, "Tap the full upgrade card")
		return
	for name in ["LowerTarget", "RaiseTarget", "Milestone20", "BuyLevels"]:
		_check(_button(name).size.y >= 64, "%s is at least 64 logical units tall" % name)
	await _tap_named("Milestone20")
	var quote: Variant = _app._campaign_progress.level_quote(id, 20)
	await _tap_named("BuyLevels")
	_check(upgrade._dialog.visible and upgrade._dialog.get_cancel_button().has_focus()
		and upgrade._dialog.get_ok_button().size.y >= 68, "Upgrade confirmation has broad actions and focuses Cancel")
	await _tap(upgrade._dialog.get_ok_button(), Vector2(0.5, 0.5), upgrade._dialog)
	_check(_app._campaign_progress.deployable_level(id) == 20 and _app._campaign_progress.funds() == quote.balance,
		"Confirm one %s upgrade and debit the exact quoted amount" % id)

func _button(name: String) -> BaseButton:
	return _app._screen.find_child(name, true, false) as BaseButton

func _tap_back() -> void:
	for child: Node in _app._screen.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text == "Back":
			await _tap(button)
			return
	_check(false, "Back button found")

func _tap_named(name: String, offset := Vector2(0.5, 0.5)) -> void:
	await _layout()
	await _tap(_button(name), offset)

func _tap(button: BaseButton, offset := Vector2(0.5, 0.5), window: Window = null) -> void:
	await _layout()
	if not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:
		_check(false, "Expected available button %s" % str(button))
		return
	var rect := button.get_global_rect()
	var at := rect.position + rect.size * offset
	if window != null:
		at += Vector2(window.position)
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * at
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var release := event.duplicate() as InputEventScreenTouch
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await _layout()

func _drop(battle: CampaignBattle, id: StringName, cell: Vector2i) -> void:
	var controller := battle.get_node("%DeploymentController")
	var index: int = controller._entries.find_custom(func(spec: DeploymentSpec) -> bool: return spec.id == id)
	var card: Control = controller._cards[index]
	(battle.get_node("%TrayScroll") as ScrollContainer).ensure_control_visible(card)
	await _layout()
	var start := root.get_final_transform() * card.get_global_rect().intersection(controller._tray_clip()).get_center()
	var target := root.get_final_transform() * (battle._board.get_global_transform_with_canvas() * battle._board.cell_center(cell))
	var press := InputEventScreenTouch.new()
	press.position = start
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	var drag := InputEventScreenDrag.new()
	drag.position = target
	drag.relative = target - start
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	var release := InputEventScreenTouch.new()
	release.position = target
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await _layout()

func _layout() -> void:
	await process_frame
	await process_frame

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
