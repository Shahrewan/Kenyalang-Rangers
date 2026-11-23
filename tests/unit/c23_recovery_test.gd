extends SceneTree

var path := "user://c23-recovery-%d.json" % OS.get_process_id()
var failures := 0

func _initialize() -> void:
	var config := ChaosConfiguration.new()
	config.set_quantity(0, &"E01", 1)
	var setup := ModifierSetup.new()
	setup.chaos = true
	setup.stage = config.build_stage()
	setup.loadout.append(DeployableLevels.definition(&"facility.logistics_post"))
	var plan := setup.resolve([], [])
	var profile := CampaignProgress.new(path)
	var run := profile.begin_chaos(config, plan, [&"facility.logistics_post"], [])
	_check(run != null, "Real Chaos attempt creates a durable draft")
	DirAccess.make_dir_absolute(path + ".tmp")
	_check(not profile.abandon_chaos(run) and not profile.pending_chaos_configuration().is_empty(), "Failed abandon retains the saved draft")
	DirAccess.remove_absolute(path + ".tmp")
	_check(profile.begin_chaos(config, plan, [], []) == null, "Failed abandon keeps ownership of the running attempt")
	_check(profile.abandon_chaos(run) and CampaignProgress.new(path).pending_chaos_configuration().is_empty(), "Retry after storage recovery durably clears the draft")

	var saved := CampaignSave.fresh()
	saved.rooms["room.ecology"] = 1
	saved.rooms["room.records"] = 2
	ProfileFile.replace(path, saved, false)
	profile = CampaignProgress.new(path)
	_check(not profile.begin_quiz(&"records_chapter.scout_sniper", ["q"], -1) and CampaignProgress.new(path).load_status == CampaignProgress.LoadStatus.READY, "An invalid quiz revision cannot publish an unreadable primary")
	var cycle := profile.plant_garden(0, "species.belian", 1000)
	var damaged := profile.snapshot()
	damaged.garden.settled_awards.append(cycle)
	ProfileFile.replace(path, damaged, true)
	profile = CampaignProgress.new(path)
	_check(profile.load_status == CampaignProgress.LoadStatus.RECOVERED and profile.garden_state().settled_awards.is_empty(), "An impossible active and settled cycle recovers the last playable plot")
	_check(profile.water_garden(0, cycle, 1000 + 18 * 3600), "Recovered plant can be watered")
	var claim := profile.collect_garden(0, cycle, 1000 + 36 * 3600)
	_check(claim.get("credited") == 58000 and CampaignProgress.new(path).collect_garden(0, cycle, 1000 + 36 * 3600).is_empty(), "Recovered harvest pays species and milestone exactly once")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	quit(1 if failures else 0)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		failures += 1
		push_error(label)
