extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const Fixture := preload("res://tests/fixtures/education/banks.gd")
const FIG := "species.strangler_fig"
const MENGARIS := "species.mengaris"
const START := 1000000

var _path := "user://c20-ui-%d.json" % OS.get_process_id()
var _now := START
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var data := CampaignSave.fresh()
	data.leader_name = "Garden UI QA"
	data.rooms[String(HeadquartersCatalog.ECOLOGY)] = 1
	data.rooms[String(HeadquartersCatalog.RECORDS)] = 1
	data.funds = FundsWallet.CAP - 100
	ProfileFile.replace(_path, data, false)
	await _garden_cycle()
	await _visitor_and_records()
	for suffix in ["", ".bak", ".bak.tmp", ".tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Restoration UI: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _garden_cycle() -> void:
	var app := _launcher(EducationCatalog.new())
	app._screen.get_node("%Garden").pressed.emit()
	await process_frame
	await process_frame
	_check(app._screen is HeadquartersGarden and _text(app, "2 available plots"), "Main Menu shortcut opens the playable shared Garden")
	_check(_button(app, "Plot1").text == "1 · Plant" and _button(app, "Plot3").text == "3 · Locked", "Available and locked plots use distinct text")
	var first := _button(app, "Plot1").get_global_rect()
	var second := _button(app, "Plot2").get_global_rect()
	var fourth := _button(app, "Plot4").get_global_rect()
	_check(first.size.y >= StoryUI.TOUCH_MINIMUM.y and not first.intersects(second) and not first.intersects(fourth), "Plot targets fit the landscape board without overlapping")
	await _tap(_button(app, "Plot6"))
	_check(_text(app, "Plot 6") and _text(app, "Requires Ecology Lv.5") and _button(app, "ChooseSeed") == null, "Touch selects the locked sixth plot and explains its Ecology gate")
	_press(app, "GardenGuide")
	_check(_text(app, "Rhinoceros Hornbill guide") and _text(app, "Field note awaiting approval") and not _text(app, "Synthetic"), "Garden guide explains growth and gates sourced copy by approval")
	_check(app._campaign_progress.discovered_facts() == [RestorationRules.GUIDE_FACT], "Guide click saves its fact reference even while approval is pending")
	_press(app, "Plot1")
	_press(app, "ChooseSeed")
	_check(app._screen.find_children("Plant_*", "Button", true, false).size() == 4 and _text(app, "in-game growth times"), "Picker offers four species and labels the durations as simulation values")
	_check(_button(app, "Plant_belian").text.contains("36h") and _button(app, "Plant_red_meranti").text.contains("48h") and _button(app, "Plant_mengaris").text.contains("72h"), "Picker displays each non-Fig duration")
	_press(app, "Plant_strangler_fig")
	_check(_text(app, "Strangler Fig") and _text(app, "Ready to water in 9h 00m") and _button(app, "WaterPlot") == null, "Planting displays a Seed and timer without early watering")
	_check(app._campaign_progress.funds() == FundsWallet.CAP - 100, "Live UI planting is free")
	app.free()
	await process_frame

	_now += 9 * 86400
	app = _launcher(_approved_facts())
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	_press(app, "Room_ecology")
	_press(app, "RoomActivity")
	await process_frame
	_check(app._screen is HeadquartersGarden and _text(app, "Growth paused at halfway") and _button(app, "Plot1").text == "1 · Water", "Cold start through HQ Ecology opens the same overdue Sapling")
	_press(app, "WaterPlot")
	_check(_text(app, "Sapling") and _text(app, "Ready to collect in 9h 00m") and _button(app, "CollectPlot") == null, "Late Water begins a fresh second half")
	_check(app._screen._board._active_effect == "water", "Successful Water plays its watering strip")
	_now += RestorationRules.midpoint(FIG)
	await process_frame
	await process_frame
	_check(_text(app, "Mature") and _button(app, "Plot1").text == "1 · Collect", "Open page updates to Mature at the saved boundary")
	_press(app, "CollectPlot")
	_check(_text(app, "20% restored") and _text(app, "100 Funds credited") and _text(app, "52,900 Funds discarded"), "Collection reflects the cap, milestone and actual awarded Funds")
	_check(_text(app, "Synthetic Fig note") and _text(app, "Synthetic source") and _text(app, "https://example.invalid/c19-fixture"), "Only approved-format fact text and citations appear in the receipt")
	_press(app, "ChooseSeed")
	_press(app, "Plant_belian")
	var garden: Dictionary = app._campaign_progress.garden_state()
	_check(garden.plots["garden_plot.01"].species == "species.belian" and garden.scenery["garden_plot.01"] == FIG, "Replanting draws a new cycle while retaining the mature scenery")
	app._go_back()
	_check(app._route == &"hq_room" and app._screen.definition.id == HeadquartersCatalog.ECOLOGY, "Back returns to the original Ecology entrance")
	app.free()
	await process_frame

func _visitor_and_records() -> void:
	var seed := ProfileFile.read(_path)
	seed.rooms[String(HeadquartersCatalog.ECOLOGY)] = 5
	ProfileFile.replace(_path, seed, false)
	var profile := CampaignProgress.new(_path)
	for species in ["species.belian", "species.red_meranti", MENGARIS]:
		var cycle := profile.plant_garden(5, species, _now)
		var water_at := _now + RestorationRules.midpoint(species)
		profile.water_garden(5, cycle, water_at)
		_now += RestorationRules.duration(species)
		if species != MENGARIS:
			profile.collect_garden(5, cycle, _now)
	var app := _launcher(_approved_facts())
	app._screen.get_node("%Garden").pressed.emit()
	_press(app, "GardenMilestones")
	_check(_text(app, "6 available plots") and _text(app, "60% restored") and _text(app, "100% · 1,250,000 Funds · Upcoming"), "Developed garden shows six plots and the full milestone track")
	_press(app, "Plot6")
	_press(app, "CollectPlot")
	_check(_text(app, "80% restored") and _text(app, "Nest box installed") and _text(app, "Synthetic nest note"), "Fourth species gives a visible nest-box announcement and approved field note")
	_check(app._screen._board._visitor_elapsed < GardenBoard.VISITOR_SECONDS, "Fourth species starts the one-shot visitor flight")
	app._go_back()
	_check(app._route == &"menu", "Back from the shortcut returns to the menu")
	app._screen.get_node("%Garden").pressed.emit()
	_check(app._screen._board._visitor_elapsed == GardenBoard.VISITOR_SECONDS and app._campaign_progress.garden_state().nest_box_seen, "Reopening retains the nest box without replaying the flight")
	var board: GardenBoard = app._screen._board
	_check(board._texture("garden_clearing.jpg") != null and board._texture("nest_box.png") != null and board._texture("hornbill_visitor.png") != null, "The live board resolves the clearing, nest box and visitor art")
	_press(app, "GardenGuide")
	_check(_text(app, "Synthetic guide note") and _text(app, "Synthetic Fig note") and _text(app, "Synthetic nest note"), "Guide keeps all approved discovered notes available")
	app._go_back()
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	_press(app, "Room_records")
	_press(app, "RoomActivity")
	_check(app._screen is RecordsArchivePage and _text(app, "Synthetic nest note") and _text(app, "Discovered"), "Records indexes Garden discoveries with locally installed citations")
	app.free()
	await process_frame

func _launcher(catalog: EducationCatalog) -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	app.education_catalog = catalog
	app.garden_time = func() -> int: return _now
	root.add_child(app)
	app.set_process(false)
	return app

func _approved_facts() -> EducationCatalog:
	var fixture := Fixture.payload()
	for pair in [[RestorationRules.GUIDE_FACT, "guide"], [RestorationRules.SPECIES[FIG].fact, "Fig"], [RestorationRules.NEST_FACT, "nest"]]:
		fixture.references.facts.append({"id": pair[0], "title": "Synthetic %s note" % pair[1], "text": "Garden QA fixture.", "source_ids": [Fixture.SOURCE]})
	return EducationCatalog.from_banks({}, {}, fixture.references)

func _tap(target: Button) -> void:
	var position := root.get_final_transform() * target.get_global_rect().get_center()
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func _button(app: Control, name: String) -> Button:
	return app._screen.find_child(name, true, false)

func _press(app: Control, name: String) -> void:
	var button := _button(app, name)
	if button != null:
		button.pressed.emit()
	else:
		_check(false, "Missing button %s" % name)

func _text(app: Control, value: String) -> bool:
	for label: Label in app._screen.find_children("*", "Label", true, false):
		if value in label.text:
			return true
	return false

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
