extends SceneTree

var _checks := 0
var _failed := 0
var _path := "user://c17-chaos-rules-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_wave_contract()
	_worked_example()
	_payout_boundaries()
	_outcomes_and_settlement()
	_boss_reinforcements()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Chaos rules: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _wave_contract() -> void:
	var configuration := ChaosConfiguration.new()
	var expected := [10, 15, 20, 25, 25, 30, 35, 30, 35, 35, 50, 65, 60, 55, 90, 200, 300, 500]
	_check(configuration.enemies().size() == expected.size(), "The composer uses all 15 enemies and three bosses")
	for index in expected.size():
		_check(configuration.enemies()[index].chaos_points == expected[index], "Enemy weight %d matches GDD M.7" % index)
	_check(not _resolve(configuration).can_start(), "An all-empty queue cannot start or earn points")
	_check(configuration.set_quantity(0, &"E01", 49) == 49 and configuration.set_quantity(0, &"E02", 8) == 1, "The 50 cap is shared across mixed enemy types")
	_check(configuration.set_quantity(0, &"E03", 1) == 0 and configuration.set_quantity(0, &"E01", 50) == 49, "Every row is clamped when the wave is full")
	_check(configuration.set_quantity(0, &"E02", -1) == 0 and configuration.set_quantity(0, &"E03", 1) == 1, "Reducing an existing count opens one place")
	_check(configuration.set_quantity(4, &"E02", 50) == 50 and configuration.wave_size(0) == 50, "The fifth slot has independent capacity")
	_check(configuration.set_quantity(5, &"E01", 1) == 0 and configuration.set_quantity(1, &"unknown", 1) == 0, "Unknown rows and a sixth wave cannot enter the setup")
	for id: StringName in ChaosConfiguration.ROUTES:
		_check(configuration.select_route(id), "%s is selectable" % id)
		var stage := configuration.build_stage()
		var source: BattleStage = CampaignContent.MAPS[id]
		_check(stage.map == source.map and stage.routes == source.routes and stage.validation_error().is_empty(), "%s uses the approved map and real routes" % id)
		_check((stage.heat_capacity > 0) == (id == &"T05") and stage.capture_boss_id.is_empty(), "%s uses only its Chaos environmental rules" % id)
	_check(not configuration.select_route(&"invented") and configuration.route_id == &"T06", "Invalid routes leave the chosen route intact")
	_check(configuration.build_stage().waves.size() == 2 and configuration.build_stage().enemy_count() == 100, "Three empty slots are removed from the actual queue")
	var saved := configuration.save_data()
	var restored := ChaosConfiguration.from_data(saved)
	_check(restored != null and restored.route_id == &"T06" and restored.wave_size(4) == 50, "The authored wave and route IDs round-trip without combat state")
	saved.waves[4]["E01"] = 1
	_check(ChaosConfiguration.from_data(saved) == null, "An interrupted draft cannot restore an overfilled wave")

	configuration = ChaosConfiguration.new()
	configuration.select_route(&"T01")
	configuration.set_quantity(1, &"E01", 1)
	configuration.set_quantity(3, &"E02", 1)
	var compacted := configuration.build_stage()
	compacted.opening_delay_seconds = 0
	var battle := BattleSimulation.new(compacted)
	battle.clock.advance_frame()
	_check(battle.wave_count == 2 and battle.wave_number == 1 and battle.active[1].definition.enemy_id == &"E01", "Leading empty slots add no opening rest")
	battle.defeat_enemy(1)
	_frames(battle, 1079)
	_check(battle.active.is_empty() and battle.wave_number == 2, "The intervening empty slot does not spawn")
	battle.clock.advance_frame()
	_check(battle.clock.tick == 1081 and battle.active[2].definition.enemy_id == &"E02", "Exactly one 18-second rest separates populated slots")
	battle.defeat_enemy(2)
	_check(battle.outcome == BattleSimulation.Outcome.WON and battle.configured_defeated == 2, "The trailing empty slot adds no completion rest")

