extends SceneTree

const TRIAL := preload("res://data/stages/c16_modifier_trial.tres")
const E01 := preload("res://data/enemies/e01_forest_trespasser.tres")
const E06 := preload("res://data/enemies/e06_smoke_infiltrator.tres")
const E08 := preload("res://data/enemies/e08_recon_drone.tres")
const E11 := preload("res://data/enemies/e11_demolitionist.tres")
const E14 := preload("res://data/enemies/e14_ignition_operator.tres")
const E15 := preload("res://data/enemies/e15_wildlife_trafficker.tres")

var _checks := 0
var _failed := 0

func _initialize() -> void:
	_catalog()
	_selection()
	_stockpile()
	_applicability()
	_stacking()
	print("Modifier rules: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _catalog() -> void:
	var setup := _setup()
	var seen := {}
	for item in BattleModifiers.CATALOG.entries:
		_check(not seen.has(item.id) and not item.effects.is_empty(), "%s has a unique ID and effect payload" % item.id)
		seen[item.id] = true
		var expected := 100
		if item.id in [&"B08", &"B13", &"B14", &"B15", &"D05", &"D09", &"D13", &"D14", &"D15"]:
			expected = 200
		if item.is_buff():
			expected = -expected
		_check(item.chaos_points == expected, "%s has its sourced signed score" % item.id)
		var buffs: Array[StringName] = []
		var debuffs: Array[StringName] = []
		if item.is_buff():
			buffs.append(item.id)
		else:
			debuffs.append(item.id)
		var evaluation := setup.resolve(buffs, debuffs)
		_check(evaluation.can_start() and evaluation.modifier_points() == expected and evaluation.score_entries.size() == 1, "%s applies and scores once on suitable input (%s)" % [item.id, evaluation.selection_error])
	for i in range(1, 16):
		_check(seen.has(StringName("B%02d" % i)) and seen.has(StringName("D%02d" % i)), "The catalog has both stable IDs at index %d" % i)

func _selection() -> void:
	var setup := _setup()
	_rejected(setup.resolve([&"B01", &"B01"]), "Duplicate buffs cannot stack or score")
	_rejected(setup.resolve([], [&"D02", &"D02"]), "Duplicate debuffs cannot stack or score")
	_rejected(setup.resolve([], [&"D99"]), "Unknown IDs cannot score")
	_rejected(setup.resolve([&"D02"]), "A debuff cannot enter the buff selector")
	setup.unlocked_buffs.erase(&"B06")
	_rejected(setup.resolve([&"B06"]), "Unresearched effects cannot appear in a submitted plan")
	setup.unlocked_buffs.append(&"B06")
	var many := setup.resolve([&"B01", &"B02", &"B03", &"B05", &"B06"], [&"D02", &"D14"])
	_check(many.can_start() and many.score_entries.size() == 7 and many.modifier_points() == -200, "Chaos accepts any number of different compatible unlocked effects")
	setup.chaos = false
	setup.fixed_debuffs = [&"D01"]
	var chapter_one := setup.resolve([&"B01"])
	_check(chapter_one.can_start() and chapter_one.stage.modifier_ids == [&"D01", &"B01"] and chapter_one.score_entries.is_empty(), "Chapter 1 keeps its fixed debuff and one optional buff")
	_rejected(setup.resolve([&"B01", &"B02"]), "Chapter 1 rejects a second buff")
	_rejected(setup.resolve([], [&"D02"]), "Story cannot replace its authored debuffs")
	setup.buff_limit = 2
	setup.fixed_debuffs = [&"D14", &"D06"]
	var chapter_two := setup.resolve([&"B01", &"B02"])
	_check(chapter_two.can_start() and chapter_two.stage.modifier_ids.size() == 4 and chapter_two.score_entries.is_empty(), "Chapter 2 retains two fixed debuffs with two optional buffs")
	_rejected(setup.resolve([&"B01", &"B02", &"B03"]), "Chapter 2 rejects a third buff")
	setup.fixed_debuffs = [&"D04", &"D06"]
	var silent := setup.resolve([&"B15"])
	_check(silent.can_start() and silent.inactive_fixed.has(&"D04") and &"D04" in silent.stage.modifier_ids, "Mandatory Radio Static stays assigned when skills are disabled")

func _stockpile() -> void:
	var setup := _setup()
	var stockpile := setup.resolve([], [&"D05"])
	_check(stockpile.can_start() and stockpile.tokens == 120 and stockpile.opening.fixed_stockpile, "Fixed Stockpile quotes exactly 120 starting Tokens")
	_check(not stockpile.entries.any(func(spec: DeploymentSpec) -> bool: return spec.logistics_post) and stockpile.facility_slots == 2 and stockpile.modifier_points() == 200, "Removed Post contributes no effective slot")
	_rejected(setup.resolve([&"B13"], [&"D05"]), "Emergency Requisition and Fixed Stockpile conflict")
	_rejected(setup.resolve([], [&"D01", &"D05"]), "Removed Post cannot provide Thin Supply Line points")
	_rejected(setup.resolve([&"B15"], [&"D04"]), "Disabled active skills cannot provide Radio Static points")
	_rejected(setup.resolve([&"B07", &"B15"]), "Disabled active skills cannot receive faster recovery")
	var post := _unit(&"facility.logistics_post")
	setup.loadout = [post]
	_rejected(setup.resolve([], [&"D05"]), "D05 cannot score by removing the only deployable")
	setup.loadout = [_unit(&"ranger.patrolman")]
	_rejected(setup.resolve([], [&"D05"]), "D05 requires a Post in the ordinary setup")
	var activation := setup.resolve([&"B13"])
	_check(activation.can_start() and activation.tokens == 35 and activation.modifier_points() == -200, "B13 enables a paid opening when no Post is equipped")
	setup.loadout.append(post)
	var paid := setup.loadout[0].duplicate() as DeploymentSpec
	paid.cost = 121
	setup.loadout[0] = paid
	_rejected(setup.resolve([], [&"D05"]), "D05 rejects a Post-free loadout above its stockpile")

func _applicability() -> void:
	var setup := _setup()
	setup.stage = _single_stage(E01)
	setup.stage.heat_capacity = 100
	setup.stage.heat_integrity_loss = 10
	for empty in [E06, E08, E11, E14]:
		var group := BattleSpawnGroup.new()
		group.enemy = empty
		group.count = 0
		group.interval_seconds = 10.0
		setup.stage.waves[0].groups.append(group)
	for id in [&"D06", &"D07", &"D09", &"D11", &"D13", &"D14"]:
		_rejected(setup.resolve([], [id]), "%s ignores empty groups and unused rest or spawn gaps" % id)
	for id in [&"B02", &"B03", &"B12"]:
		_rejected(setup.resolve([id]), "%s needs a matching enemy in a populated wave" % id)
	setup.stage = _single_stage(E14)
	_rejected(setup.resolve([&"B02"]), "A Heat emitter on a non-Heat map cannot enable Fireline Preparation")
	_rejected(setup.resolve([], [&"D14"]), "A Heat emitter on a non-Heat map cannot score Heat Surge")
	setup.stage = _single_stage(E15)
	_rejected(setup.resolve([&"B04"]), "Safe Extraction does not apply to fatal escapes")
	_rejected(setup.resolve([], [&"D15"]), "Fatal escape alone cannot score Critical Escape")
	var trivial := E01.duplicate() as BattleEnemyDefinition
	trivial.escape_penalty = 1
	setup.stage = _single_stage(trivial)
	_rejected(setup.resolve([&"B04"]), "A penalty already at the floor has no applicable reduction")
	setup.stage = _single_stage(E11)
	setup.stage.map = setup.stage.map.duplicate() as BattleMap
	setup.stage.map.elevated = [Vector2i(1, 4), Vector2i(2, 4)]
	setup.loadout = [_unit(&"facility.logistics_post"), _unit(&"ranger.patrolman")]
	_rejected(setup.resolve([], [&"D09"]), "A Siege tag alone cannot score if the Facility footprint is out of reach")
	_rejected(setup.resolve([], [&"D10"]), "One free Post on the only footprint cannot score Delayed Construction")
	setup.stage = _single_stage(E01)
	setup.loadout = [_unit(&"ranger.scout_sniper"), _unit(&"facility.logistics_post")]
	setup.enhancements = []
	_rejected(setup.resolve([&"B07"]), "Records-locked skills cannot qualify for cooldown recovery")
	_rejected(setup.resolve([&"B08"]), "Exploit Weakness requires an available negative-effect source")
	_rejected(setup.resolve([&"B10"]), "Improved First Aid needs a source of actual healing")
	setup.loadout.append(_unit(&"facility.disruption_beacon"))
	_check(setup.resolve([&"B08"]).can_start(), "A completed Disruption Beacon can enable Exploit Weakness where a Ranger reaches the same route")
	setup.loadout = [_unit(&"ranger.patrolman")]
	_rejected(setup.resolve([], [&"D01"]), "Thin Supply Line cannot score without generation")
	_rejected(setup.resolve([], [&"D02"]), "An otherwise relevant debuff earns no score when Start is blocked")

func _stacking() -> void:
	var setup := _setup()
	var combined := setup.resolve([&"B02", &"B05", &"B09", &"B13", &"B14", &"B15"], [&"D01", &"D03", &"D14"])
	_check(combined.can_start() and combined.tokens == 35 and combined.opening.yield_percent == 80, "Compatible yield changes add in percentage points")
	var scout := _from_loadout(combined.entries, &"ranger.scout_sniper")
	_check(scout.attack_damage == 34 and scout.max_hp == 75 and _unit(&"ranger.scout_sniper").max_hp == 100, "Damage and HP adjust once while source stats remain intact")
	_check(is_equal_approx(combined.stage.heat_gain_scale, 1.05) and is_equal_approx(TRIAL.heat_gain_scale, 1.0), "Heat Surge and Fireline add once without modifying base stage data")
	var expensive := _unit(&"ranger.patrolman").duplicate() as DeploymentSpec
	expensive.cost = 50
	var strained := BattleModifiers.new([&"D12"]).deployable(expensive)
	_check(strained.cost == 55 and BattleModifiers.new([&"D12"]).deployable(_unit(&"ranger.scout_sniper")).cost == 14, "D12 rounds exact multiples and fractional costs correctly")
	_check(BattleModifiers.new([&"B04", &"D15"]).escape_penalty(5) == 6, "D15 rounds up before applying the B04 reduction")
	var recharge := setup.resolve([&"B07"], [&"D04"])
	var guard := _from_loadout(recharge.entries, &"ranger.guard_veteran") as RangerSpec
	_check(is_equal_approx(guard.active_skill.recharge_seconds, 13.0), "Cooldown duration and recovery resolve through separate factors")

func _setup() -> ModifierSetup:
	var setup := ModifierSetup.new()
	setup.stage = TRIAL
	setup.chaos = true
	setup.enhancements = [&"records_chapter.scout_sniper"]
	setup.loadout = [
		_unit(&"ranger.scout_sniper"), _unit(&"ranger.patrolman"), _unit(&"ranger.guard_veteran"),
		_unit(&"facility.logistics_post"), _unit(&"facility.medic_cabin"), _unit(&"facility.sonic_turret"),
	]
	for item in BattleModifiers.CATALOG.entries:
		if item.is_buff():
			setup.unlocked_buffs.append(item.id)
	return setup

func _single_stage(enemy: BattleEnemyDefinition) -> BattleStage:
	var stage := TRIAL.duplicate() as BattleStage
	stage.heat_capacity = 0
	stage.heat_integrity_loss = 0
	var group := BattleSpawnGroup.new()
	group.enemy = enemy
	group.count = 1
	group.interval_seconds = 10.0
	var wave := BattleWave.new()
	wave.groups = [group]
	wave.rest_after_seconds = 10.0
	stage.waves = [wave]
	return stage

func _unit(id: StringName) -> DeploymentSpec:
	return DeployableLevels.definition(id)

func _from_loadout(entries: Array[DeploymentSpec], id: StringName) -> DeploymentSpec:
	for spec in entries:
		if spec.id == id:
			return spec
	return null

func _rejected(result: ModifierResolution, message: String) -> void:
	_check(not result.can_start() and result.score_entries.is_empty() and result.modifier_points() == 0, message)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
