extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const FIELD := preload("res://scenes/battle/sample_battle.tscn")
const BANK := preload("res://tests/fixtures/education/banks.gd")
var path := "user://c22-%d.json" % OS.get_process_id()
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var data := CampaignSave.fresh()
	data.leader_name = "Lina"
	data.rooms[String(HeadquartersCatalog.ECOLOGY)] = 1
	data.rooms[String(HeadquartersCatalog.RECORDS)] = 1
	ProfileFile.replace(path, data, false)
	var app := _launch()
	var bank: PresentationAudio = app.presentation
	_check(bank.music.stream is AudioStreamOggVorbis and bank.music.stream.loop, "Menu has a looping local score")
	var fixture: EducationCatalog = app.education_catalog
	app.education_catalog = EducationCatalog.new()
	app._screen.find_child("OpenFAQ", true, false).pressed.emit()
	_click(app._guide, "References")
	_check(_contains(app._guide, "Forest Department Sarawak") and _contains(app._guide, "iucnhornbills.org/rhinoceros-hornbill/"), "The standard offline reader includes both S53 source attributions")
	_check(_contains(app._guide, "Conservation articles await review") and not _contains(app._guide, "Synthetic fact"), "Cited sources are readable while the bank remains gated")
	_click(app._guide, FieldGuide.CREDITS)
	_check(_contains(app._guide, "Group SimSimi") and _contains(app._guide, "Permission is hereby granted"), "Credits and Godot license are readable offline")
	app._go_back()
	_check(_contains(app._guide, "Offline references"), "Credits return to the conservation source index")
	app._go_back()
	app._go_back()
	app.education_catalog = fixture
	app._screen.find_child("OpenFAQ", true, false).pressed.emit()
	_click(app._guide, "References")
	_check(_contains(app._guide, "Offline references"), "FAQ opens the offline References index")
	_click(app._guide, "Synthetic fact")
	_check(_contains(app._guide, "https://example.invalid"), "Approved article shows its offline source")
	app._go_back()
	app._go_back()
	_click(app._guide, "How do I deploy and retreat?")
	_check(_contains(app._guide, "Hold a Ranger"), "Help explains touch deployment")
	app._go_back()
	app._go_back()
	_check(app._guide == null and app._screen.visible, "Back restores the originating menu")
	app._screen.get_node("%Garden").pressed.emit()
	var garden: HeadquartersGarden = app._screen
	garden.find_child("GardenGuide", true, false).pressed.emit()
	_click(garden, "Read article")
	_check(is_instance_valid(app._guide) and _contains(app._guide, "Garden QA"), "Garden discovery opens its own cited article")
	app._go_back()
	_check(app._screen == garden and garden.visible and _contains(garden, "Rhinoceros Hornbill guide"), "Article Back restores the selected garden view")
	app._show_records(CampaignProgress.HEADQUARTERS.room(HeadquartersCatalog.RECORDS))
	var records: RecordsArchivePage = app._screen
	_click(records, "Read article")
	app._go_back()
	_check(app._guide == null and app._screen == records and records.visible, "Article Back restores the Records archive")
	app.show_menu()
	app._screen.get_node("%OpenSettings").pressed.emit()
	var settings: ProfileSettingsPage = app._screen
	settings.find_child("MusicVolume", true, false).value = 25
	settings.find_child("MasterVolume", true, false).value = 50
	settings.find_child("SfxVolume", true, false).value = 0
	var music_bus := AudioServer.get_bus_index(&"Music")
	var master_bus := AudioServer.get_bus_index(&"Master")
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(master_bus) * AudioServer.get_bus_volume_linear(music_bus), 0.0625), "Master and perceptual Music gains multiply")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")) and bank.effects.bus == &"SFX" and bank.alerts.bus == &"SFX", "SFX mute includes critical alerts")
	var text := settings.find_child("TextSize130", true, false) as Button
	await _touch(text)
	await process_frame
	_check(text.button_pressed and text.get_theme_font_size("font_size") == roundi(float(text.get_meta("base_font_size")) * 1.30), "Touch selects 130 percent and scales the preset label")
	_check(settings.find_children("TextSize*", "Button", true, false).all(func(button: Button) -> bool:
		return button.size.y >= StoryUI.TOUCH_MINIMUM.y and settings.get_global_rect().encloses(button.get_global_rect())
	), "All text presets fit the shared touch footprint in landscape")
	settings.find_child("ResetProgress", true, false).pressed.emit()
	_click(settings, "Back")
	_check(app._screen == settings and not settings._dialog.visible and app._campaign_progress.snapshot().leader_name == "Lina", "Visible Back cancels the wipe and preserves progress")
	bank.path = "user://missing-c22-directory/settings"
	var slider := settings.find_child("MusicVolume", true, false) as HSlider
	slider.value = 90
	_check(slider.value == 25 and bank.values.music == 25 and _contains(settings, "Could not save volume"), "Failed settings write restores the previous value")
	await _touch(settings.find_child("TextSize115", true, false))
	_check(text.button_pressed and bank.values.text == 130 and _contains(settings, "Could not save text size"), "Failed text-size write restores the selected preset")
	app.free()
	await process_frame
	app = _launch()
	bank = app.presentation
	_check(bank.values == {"master": 50, "music": 25, "sfx": 0, "text": 130}, "Four preferences survive a cold launch")
	for route: String in ["battle", "chaos_battle", "hq_garden", "menu"]:
		bank.set_route(route)
		_check(bank.music.stream is AudioStreamOggVorbis and bank.music.stream.loop, "%s has a loop" % route)
	bank.change("sfx", 80)
	for id: String in PresentationAudio.CUES:
		bank.cue(id)
		var sound := PresentationAudio._sound(id, PresentationAudio.CUES[id], false)
		_check(sound.get_length() > 0 and sound.data.decode_s16(260) != 0, "%s has a non-silent PCM cue" % id)
	await _story_pause(app)
	await _full_tray(app)
	app.free()
	await process_frame
	for suffix in ["", ".bak", ".settings"]:
		DirAccess.remove_absolute(path + suffix)
	quit(1 if failed else 0)