func _worked_example() -> void:
	var configuration := ChaosConfiguration.new()
	configuration.select_route(&"T02")
	configuration.set_quantity(0, &"E02", 20)
	for id in [&"E03", &"E04", &"E08"]:
		configuration.set_quantity(0, id, 10)
	configuration.set_quantity(1, &"E11", 10)
	var loadout: Array[DeploymentSpec] = [
		_unit(&"ranger.scout_sniper"), _unit(&"ranger.patrolman"), _unit(&"ranger.combat_medic"),
		_unit(&"facility.logistics_post"), _unit(&"facility.sonic_turret"),
	]
	var resolution := _resolve(configuration, loadout, [&"B05"], [&"D02", &"D09", &"D11"])
	_check(resolution.can_start(), "The original Mulu worked setup is legal (%s)" % resolution.selection_error)
	var score := ChaosScore.new(resolution)
	_check(configuration.wave_points(0) == 1050 and configuration.wave_points(1) == 500 and score.enemy_points == 1550, "The exact storyboard queues contribute 1,050 and 500")
	_check(score.ranger_slots == 3 and score.facility_slots == 2 and score.slot_points() == -500, "Only five filled slots deduct points")
	_check(score.debuff_points == 400 and score.buff_points == -100 and score.modifiers.size() == 4, "Only distinct eligible modifiers contribute their exact points")
	_check(score.configured_enemies == 60 and score.points() == 1350 and ChaosScore.payout(score.points()) == 54000, "Storyboard example resolves to 1,350 and 54,000")
	_check(resolution.stage.waves[0].groups[0].route_index == 0 and resolution.stage.waves[0].groups[1].route_index == 1 and resolution.stage.waves[1].groups[0].route_index == 1, "Mulu's original entries alternate by populated group and wave")
	var post_free := _resolve(configuration, loadout, [], [&"D05"])
	_check(post_free.can_start() and ChaosScore.new(post_free).slot_points() == -400 and post_free.tokens == 120, "D05 scores effective slots after removing the Post")
	configuration.set_quantity(1, &"E11", 0)
	resolution = _resolve(configuration, loadout, [&"B05"], [&"D09"])
	_check(not resolution.can_start() and resolution.score_entries.is_empty(), "Removing all Siege targets invalidates its score")

func _payout_boundaries() -> void:
	for row in [
		[-100, 0, 0], [0, 0, 0], [1, 20, 0], [999, 19980, 0], [1000, 40000, 1],
		[1999, 79960, 1], [2000, 130000, 2], [2999, 199930, 2], [3000, 300000, 3],
		[3500, 360000, 3], [5000, 540000, 3],
	]:
		_check(ChaosScore.payout(row[0]) == row[1] and ChaosScore.tier(row[0]) == row[2], "Exact payout and capped trophy tier at %d" % row[0])
	var facilities := ChaosScore.tier_facilities()
	_check(facilities.map(func(spec: FacilitySpec) -> StringName: return spec.id) == [&"facility.skill_relay_station", &"facility.specialist_calltower", &"facility.sentry_tower"], "The three thresholds use the sourced Facility catalog entries")
	var story := CampaignContent.new()
	_check(story.error.is_empty() and story.operations.all(func(operation: StoryOperation) -> bool:
		return operation.clear_unlock_ids.all(func(id: StringName) -> bool: return facilities.all(func(spec: FacilitySpec) -> bool: return spec.id != id))
	), "Story rewards contain none of the Chaos threshold Facilities")

