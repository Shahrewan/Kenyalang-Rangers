extends SceneTree

const PATH := "user://c23-interruption.json"
const BANK := preload("res://tests/fixtures/education/banks.gd")
const NOW := 1700000000

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog := BANK.catalog()
	if args[0] == "seed":
		var fresh := CampaignSave.fresh()
		fresh.rooms["room.ecology"] = 1
		fresh.rooms["room.outreach"] = 1
		if not ProfileFile.replace(PATH, fresh, false):
			quit(1)
			return
	var profile := CampaignProgress.new(PATH)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var session := OutreachSession.new(profile, catalog, rng)
	if args[0] == "seed":
		var planted := profile.plant_garden(0, "species.belian", NOW)
		if planted.is_empty() or not session.refresh(NOW):
			quit(1)
			return
		var id: String = session.batch().batch[0]
		var best_index: int = session.batch().choice_order[id].find(0)
		if session.submit(id, best_index, NOW).get("credited", 0) != 25000:
			quit(1)
			return
		# Model an interrupted *next* write after the two real commits. Leave
		# the partial scratch file open until the harness kills this process.
		var partial := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
		partial.store_string('{"version":2,"funds":')
		partial.flush()
		var marker := FileAccess.open(args[1], FileAccess.WRITE)
		marker.store_string("ready")
		marker.close()
		while true:
			OS.delay_msec(100)
	var garden := profile.garden_state()
	var plot: Dictionary = garden.plots.get(RestorationRules.plot_id(0), {})
	var batch := session.batch()
	var ok := profile.load_status == CampaignProgress.LoadStatus.READY and profile.funds() == 35000
	ok = ok and batch.responses.size() == 1 and session.seconds_until_refresh(NOW + 71999) == 1
	ok = ok and session.submit(batch.batch[0], 0, NOW + 1).is_empty() and not plot.is_empty()
	ok = ok and RestorationRules.needs_water(plot, NOW + 36 * 3600)
	ok = ok and profile.water_garden(0, plot.cycle_id, NOW + 36 * 3600)
	ok = ok and profile.collect_garden(0, plot.cycle_id, NOW + 54 * 3600).get("credited") == 58000
	ok = ok and CampaignProgress.new(PATH).funds() == 93000
	print("Process-kill recovery: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