func _story_pause(app: Control) -> void:
	app._screen.get_node("%OpenCampaign").pressed.emit()
	app._screen.find_child("Operation_C1_01", true, false).pressed.emit()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	var clock := field.battle.clock
	clock.set_speed(2)
	clock.advance_frame()
	_check(clock.tick == 0 and field.get_node("Content").focus_behavior_recursive == Control.FOCUS_BEHAVIOR_DISABLED and _contains(field, "Story paused"), "The Story modal owns focus and keeps the 2× opening at tick zero")
	field.get_node("%Continue").pressed.emit()
	clock.advance_frame()
	_check(clock.tick == 0 and field._portrait.identity == "portrait.leader", "Continue shows the Leader portrait while the clock remains held")
	field.get_node("%Skip").pressed.emit()
	clock.advance_frame()
	_check(clock.tick == 2 and field.get_node("Content").focus_behavior_recursive == Control.FOCUS_BEHAVIOR_INHERITED, "Skip closes the beat and resumes the same 2× clock")

	var overlay: Control = field.get_node("%PauseOverlay")
	field.get_node("%Pause").pressed.emit()
	overlay.find_child("PauseSettings", true, false).grab_focus()
	overlay.find_child("PauseSettings", true, false).pressed.emit()
	var settings := app._battle_settings as ProfileSettingsPage
	_check(settings.is_visible_in_tree() and not field.visible and settings.find_child("ResetProgress", true, false) == null, "Paused Settings exposes presentation controls within the same active operation")
	settings.find_child("MusicVolume", true, false).value = 35
	_click(settings, "Help and references")
	app._go_back()
	_check(settings.visible and not field.visible and app.presentation.values.music == 35, "Back from help restores the active battle Settings and its changed value")
	app._go_back()
	_check(app._screen == field and field.visible and overlay.visible and clock.paused and root.gui_get_focus_owner().name == "PauseSettings", "Settings Back restores the original pause overlay and focus")
	overlay.find_child("PauseControls", true, false).pressed.emit()
	clock.advance_frame()
	_check(_contains(app._guide, "Battle controls") and clock.tick == 2 and clock.get_speed() == 2, "Pause controls help shares the frozen 2× operation")
	app._go_back()
	overlay.find_child("AskAbandon", true, false).pressed.emit()
	app._go_back()
	_check(overlay.visible and clock.paused and overlay.find_child("ResumeOperation", true, false).is_visible_in_tree(), "Back cancels abandon to the same pause screen")
	overlay.find_child("ResumeOperation", true, false).pressed.emit()
	clock.advance_frame()
	_check(clock.tick == 4 and field.battle.integrity == 100 and field.battle.deployment.tokens == 0, "Explicit Resume advances the same battle with the original Integrity and Tokens")

	app.presentation.change("sfx", 0)
	field.battle.siege_hit.emit()
	field.battle.heat_overflow.emit()
	field._refresh()
	_check("Siege hit" in field._status.text and "Heat overflow" in field._status.text, "Overlapping critical alerts both have visible feedback with sound muted")
	field.get_node("%Pause").pressed.emit()
	overlay.find_child("AskAbandon", true, false).pressed.emit()
	overlay.find_child("ConfirmAbandon", true, false).pressed.emit()
	_check(app._route == &"plan" and app._campaign_progress.snapshot().pending_attempt == "", "Confirmed abandon returns to the retained plan and closes the saved attempt")
	app.show_menu()
	app.presentation.change("sfx", 80)
	await process_frame