func _outcomes_and_settlement() -> void:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Chaos QA"
	profile.funds = FundsWallet.CAP - 10000
	_check(ProfileFile.replace(_path, profile, false), "The transaction fixture has a writable profile")
	var progress := CampaignProgress.new(_path)
	var before := progress.snapshot()
	var configuration := ChaosConfiguration.new()
	configuration.select_route(&"T01")
	configuration.set_quantity(0, &"E01", 10)
	configuration.set_quantity(0, &"boss.poacher_leader", 7)
	var resolution := _resolve(configuration)
	var run := _begin(progress, configuration, resolution)
	_check(run != null and run.score.points() == 3500, "The first clear fixture is exactly 3,500 using configured enemies and one filled slot")
	_check(_begin(progress, configuration, resolution) == null and progress.settle_chaos(run).is_empty(), "A running challenge cannot be overwritten or paid")
	var reopened := CampaignProgress.new(_path)
	_check(reopened.pending_chaos_configuration().waves[0]["E01"] == 10 and reopened.funds() == before.funds, "Launch persists a draft without crediting projected Funds")
	progress.abandon_chaos(run)
	_check(progress.settle_chaos(run).is_empty() and progress.snapshot() == before, "Abandoning drops the attempt without a record")

	run = _begin(progress, configuration, resolution)
	var battle := _play(resolution.stage, true)
	_check(battle.outcome == BattleSimulation.Outcome.WON and battle.integrity == 90 and battle.configured_defeated == 16 and battle.escaped == 1, "A real configured escape can leave positive Integrity")
	run.record_outcome(battle)
	var escaped := progress.settle_chaos(run)
	_check(escaped.get("credited", -1) == 0 and progress.snapshot() == before, "An escape forfeits Funds, all unlocks and the best")

	run = _begin(progress, configuration, resolution)
	battle = BattleSimulation.new(resolution.stage)
	battle.lose_integrity(100)
	run.record_outcome(battle)
	_check(progress.settle_chaos(run).get("credited", -1) == 0 and progress.snapshot() == before, "Defeat forfeits the whole transaction")

	run = _begin(progress, configuration, resolution)
	battle = _play(resolution.stage)
	_check(run.record_outcome(battle) and run.qualifies() and not run.record_outcome(battle), "The qualifying outcome is recorded once")
	var disk_before := ProfileFile.read(_path)
	var profile_before := progress.snapshot()
	DirAccess.make_dir_absolute(_path + ".tmp")
	_check(progress.settle_chaos(run).is_empty() and progress.snapshot() == profile_before and ProfileFile.read(_path) == disk_before, "A failed save changes neither the persisted nor in-memory profile")
	DirAccess.remove_absolute(_path + ".tmp")
	var receipt := progress.settle_chaos(run)
	_check(receipt.get("credited") == 10000 and receipt.get("discarded") == 350000 and progress.funds() == FundsWallet.CAP, "Retry commits a single capped payout for 3,500")
	_check(receipt.get("new_best") and receipt.get("unlocked", []).size() == 3 and progress.chaos_personal_best() == 3500, "A first high clear awards every crossed Facility in one commit")
	_check(progress.settle_chaos(run).is_empty(), "A successfully settled attempt cannot be claimed twice")
	progress = CampaignProgress.new(_path)
	_check(progress.chaos_personal_best() == 3500 and progress.pending_chaos_configuration().is_empty() and progress.snapshot().chaos.earned_thresholds == ["chaos_tier.1000", "chaos_tier.2000", "chaos_tier.3000"], "Best, cleared pending state and all threshold flags survive cold reload")
	_check(ChaosScore.tier_facilities().all(func(spec: FacilitySpec) -> bool: return progress.owns(spec.id)), "All threshold Facilities persist alongside the best")

	run = _begin(progress, configuration, resolution)
	run.record_outcome(_play(resolution.stage))
	receipt = progress.settle_chaos(run)
	_check(receipt.get("credited") == 0 and receipt.get("discarded") == 360000 and receipt.get("unlocked", []).is_empty() and not receipt.get("new_best"), "A new qualifying repeat pays once without duplicating tier unlocks")
	configuration.set_quantity(0, &"boss.poacher_leader", 8)
	resolution = _resolve(configuration)
	run = _begin(progress, configuration, resolution)
	run.record_outcome(_play(resolution.stage))
	receipt = progress.settle_chaos(run)
	_check(receipt.get("new_best") and progress.chaos_personal_best() == 4000 and ChaosScore.tier(progress.chaos_personal_best()) == 3, "A new best above 3,000 changes the number and retains the final art")

	configuration = ChaosConfiguration.new()
	configuration.set_quantity(0, &"E01", 1)
	resolution = _resolve(configuration)
	run = _begin(progress, configuration, resolution)
	run.record_outcome(_play(resolution.stage))
	_check(run.qualifies() and run.score.points() == -90 and progress.settle_chaos(run).get("credited", -1) == 0 and progress.chaos_personal_best() == 4000, "A nonpositive clear pays zero and preserves the best")
	var damaged := progress.snapshot()
	damaged.chaos.pending_configuration = {"route": "bad", "waves": [], "loadout": [], "modifiers": []}
	var migrated := CampaignSave.load_data(damaged)
	_check(migrated.chaos.pending_configuration.is_empty() and migrated.chaos.personal_best == 4000, "Malformed optional draft data leaves verified progression readable")

