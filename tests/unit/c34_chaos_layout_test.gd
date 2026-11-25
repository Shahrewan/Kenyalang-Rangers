extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
var _save := "user://c34-chaos-layout-%d.json" % OS.get_process_id()
var _checks := 0
var _failures := 0
var _app: Control
var _output := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var fixture := CampaignSave.fresh()
	fixture.leader_name = "Rimba"
	fixture.rooms["room.mechanical"] = 2
	fixture.rooms["room.r_d_combat"] = 2
	_check(ProfileFile.replace(_save, fixture, false), "Create a disposable profile")
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _save
	root.add_child(_app)
	_app.set_process(false)
	var args := OS.get_cmdline_user_args()
	if args.size() == 3:
		_output = args[0]
		var dimensions := args[1].split("x")
		if not _output.is_empty():
			DirAccess.make_dir_recursive_absolute(_output)
		await _check_layout(Vector2i(int(dimensions[0]), int(dimensions[1])), int(args[2]))
	else:
		for layout: Array in [[960, 540, 100], [1280, 720, 115], [1920, 1080, 130], [1170, 540, 130], [1200, 540, 130]]:
			await _check_layout(Vector2i(layout[0], layout[1]), layout[2])
	_app.free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp", ".settings"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(_save + suffix)
	print("C34 Chaos controls and layouts: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check_layout(dimensions: Vector2i, text_scale: int) -> void:
	root.size = dimensions
	_app.presentation.values.text = text_scale
	_app.show_chaos()
	await _layout()
	var routes := _app._screen as ChaosRoutePage
	var route := _button("Route_T02")
	var configure := _button("ConfigureChaos")
	_check(route.size.y >= 64.0 and configure.size.y >= 72.0, "Route and Configure have enlarged targets")
	_check(configure.size.x > routes.size.x * 0.55 and _inside(routes, configure), "Configure occupies the thumb-side action column")
	_check(routes._board.size.x >= routes.size.x * 0.50, "W29 map preview uses half the safe width")
	var rank := routes.find_child("ChaosTrophyRank", true, false) as Label
	_check(rank.get_line_count() == 1 and _inside(routes, rank), "Trophy rank stays on one visible line")
	_tap(_button("Route_T05").get_global_rect().get_center())
	_check(routes.configuration.route_id == &"T05" and "Heat enabled" in routes._route_info.text, "Spatial press selects Imbak and updates Heat")
	_click(route.get_global_rect().get_center())
	await _capture("route-t02")
	routes.configuration.set_quantity(0, &"E01", 2)
	routes.configuration.set_quantity(0, &"E02", 1)
	_click(configure.get_global_rect().get_center())
	await _layout()

	var composer := _app._screen as ChaosComposer
	_check(composer != null, "Configure opens the live composer")
	if composer == null:
		return
	var first := _button("WaveSlot1")
	var fifth := _button("WaveSlot5")
	var increase := _button("Increase_E01")
	var decrease := _button("Decrease_E01")
	var slider := _app._screen.find_child("Quantity_E01", true, false) as HSlider
	var start := _button("StartChaos")
	_check(first.size.y >= 72.0 and fifth.size.y >= 72.0 and _inside(composer, fifth), "Full-height wave targets fit the safe width")
	_check(_large(increase, 68, 64) and _large(decrease, 68, 64) and _large(slider, 88, 64),
		"Enemy step buttons and slider reserve large touch areas")
	_check(not increase.get_global_rect().intersects(slider.get_global_rect()) and _inside(composer, increase),
		"Enemy increase and slider have independent hitboxes")
	_click(increase.get_global_rect().get_center())
	_check(composer.configuration.quantity(0, &"E01") == 3, "Spatial press increases only the current wave")
	_click(decrease.get_global_rect().get_center())
	_check(composer.configuration.quantity(0, &"E01") == 2, "Spatial press reverses the change")
	var enemy_scroll := composer.wave_editor._entries.get_parent() as ScrollContainer
	await _swipe(increase.get_global_rect().get_center())
	_check(enemy_scroll.scroll_vertical > 0 and composer.configuration.quantity(0, &"E01") == 2,
		"Touch starting on a quantity button can scroll without editing the wave")
	enemy_scroll.scroll_vertical = 0
	_click(fifth.get_global_rect().get_center())
	_check(composer.wave_editor.slot == 4 and _button("Decrease_E01").disabled, "Wave five keeps its separate composition")
	_click(first.get_global_rect().get_center())
	_check(start.size.y >= 72.0 and start.size.x > composer.size.x * 0.32 and _inside(composer, start), "Start remains large and visible beneath the scrollers")
	await _capture("chaos-waves")
	_click(_button("EditLoadout").get_global_rect().get_center())
	await _layout()
	_check(composer.show_loadout and _inside(composer, start), "Loadout keeps the start action visible")
	await _capture("chaos-loadout")
	_click(_button("OpenModifiers").get_global_rect().get_center())
	await _layout()
	var sheet := _app._screen as ModifierPicker
	_check(sheet != null, "Modifier tab opens the live catalog")
	if sheet == null:
		return
	await _capture("modifiers-buffs")
	_click(_button("ShowDebuffs").get_global_rect().get_center())
	await _layout()
	var debuff := _button("Modifier_D02")
	var beyond_label := debuff.get_global_rect().position + debuff.size * Vector2(0.86, 0.73)
	_click(beyond_label)
	_check(debuff.button_pressed and sheet.plan.modifier_selected(&"D02"), "Click on description side toggles the actual modifier")
	_click(beyond_label)
	_check(not sheet.plan.modifier_selected(&"D02"), "Second click deselects without duplicate action")
	var modifier_scroll := sheet._scroll
	await _swipe(beyond_label)
	_check(modifier_scroll.scroll_vertical > 0 and not sheet.plan.modifier_selected(&"D02"),
		"Touch starting on a modifier card scrolls without changing its selection")
	modifier_scroll.scroll_vertical = 0
	var apply := _button("ApplyModifiers")
	_check(sheet._list.columns == 2 and apply.size.y >= 70.0 and is_equal_approx(apply.size.x, sheet.size.x),
		"Modifier page uses two columns and a full-width Apply action")
	await _capture("modifiers-debuffs")

	var safe := _app.get_node("SafeArea") as MarginContainer
	var previous_left := safe.get_theme_constant("margin_left")
	var previous_right := safe.get_theme_constant("margin_right")
	safe.add_theme_constant_override("margin_left", 200)
	safe.add_theme_constant_override("margin_right", 200)
	await _layout()
	_check(sheet._list.columns == (2 if sheet.size.x >= 1000.0 else 1) and _inside(sheet, apply),
		"Simulated side insets update catalog columns and preserve Apply")
	safe.add_theme_constant_override("margin_left", previous_left)
	safe.add_theme_constant_override("margin_right", previous_right)
	await _layout()
	_click(apply.get_global_rect().get_center())
	_check(_app._screen is ChaosComposer and _app._screen.show_loadout, "Applying modifiers returns to the previous composer tab")

func _button(id: String) -> BaseButton:
	return _app._screen.find_child(id, true, false)

func _inside(page: Control, control: Control) -> bool:
	return page.get_global_rect().encloses(control.get_global_rect())

func _large(control: Control, width: float, height: float) -> bool:
	return control.size.x >= width and control.size.y >= height

func _tap(position: Vector2) -> void:
	for pressed: bool in [true, false]:
		_touch(position, pressed)

func _touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_screen_transform() * position
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _swipe(position: Vector2) -> void:
	var emulate := Input.is_emulating_touch_from_mouse()
	Input.set_emulate_touch_from_mouse(true)
	var target := position - Vector2(0, 135)
	_touch(position, true)
	var drag := InputEventScreenDrag.new()
	drag.position = root.get_screen_transform() * target
	drag.relative = drag.position - root.get_screen_transform() * position
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	_touch(target, false)
	Input.set_emulate_touch_from_mouse(emulate)
	await _layout()

func _click(position: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.global_position = position
		event.pressed = pressed
		root.push_input(event, true)

func _layout() -> void:
	await process_frame
	await process_frame
	await process_frame

func _capture(id: String) -> void:
	if _output.is_empty() or DisplayServer.get_name() == "headless":
		return
	await _layout()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == root.size and image.save_png(_output.path_join(id + ".png")) == OK,
		"Capture %s at native size" % id)

func _check(result: bool, message: String) -> void:
	_checks += 1
	if not result:
		_failures += 1
		printerr("FAIL ", message)