func _full_tray(app: Control) -> void:
	var scene := FIELD.instantiate() as BattleScene
	var controller := scene.get_node("%DeploymentController")
	var roster := DeploymentRoster.new()
	var rangers: DeploymentRoster = load("res://data/rangers/c14_campaign_roster.tres")
	roster.entries.assign(rangers.entries.slice(0, 8))
	var facilities: DeploymentRoster = load("res://data/facilities/catalog.tres")
	roster.entries.append_array(facilities.entries.slice(0, 6))
	controller.roster = roster
	controller.support_entries.clear()
	controller.preview_budget = 1000
	scene.sandbox = true
	app._present(scene, &"sample")
	await process_frame
	await process_frame
	var scroll: ScrollContainer = scene.get_node("%TrayScroll")
	var tray: HBoxContainer = scene.get_node("%DeploymentTray")
	_check(tray.get_child_count() == 14 and tray.size.x > scroll.size.x, "Eight Rangers and six Facilities share one horizontally scrolling tray")
	var initial_tokens := scene.battle.deployment.tokens
	var clip: Rect2 = controller._tray_clip()
	var y := clip.get_center().y
	for swipe in 4:
		_drag(Vector2(clip.end.x - 40, y), Vector2(clip.position.x + 40, y))
		await process_frame
	_check(scroll.scroll_horizontal > 0 and scroll.get_global_rect().has_point(tray.get_child(13).get_global_rect().get_center()), "Synthetic touch swipes reach the last card at 130 percent")
	_check(scene.battle.deployment.tokens == initial_tokens and scene.battle.deployment.occupancy.is_empty(), "Repeated tray swipes leave Tokens and occupancy intact")
	await _placement_feedback(scene, controller, tray)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var tick := scene.battle.clock.tick
	scene.battle.clock.advance_frame()
	_check(scene.battle.clock.tick == tick and scene.get_node("%PauseOverlay").visible, "Backgrounding opens pause inspection and holds the battle clock")