func _boss_reinforcements() -> void:
	var configuration := ChaosConfiguration.new()
	configuration.select_route(&"T01")
	configuration.set_quantity(0, &"boss.poacher_leader", 1)
	var resolution := _resolve(configuration)
	var battle := BattleSimulation.new(resolution.stage)
	_frames(battle, 1081)
	var leader := battle.active[1]
	battle.damage_enemy(1, ceili(leader.hp * 0.40))
	_frames(battle, 61)
	_check(battle.active.size() == 2 and battle.active[2].reinforcement, "The configured boss really summons a registered reinforcement")
	battle.defeat_enemy(2)
	_check(battle.defeated == 1 and battle.configured_defeated == 0, "A defeated Runner gives no configured-enemy credit")
	battle.defeat_enemy(1)
	_frames(battle, 60)
	battle.defeat_enemy(3)
	var run := ChaosRun.new(configuration.route_label(), resolution)
	_check(run.record_outcome(battle) and run.qualifies() and run.score.configured_enemies == 1 and run.score.enemy_points == 500 and battle.defeated == 3, "Clearing a boss and its two reinforcements qualifies without adding their points")

func _resolve(configuration: ChaosConfiguration, loadout: Array[DeploymentSpec] = [], buffs: Array[StringName] = [], debuffs: Array[StringName] = []) -> ModifierResolution:
	var setup := ModifierSetup.new()
	setup.chaos = true
	setup.stage = configuration.build_stage()
	if loadout.is_empty():
		setup.loadout.append(_unit(&"facility.logistics_post"))
	else:
		setup.loadout = loadout
	setup.unlocked_buffs = buffs.duplicate()
	return setup.resolve(buffs, debuffs)

func _begin(progress: CampaignProgress, configuration: ChaosConfiguration, resolution: ModifierResolution) -> ChaosRun:
	return progress.begin_chaos(configuration, resolution, [&"facility.logistics_post"], [])

func _play(stage: BattleStage, escape_first := false) -> BattleSimulation:
	var battle := BattleSimulation.new(stage)
	for iteration in 12000:
		if battle.outcome != BattleSimulation.Outcome.RUNNING:
			break
		battle.clock.advance_frame()
		for id: int in battle.active.keys():
			if id == 1 and escape_first:
				var enemy := battle.active[id]
				enemy.distance = enemy.route.cells.size() - 1.00001
			else:
				battle.defeat_enemy(id)
	return battle

func _frames(battle: BattleSimulation, count: int) -> void:
	for i in count:
		battle.clock.advance_frame()

func _unit(id: StringName) -> DeploymentSpec:
	return DeployableLevels.definition(id)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
