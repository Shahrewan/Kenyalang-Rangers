extends SceneTree

const CATALOG: EnemyCatalog = preload("res://data/enemies/catalog.tres")
const ARENA: BattleStage = preload("res://tests/fixtures/c11_facility_stage.tres")
const SCOUT: RangerSpec = preload("res://data/rangers/scout_sniper.tres")
const GUARD: RangerSpec = preload("res://data/rangers/guard_veteran.tres")
const SCAN: RangerSpec = preload("res://tests/fixtures/c12_seer_scan.tres")
const BARRICADE: RangerSpec = preload("res://tests/fixtures/c11_barricade_target.tres")
const SONIC: FacilitySpec = preload("res://data/facilities/sonic_turret.tres")
const DISRUPTION: FacilitySpec = preload("res://data/facilities/disruption_beacon.tres")
const FIREBREAK: FacilitySpec = preload("res://data/facilities/firebreak_beacon.tres")
const OPERATION: StoryOperation = preload("res://data/stages/c09_first_contact_operation.tres")

var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_catalog()
	for entry in CATALOG.entries:
		_lifecycle(entry)
		_attack_target(entry)
	_sprint()
	_smoke_and_scan()
	_signal_jam()
	_tracking_and_net()
	_knockdown()
	_heat()
	_marks_and_buff()
	print("Enemy checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _catalog() -> void:
	var names := ["Forest Trespasser", "Poacher", "Contraband Runner", "Shield Carrier", "Rifle Spotter", "Smoke Infiltrator", "Signal Jammer", "Recon Drone", "Tracking Bot", "Net Trapper", "Demolitionist", "Portable Mortar Crew", "Heavy Breacher", "Ignition Operator", "Wildlife Trafficker"]
	var hp := [100, 140, 110, 450, 180, 150, 320, 120, 300, 250, 360, 600, 1050, 280, 850]
	var danger := [1, 1, 2, 3, 3, 3, 4, 3, 3, 3, 4, 4, 4, 4, 5]
	var damage := [6, 9, 5, 12, 15, 12, 8, 7, 11, 8, 60, 120, 45, 9, 18]
	var intervals := [1.8, 1.7, 1.2, 2.2, 2.4, 1.6, 2.4, 2.0, 2.0, 2.0, 6.0, 10.0, 3.2, 2.5, 2.0]
	var score := [10, 15, 20, 25, 25, 30, 35, 30, 35, 35, 50, 65, 60, 55, 90]
	_check(CATALOG.entries.size() == 15, "The standard catalog contains fifteen entries")
	var siege: Array[StringName] = []
	var tech: Array[StringName] = []
	for index in CATALOG.entries.size():
		var entry := CATALOG.entries[index]
		var id := "E%02d" % (index + 1)
		_check(entry.enemy_id == id and entry.display_name == names[index] and entry.max_hp == hp[index] and entry.danger == danger[index], "%s preserves canonical name, HP and Danger" % id)
		_check(entry.attack_damage == damage[index] and is_equal_approx(entry.attack_seconds, intervals[index]) and entry.chaos_points == score[index], "%s preserves attack output, cadence and Chaos weight" % id)
		if entry.is_siege_capable():
			siege.append(entry.enemy_id)
		if entry.technological:
			tech.append(entry.enemy_id)
	_check(siege == [&"E11", &"E12"], "Only Demolitionist and Portable Mortar Crew have Siege authority")
	_check(tech == [&"E07", &"E08", &"E09", &"E12", &"E14"], "Technological tags match the documented overlap")
	_check("Aerial" in _entry(8).tags() and "Invisible" in _entry(6).tags() and "Heavy" in _entry(13).tags() and "Environmental" in _entry(14).tags(), "Functional tags are available to the battle and UI")

func _lifecycle(entry: BattleEnemyDefinition) -> void:
	var battle := _single(entry)
	var id := String(entry.enemy_id)
	battle.clock.set_speed(2)
	battle.clock.paused = true
	_frames(battle, 20)
	_check(battle.active.is_empty() and battle.clock.tick == 0, "%s spawn waits during Pause at 2×" % id)
	battle.clock.paused = false
	battle.clock.set_speed(1)
	_frames(battle, 1)
	var actor := battle.active[1]
	_check(actor.definition == entry and actor.hp == entry.max_hp and actor.distance == 0.0, "%s spawns from its data with the authored HP" % id)
	battle.clock.dialogue_open = true
	battle.damage_enemy(1, entry.max_hp)
	_frames(battle, 20)
	_check(actor.hp == entry.max_hp and actor.distance == 0.0 and battle.clock.tick == 1, "%s movement and HP are held during dialogue" % id)
	battle.clock.dialogue_open = false
	battle.damage_enemy(1, entry.max_hp)
	_check(battle.defeated == 1 and battle.escaped == 0 and battle.is_perfect(), "%s defeat resolves its populated wave once" % id)

	battle = _single(entry)
	_frames(battle, 1)
	battle.active[1].distance = battle.active[1].route.cells.size() - 1.001
	_frames(battle, 1)
	var loss := battle.outcome == BattleSimulation.Outcome.LOST
	var integrity := 0 if entry.escape_causes_defeat else 100 - entry.escape_penalty
	_check(battle.escaped == 1 and battle.defeated == 0 and battle.integrity == integrity and loss == entry.escape_causes_defeat and not battle.is_perfect(), "%s escape applies its authored Integrity outcome" % id)

func _attack_target(entry: BattleEnemyDefinition) -> void:
	var battle := _single(entry)
	var state := battle.deployment
	var elevated := SCOUT.duplicate() as RangerSpec
	elevated.attack_damage = 0
	elevated.max_hp = 500
	state.deploy(elevated, Vector2i(0, 1), 1)
	state.deploy(BARRICADE, Vector2i(1, 2), -1)
	state.deploy(SONIC, Vector2i(0, 3), 1)
	_frames(battle, 1)
	var actor := battle.active[1]
	var scout := state.placed[SCOUT.id]
	var guard := state.placed[BARRICADE.id]
	var site := state.placed[SONIC.id]
	var id := String(entry.enemy_id)
	if entry.is_siege_capable():
		_check(actor.aim_target == SONIC.id and site.hp == SONIC.max_hp, "%s pins a Siege windup to the unfinished Facility" % id)
		_frames(battle, actor.fire_tick - battle.clock.tick)
		_check(site.hp == SONIC.max_hp - entry.attack_damage and scout.hp == 500 and guard.hp == BARRICADE.max_hp, "%s delivers its Siege damage only to the Facility" % id)
	elif entry.attack_profile != null:
		_check(scout.hp == 500 - entry.attack_damage and guard.hp == BARRICADE.max_hp and site.hp == SONIC.max_hp, "%s hits an eligible elevated Ranger and leaves the Facility intact" % id)
		if entry.aerial:
			actor.distance = 0.49
			_frames(battle, 1)
			_check(actor.blocked_by.is_empty() and actor.distance > 0.49, "%s flies through a ground footprint" % id)
	else:
		actor.distance = 0.49
		_frames(battle, 1 + CombatClock.ticks_for(entry.attack_seconds))
		_check(actor.blocked_by == BARRICADE.id and scout.hp == 500 and guard.hp == BARRICADE.max_hp - entry.attack_damage and site.hp == SONIC.max_hp, "%s melee damage reaches its ground blocker" % id)

func _sprint() -> void:
	var battle := _single(_entry(3))
	_frames(battle, 120)
	var runner := battle.active[1]
	_check(runner.sprint_until == 0, "Runner stays at base speed before Sprint")
	_frames(battle, 1)
	var progress := runner.distance
	battle.clock.paused = true
	_frames(battle, 120)
	_check(runner.distance == progress and runner.sprint_until == 241, "Pause holds Sprint movement and its expiry")
	battle.clock.paused = false
	_frames(battle, 1)
	_check(is_equal_approx(runner.distance - progress, _entry(3).tiles_per_second * 1.6 / 60.0), "Sprint multiplies movement during its active window")

func _smoke_and_scan() -> void:
	var battle := _single(_entry(6))
	var state := battle.deployment
	state.deploy(SCOUT, Vector2i(0, 1), 1)
	state.deploy(SCAN, Vector2i(1, 1), 1)
	_frames(battle, 1)
	var smoke := battle.active[1]
	_check(not smoke.is_targetable(battle.clock.tick) and smoke.hp == 150, "Smoke prevents an ordinary ranged attack at spawn")
	_check(battle.tap_unit(SCAN.id) and smoke.is_targetable(battle.clock.tick) and smoke.hp == 150 and smoke.damage_mark_bonus(battle.clock.tick) == 2, "The scan reveals, marks and deals zero HP damage")
	_frames(battle, 1)
	_check(smoke.hp == 119, "Steady Aim can hit the revealed and marked target")
	battle = _single(_entry(6))
	_frames(battle, 151)
	_check(battle.active[1].is_targetable(battle.clock.tick), "Smoke concealment ends on its own combat deadline")

func _signal_jam() -> void:
	var battle := _single(_entry(7), 8.0)
	var state := battle.deployment
	state.deploy(SCOUT, Vector2i(0, 1), 1)
	state.deploy(DISRUPTION, Vector2i(0, 3), 1)
	_frames(battle, 601)
	var scout := state.placed[SCOUT.id]
	var jammer := battle.active[1]
	_check(jammer.ability_target == SCOUT.id and jammer.ability_fire_tick == 697, "Disruption adds its delay to the separate Signal Jammer ability")
	_check(battle.tap_unit(SCOUT.id), "Scout can arm before a pending jam lands")
	scout.skill_recharge_tick = 900
	_frames(battle, 95)
	var hp_before := scout.hp
	battle.clock.dialogue_open = true
	_frames(battle, 200)
	_check(battle.clock.tick == 696 and scout.jammed_until == 0 and state.armed == SCOUT.id, "Dialogue holds the pending skill interference")
	battle.clock.dialogue_open = false
	_frames(battle, 1)
	_check(scout.hp == hp_before and scout.skill_recharge_tick == 1020 and scout.jammed_until == 817 and state.armed.is_empty(), "Jammer interrupts the active aim and adds recharge time separately from HP damage")
	_check(not battle.tap_unit(SCOUT.id) and "Signal Jammer" in state.last_skill_error, "A jammed Ranger gives an explicit skill rejection")

func _tracking_and_net() -> void:
	var battle := _single(_entry(9))
	battle.deployment.deploy(SCOUT, Vector2i(0, 1), 1)
	_frames(battle, 115)
	var scout := battle.deployment.placed[SCOUT.id]
	_check(scout.basic_interval_ticks == 172 and is_equal_approx(scout.attack_rate(battle.clock.tick), 0.7), "Tracking Bot slows the current Ranger attack cadence")
	_frames(battle, 180)
	_check(scout.basic_interval_ticks == 120, "Tracking expires and restores the base cadence")

	battle = _single(_entry(10))
	battle.deployment.deploy(SCOUT, Vector2i(0, 1), 1)
	_frames(battle, 133)
	scout = battle.deployment.placed[SCOUT.id]
	var netted := battle.active[1]
	var hp := netted.hp
	scout.next_attack_tick = battle.clock.tick
	_check(not battle.tap_unit(SCOUT.id) and not scout.can_act(battle.clock.tick), "Entanglement disables Ranger attacks and active skills")
	_frames(battle, 104)
	_check(netted.hp == hp, "An entangled Ranger cannot finish a ready basic attack")
	_frames(battle, 1)
	_check(netted.hp == hp - 24 and scout.can_act(battle.clock.tick), "The Ranger acts again at entanglement expiry")

func _knockdown() -> void:
	for blocker: RangerSpec in [GUARD, BARRICADE]:
		var battle := _single(_entry(13))
		battle.deployment.deploy(blocker, Vector2i(1, 2), -1)
		_frames(battle, 1)
		var enemy := battle.active[1]
		enemy.distance = 0.49
		_frames(battle, 32)
		var placement := battle.deployment.placed[blocker.id]
		var resists := blocker == BARRICADE
		_check((placement.knocked_down_until == 0) == resists and (enemy.blocked_by == blocker.id) == resists, "%s has the authored Knockdown and blocking interaction" % blocker.label)

func _heat() -> void:
	var battle := _single(_entry(14), 7.0, true)
	battle.deployment.deploy(FIREBREAK, Vector2i(0, 1), 1)
	_frames(battle, 480)
	var firebreak := battle.deployment.placed[FIREBREAK.id]
	_check(is_equal_approx(battle.heat, 4.8), "Ignition Operator produces Heat through the completed Firebreak's positive slowdown")
	_frames(battle, 440)
	_check(battle.integrity == 90 and is_zero_approx(battle.heat) and firebreak.hp == FIREBREAK.max_hp, "Ignition Heat resets at capacity and damages Integrity alone")
	battle.damage_enemy(1, _entry(14).max_hp)
	_check(battle.is_perfect(), "Heat damage with zero escapes can still earn a perfect clear")

func _marks_and_buff() -> void:
	var battle := _single(_entry(4))
	_frames(battle, 1)
	var target := battle.active[1]
	for count in 12:
		target.add_damage_mark(battle.clock.tick, 20, 2)
	_check(target.damage_mark_bonus(battle.clock.tick) == 20, "Damage marks stop stacking at ten")
	var operation := OPERATION.duplicate() as StoryOperation
	var roster := DeploymentRoster.new()
	var basic := SCOUT.duplicate() as RangerSpec
	basic.records_enhancement = &""
	roster.entries = [basic]
	operation.roster = roster
	operation.ranger_ids = [SCOUT.id]
	var plan := OperationPlan.new(operation, [&"B05"])
	for choice in operation.buff_choices:
		if choice.id == &"B05":
			plan.select_buff(choice)
	var enhanced := plan.deployment_entries()[0]
	battle.deployment.deploy(enhanced, Vector2i(0, 1), 1)
	_frames(battle, 1)
	_check(enhanced.attack_damage == 26 and target.hp == 419, "B05's 26-HP basic attack combines once with the capped mark bonus for 31 HP")
	_frames(battle, 18)
	_check(target.damage_mark_bonus(battle.clock.tick) == 0 and not target.is_marked(battle.clock.tick), "Mark expiry removes the named damage bonus")

func _single(definition: BattleEnemyDefinition, opening := 0.0, heat := false) -> BattleSimulation:
	var stage := ARENA.duplicate() as BattleStage
	stage.stage_id = &"qa.enemy_unit"
	stage.opening_delay_seconds = opening
	if not heat:
		stage.heat_capacity = 0.0
		stage.heat_integrity_loss = 0
	var group := BattleSpawnGroup.new()
	group.count = 1
	group.enemy = definition
	var wave := BattleWave.new()
	wave.groups = [group]
	stage.waves = [wave]
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(stage.map, battle.clock, 500, null, [SCOUT.records_enhancement])
	return battle

func _entry(number: int) -> BattleEnemyDefinition:
	return CATALOG.entries[number - 1]

func _frames(battle: BattleSimulation, count: int) -> void:
	for frame in count:
		battle.clock.advance_frame()

func _check(ok: bool, text: String) -> void:
	if ok:
		print("PASS ", text)
	else:
		printerr("FAIL ", text)
		_failed += 1
