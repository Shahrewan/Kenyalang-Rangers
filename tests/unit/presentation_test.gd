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
	_check(bank.music.stream.loop_end > 0, "Menu has a looping local score")
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
	_check(is_equal_approx(db_to_linear(bank.music.volume_db), 0.125), "Master and Music gains multiply")
	_check(db_to_linear(bank.effects.volume_db) == 0 and db_to_linear(bank.alerts.volume_db) == 0, "SFX mute includes critical alerts")
	var text: OptionButton = settings.find_child("TextSize", true, false)
	text.select(2)
	text.item_selected.emit(2)
	await process_frame
	_check(text.get_theme_font_size("font_size") == roundi(float(text.get_meta("base_font_size")) * 1.30), "Text scales to 130 percent")
	settings.find_child("ResetProgress", true, false).pressed.emit()
	app._go_back()
	_check(app._screen == settings and not settings._dialog.visible and app._campaign_progress.snapshot().leader_name == "Lina", "Back cancels the wipe and preserves progress")
	bank.path = "user://missing-c22-directory/settings"
	var slider := settings.find_child("MusicVolume", true, false) as HSlider
	slider.value = 90
	_check(slider.value == 25 and bank.values.music == 25 and _contains(settings, "Could not save volume"), "Failed settings write restores the previous value")
	app.free()
	await process_frame
	app = _launch()
	bank = app.presentation
	_check(bank.values == {"master": 50, "music": 25, "sfx": 0, "text": 130}, "Four preferences survive a cold launch")
	for route: String in ["battle", "chaos_battle", "hq_garden", "menu"]:
		bank.set_route(route)
		_check(bank.music.stream.loop_end > 0, "%s has a loop" % route)
	bank.change("sfx", 80)
	for id: String in PresentationAudio.CUES:
		bank.cue(id)
		var sound := PresentationAudio._sound(id, PresentationAudio.CUES[id], false)
		_check(sound.get_length() > 0 and sound.data.decode_s16(260) != 0, "%s has a non-silent PCM cue" % id)
	await _full_tray(app)
	app.free()
	await process_frame
	for suffix in ["", ".settings"]:
		DirAccess.remove_absolute(path + suffix)
	quit(1 if failed else 0)

func _full_tray(app: Control) -> void:
	var scene := FIELD.instantiate() as BattleScene
	var controller := scene.get_node("%DeploymentController")
	var roster := DeploymentRoster.new()
	var rangers: DeploymentRoster = load("res://data/rangers/c14_campaign_roster.tres")
	roster.entries.assign(rangers.entries)
	var eighth := rangers.entries[0].duplicate() as DeploymentSpec
	eighth.id = &"qa_eighth"
	roster.entries.append(eighth)
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
	scroll.scroll_horizontal = ceili(scroll.get_h_scroll_bar().max_value)
	await process_frame
	_check(scroll.get_global_rect().has_point(tray.get_child(13).get_global_rect().get_center()), "Last card is reachable at enlarged text size")
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var tick := scene.battle.clock.tick
	scene.battle.clock.advance_frame()
	_check(scene.battle.clock.tick == tick and scene.get_node("%PauseOverlay").visible, "Backgrounding opens pause inspection and holds the battle clock")

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