func _placement_feedback(scene: BattleScene, controller: Node, tray: Control) -> void:
	scene.set_physics_process(false)
	var board: BattleBoard = scene.get_node("%Board")
	var state := scene.battle.deployment
	var ground: Vector2i = scene.stage.map.ground[0]
	var at := board.get_global_transform_with_canvas() * board.cell_center(ground)
	var facility_index: int = controller._entries.find_custom(func(spec: DeploymentSpec) -> bool: return spec.kind == DeploymentSpec.Kind.FACILITY_PAIR)
	var facility_card := tray.get_child(facility_index) as Control
	var scroll: ScrollContainer = scene.get_node("%TrayScroll")
	scroll.ensure_control_visible(facility_card)
	await process_frame
	var original_tokens := state.tokens
	_drag(facility_card.get_global_rect().get_center(), at)
	var reason := board.find_child("PlacementError", true, false) as Label
	_check(reason.is_visible_in_tree() and "two adjacent elevated tiles" in reason.text and board.get_global_rect().encloses(reason.get_parent().get_global_rect()), "An invalid drop anchors the exact reason inside the field")
	_check(state.tokens == original_tokens and state.occupancy.is_empty() and state.clock.is_running(), "Rejected drop leaves Tokens and occupancy intact while combat can advance")

	var ranger_index: int = controller._entries.find_custom(func(spec: DeploymentSpec) -> bool: return spec.is_melee())
	var ranger: DeploymentSpec = controller._entries[ranger_index]
	var card := tray.get_child(ranger_index) as Control
	scroll.ensure_control_visible(card)
	await process_frame
	var from := card.get_global_rect().get_center()
	state.tokens = ranger.cost - 1
	_drag(from, at)
	_check(reason.is_visible_in_tree() and reason.text == "Need 1 more Logistic Tokens." and state.tokens == ranger.cost - 1, "Token shortfall uses the same local warning without a spend")
	state.tokens = original_tokens
	_drag(from, at)
	scene.find_child("FaceLeft", true, false).pressed.emit()
	scene.find_child("ConfirmDeploy", true, false).pressed.emit()
	var deployed := state.placed.has(ranger.id)
	_check(deployed, "Choosing facing and confirming commits the legal placement")
	if deployed:
		_send_touch(at, true)
		await create_timer(0.40).timeout
		var retreat: Button = scene.get_node("%Retreat")
		var release_at := retreat.get_global_rect().get_center()
		_send_touch(release_at, false)
		_check(not state.placed.has(ranger.id) and state.cooldown_ticks(ranger.id) > 0, "A hold and release onto the nearby Retreat button starts redeploy cooldown")
		_drag(from, at)
		_check("Ready to deploy in %d s." % ceili(float(state.cooldown_ticks(ranger.id)) / CombatClock.TICKS_PER_SECOND) == reason.text, "Redeploy feedback shows the remaining combat-time seconds")

func _drag(from: Vector2, to: Vector2) -> void:
	_send_touch(from, true)
	var drag := InputEventScreenDrag.new()
	drag.position = to
	drag.relative = to - from
	root.push_input(drag, true)
	_send_touch(to, false)

func _send_touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	root.push_input(event, true)

func _touch(button: Button) -> void:
	await process_frame
	await process_frame
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * button.get_global_rect().get_center()
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func _launch() -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = path
	var fixture := BANK.payload()
	fixture.references.facts.append({"id": RestorationRules.GUIDE_FACT, "title": "Garden QA", "text": "Synthetic guide note.", "source_ids": [BANK.SOURCE]})
	app.education_catalog = EducationCatalog.from_banks(fixture.outreach, fixture.records, fixture.references)
	root.add_child(app)
	return app

func _click(parent: Node, caption: String) -> void:
	for button: Button in parent.find_children("*", "Button", true, false):
		if button.text == caption:
			button.pressed.emit()
			return
	_check(false, "Missing button " + caption)

func _contains(parent: Node, fragment: String) -> bool:
	for label: Label in parent.find_children("*", "Label", true, false):
		if fragment in label.text:
			return true
	return false

func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		failed += 1
		printerr("FAIL ", message)
