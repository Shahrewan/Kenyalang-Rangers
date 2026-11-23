extends SceneTree

const FIG := "species.strangler_fig"
const BELIAN := "species.belian"
const MERANTI := "species.red_meranti"
const MENGARIS := "species.mengaris"
const FIRST := "garden_plot.01"
const ECOLOGY := HeadquartersCatalog.ECOLOGY
const START := 1000000

var _paths: PackedStringArray
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_species()
	_offline_and_clock_changes()
	_settlements_and_ecology()
	_save_failure_and_wallet_cap()
	_legacy_and_reset()
	for path in _paths:
		for suffix in ["", ".bak", ".bak.tmp", ".tmp", ".reset"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	print("Restoration rules: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _species() -> void:
	var times := {FIG: 64800, BELIAN: 129600, MERANTI: 172800, MENGARIS: 259200}
	_check(RestorationRules.SPECIES.keys() == times.keys(), "Exactly the four named species are available")
	var path := _seed("species", 1, 50000)
	var profile := CampaignProgress.new(path)
	for species: String in times:
		var finish: int = START + times[species]
		var middle := START + RestorationRules.midpoint(species)
		var cycle := profile.plant_garden(0, species, START)
		var plot := _first(profile)
		_check(not cycle.is_empty() and finish == START + RestorationRules.duration(species), "%s is free to plant and has its configured duration" % species)
		_check(RestorationRules.stage(plot, middle - 1) == RestorationRules.Stage.SEED and not profile.water_garden(0, cycle, middle - 1), "Seed does not accept early water")
		_check(RestorationRules.stage(plot, middle) == RestorationRules.Stage.SAPLING and RestorationRules.needs_water(plot, middle), "Midpoint changes the stage to Sapling and asks for water")
		_check(profile.water_garden(0, cycle, middle) and not profile.water_garden(0, cycle, middle + 1), "A cycle accepts water exactly once")
		_check(not RestorationRules.needs_water(_first(profile), finish - 1) and RestorationRules.remaining(_first(profile), finish - 1) == 1, "Second half uses its full duration")
		_check(profile.collect_garden(0, cycle, finish - 1).is_empty(), "A sapling cannot settle early")
		_check(RestorationRules.stage(_first(profile), finish) == RestorationRules.Stage.MATURE and not profile.collect_garden(0, cycle, finish).is_empty(), "Only a mature cycle can settle")

func _offline_and_clock_changes() -> void:
	var path := _seed("time", 0, 100000)
	var profile := CampaignProgress.new(path)
	_check(profile.plant_garden(0, FIG, START).is_empty() and not profile.visit_garden_guide(), "Unbuilt Ecology has no planting or guide discovery")
	_check(profile.purchase_room(ECOLOGY).is_empty() and profile.room_capacity(ECOLOGY) == 2, "Ecology opens two plots")
	var original := profile.snapshot()
	_check(profile.plant_garden(-1, FIG, START).is_empty() and profile.plant_garden(2, FIG, START).is_empty() and profile.plant_garden(6, FIG, START).is_empty(), "Unknown or locked slots reject planting")
	_check(profile.plant_garden(0, "species.missing", START).is_empty() and profile.plant_garden(0, FIG, 0).is_empty() and profile.plant_garden(0, FIG, CampaignActivities.LAST_TIMESTAMP + 1).is_empty(), "Unknown species and invalid times reject planting")
	_check(profile.snapshot() == original, "Invalid planting changes no persistence or Funds")
	var cycle := profile.plant_garden(0, FIG, START)
	var next := profile.snapshot()
	_check(profile.plant_garden(0, BELIAN, START + 1).is_empty() and profile.snapshot() == next, "Occupied plot preserves the current cycle and wallet")
	profile = CampaignProgress.new(path)
	var late := START + 3 * 86400
	var halfway := RestorationRules.midpoint(FIG)
	_check(RestorationRules.remaining(_first(profile), START + 123) == halfway - 123, "Closed app advances toward water from the planted timestamp")
	_check(RestorationRules.needs_water(_first(profile), late) and RestorationRules.elapsed(_first(profile), late) == halfway, "Long offline gap stops at the unwatered midpoint indefinitely")
	_check(profile.collect_garden(0, cycle, late).is_empty(), "Skipping days does not collect an unwatered tree")
	_check(profile.checkpoint_garden(late), "Opening the garden saves the reached midpoint")
	profile = CampaignProgress.new(path)
	_check(RestorationRules.needs_water(_first(profile), START - 900), "A saved midpoint survives a local clock rollback before planting")
	_check(not profile.water_garden(0, "stale_cycle", late) and profile.water_garden(0, cycle, late), "Only the active waiting cycle can be watered")
	_check(RestorationRules.remaining(_first(profile), late) == halfway, "Waiting for water gives no carryover to the second half")
	profile = CampaignProgress.new(path)
	_check(RestorationRules.remaining(_first(profile), late + 123) == halfway - 123, "Closed app resumes from the saved water timestamp")
	_check(profile.checkpoint_garden(late + 123) and profile.checkpoint_garden(late - 300), "Checkpoint accepts a later observation and a subsequent rollback")
	profile = CampaignProgress.new(path)
	_check(RestorationRules.elapsed(_first(profile), late - 300) == halfway + 123 and RestorationRules.stage(_first(profile), late - 300) == RestorationRules.Stage.SAPLING, "Saved Sapling growth is monotonic across a rollback and restart")
	var mature := late + halfway
	_check(profile.checkpoint_garden(mature), "The maturity observation saves")
	profile = CampaignProgress.new(path)
	_check(RestorationRules.stage(_first(profile), START - 900) == RestorationRules.Stage.MATURE, "A saved Mature tree remains collectible after a clock rollback")
	_check(not profile.collect_garden(0, cycle, START - 900).is_empty(), "Can collect a previously observed Mature tree even if the clock rolled back")
	profile = CampaignProgress.new(path)
	_check(_first(profile).is_empty() and profile.garden_state().scenery[FIRST] == FIG and profile.collect_garden(0, cycle, mature).is_empty(), "Cold load retains scenery and rejects a stale collection")
	var replacement := profile.plant_garden(0, BELIAN, START)
	_check(not replacement.is_empty() and replacement != cycle and profile.garden_state().scenery[FIRST] == FIG, "Retained scenery does not block a new cycle at a rolled-back time")
	_check(not profile.water_garden(0, cycle, mature) and profile.collect_garden(0, cycle, mature).is_empty(), "Prior cycle cannot change the new plant")
	var middle := START + RestorationRules.midpoint(BELIAN)
	profile.checkpoint_garden(middle)
	var rolled := START - 500
	_check(profile.water_garden(0, replacement, rolled), "Watering works after a clock rollback before planting")
	profile = CampaignProgress.new(path)
	_check(_first(profile).get("watered_at") == rolled and RestorationRules.remaining(_first(profile), rolled + 1) == RestorationRules.midpoint(BELIAN) - 1, "Cold load resumes immediately from the rolled-back watering time")

func _settlements_and_ecology() -> void:
	var path := _seed("settlements", 1, 1600000)
	var profile := CampaignProgress.new(path)
	for level in range(2, 5):
		_check(profile.purchase_room(ECOLOGY).is_empty() and profile.room_capacity(ECOLOGY) == level + 1, "Ecology Lv.%d opens %d plots" % [level, level + 1])
	_check(profile.purchase_room(ECOLOGY).contains("60%") and profile.plant_garden(5, FIG, START).is_empty(), "Funds alone cannot open the sixth plot")
	_check(profile.visit_garden_guide() and profile.visit_garden_guide() and profile.discovered_facts() == [RestorationRules.GUIDE_FACT], "The hornbill guide discovery is one-shot")
	var species_in_order := [FIG, FIG, BELIAN, MERANTI, MENGARIS, BELIAN, MENGARIS]
	var base_funds := [3000, 3000, 8000, 11000, 18000, 8000, 18000]
	var milestone_funds := [50000, 0, 150000, 350000, 750000, 1250000, 0]
	var percent := [20, 20, 40, 60, 80, 100, 100]
	var milestone_total := 0
	for i in species_in_order.size():
		var before := profile.funds()
		var result := _grow(profile, 0, species_in_order[i], START + i * 350000)
		_check(result.get("cycle_funds") == base_funds[i] and result.get("milestone_funds") == milestone_funds[i], "Collection %d uses the specified cycle and milestone Funds" % (i + 1))
		_check(result.get("visitor") == (i == 4) and profile.garden_state().nest_box_seen == (i >= 4), "Fourth distinct species alone triggers the hornbill visitor")
		milestone_total += int(result.get("milestone_funds", 0))
		profile = CampaignProgress.new(path)
		_check(profile.funds() == before + base_funds[i] + milestone_funds[i] and profile.restoration_percent() == percent[i], "Cold load preserves collection %d Funds and %d%%" % [i + 1, percent[i]])
		if percent[i] == 60:
			var quote := profile.room_quote(ECOLOGY)
			_check(quote.error.is_empty() and quote.cost == 900000, "Three distinct collections enable the priced Lv.5 upgrade")
			var poor_path := _seed("poor", 4, 899999)
			var poor_data := profile.snapshot()
			poor_data.funds = 899999
			ProfileFile.replace(poor_path, poor_data, false)
			var poor := CampaignProgress.new(poor_path)
			_check(poor.restoration_percent() == 60 and poor.purchase_room(ECOLOGY).contains("1 more Funds") and poor.room_capacity(ECOLOGY) == 5, "60% alone cannot open the sixth plot without the price")
			_check(profile.purchase_room(ECOLOGY).is_empty() and profile.funds() == quote.balance and profile.room_capacity(ECOLOGY) == 6 and not profile.plant_garden(5, FIG, START).is_empty(), "Paying Lv.5 at 60% opens a plantable sixth plot")
	_check(milestone_total == 2550000 and profile.garden_state().milestones.size() == 5, "All five milestones settle 2,550,000 Funds once")
	var expected_facts := [RestorationRules.GUIDE_FACT, "fact.strangler_fig_start", "fact.belian_identity", "fact.red_meranti_example", "fact.mengaris_identity", RestorationRules.NEST_FACT]
	_check(profile.discovered_facts() == expected_facts, "Guide, each species and the nest box each leave one stable discovery")

func _save_failure_and_wallet_cap() -> void:
	var path := _seed("wallet", 1, FundsWallet.CAP - 100)
	var profile := CampaignProgress.new(path)
	for i in 3:
		_grow(profile, 1, [FIG, BELIAN, MERANTI][i], START)
	var cycle := profile.plant_garden(0, MENGARIS, START)
	profile.water_garden(0, cycle, START + RestorationRules.midpoint(MENGARIS))
	var mature := START + RestorationRules.duration(MENGARIS)
	var before := profile.snapshot()
	var saved_before := ProfileFile.read(path)
	var blocker := path + ".bak"
	DirAccess.remove_absolute(blocker)
	DirAccess.make_dir_absolute(blocker)
	_check(profile.collect_garden(0, cycle, mature).is_empty() and profile.snapshot() == before, "Failed write grants no cash, milestone, discovery, visitor flag or plot release")
	var reloaded := CampaignProgress.new(path)
	_check(ProfileFile.read(path) == saved_before and reloaded.load_status == CampaignProgress.LoadStatus.READY and _first(reloaded).cycle_id == cycle, "Cold load after partial write still has the original uncollected cycle")
	DirAccess.remove_absolute(blocker)
	var retry := profile.collect_garden(0, cycle, mature)
	_check(retry.get("credited") == 0 and retry.get("discarded") == 768000 and retry.get("visitor") == true, "Successful retry settles overflow and the single 80% visitor")
	profile = CampaignProgress.new(path)
	_check(profile.funds() == FundsWallet.CAP and profile.restoration_percent() == 80 and profile.collect_garden(0, cycle, mature).is_empty(), "Discarded money stays unavailable after reload")

func _legacy_and_reset() -> void:
	var path := _seed("legacy", 1, 10000)
	var previous := ProfileFile.read(path)
	previous.garden.erase("cycle_serial")
	previous.garden.plots[FIRST] = {"cycle_id": "old_fig", "species": FIG, "planted_at": START, "watered_at": START + 300}
	previous.garden.settled_awards = ["garden_cycle.1"]
	ProfileFile.replace(path, previous, false)
	var profile := CampaignProgress.new(path)
	_check(profile.load_status == CampaignProgress.LoadStatus.READY and RestorationRules.stage(_first(profile), START + 301) == RestorationRules.Stage.SEED, "Existing v2 timestamp-only plots load without early maturity")
	var cycle := profile.plant_garden(1, BELIAN, START)
	_check(cycle == "garden_cycle.2", "New cycle serials skip IDs used by an older file")
	var midway := START + RestorationRules.midpoint(FIG)
	profile.checkpoint_garden(midway - 1)
	_check(RestorationRules.stage(_first(profile), midway - 1) == RestorationRules.Stage.SEED, "Legacy early watering does not skip its remaining Seed phase")
	profile.checkpoint_garden(midway + 1)
	profile = CampaignProgress.new(path)
	_check(RestorationRules.elapsed(_first(profile), START) == RestorationRules.midpoint(FIG) + 1, "Legacy checkpoint becomes monotonic after it reaches Sapling")
	_check(not profile.collect_garden(0, "old_fig", START + RestorationRules.duration(FIG)).is_empty(), "An older active cycle can finish and settle")
	_check(profile.reset_profile(), "Confirmed profile reset succeeds")
	profile = CampaignProgress.new(path)
	var garden := profile.garden_state()
	_check(garden.plots.is_empty() and garden.scenery.is_empty() and garden.settled_awards.is_empty() and garden.cycle_serial == 0 and profile.restoration_percent() == 0 and profile.discovered_facts().is_empty() and profile.room_capacity(ECOLOGY) == 0, "Cold load clears all Garden data after a confirmed reset")

func _grow(profile: CampaignProgress, slot: int, species: String, start: int) -> Dictionary:
	var cycle := profile.plant_garden(slot, species, start)
	profile.water_garden(slot, cycle, start + RestorationRules.midpoint(species))
	return profile.collect_garden(slot, cycle, start + RestorationRules.duration(species))

func _first(profile: CampaignProgress) -> Dictionary:
	return profile.garden_state().plots.get(FIRST, {})

func _seed(suffix: String, level: int, funds: int) -> String:
	var path := "user://c20-%d-%s.json" % [OS.get_process_id(), suffix]
	_paths.append(path)
	var data := CampaignSave.fresh()
	data.leader_name = "Garden QA"
	data.funds = funds
	if level > 0:
		data.rooms[String(ECOLOGY)] = level
	ProfileFile.replace(path, data, false)
	return path

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
