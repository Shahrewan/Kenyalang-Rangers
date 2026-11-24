extends SceneTree

const T01 := preload("res://data/stages/c05_first_contact.tres")
const E01 := preload("res://data/enemies/e01_forest_trespasser.tres")
const PATROL := &"ranger.patrolman"
const GUARD := &"ranger.guard_veteran"
const BARRICADE := &"ranger.barricade_ops"
const SCOUT := &"ranger.scout_sniper"
const MEDIC := &"ranger.combat_medic"
const CABIN := &"facility.medic_cabin"
const POST := &"facility.logistics_post"

var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_defender(PATROL, 12, 90)
	_defender(BARRICADE, 8, 132)
	_defender(GUARD, 32, 120)
	_facing()
	_charges()
	_facility_stock()
	_chaos_values()
	print("C30 combat and skills: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _battle(modifiers: Array[StringName] = [], count := 20, interval := 1.0, durable := false) -> BattleSimulation:
	var stage := T01.duplicate() as BattleStage
	stage.opening_delay_seconds = 0.0
	var wave := BattleWave.new()
	var group := BattleSpawnGroup.new()
	group.enemy = E01.duplicate() as BattleEnemyDefinition if durable else E01
	if durable:
		group.enemy.max_hp = 400
		group.enemy.tiles_per_second = 1.0
	group.count = count
	group.interval_seconds = interval
	wave.groups.append(group)
	stage.waves = [wave]
	var sim := BattleSimulation.new(BattleModifiers.new(modifiers).stage(stage))
	sim.deployment = DeploymentState.new(stage.map, sim.clock, 500, null, [], sim.effects)
	return sim

func _defender(id: StringName, damage: int, interval: int) -> void:
	var sim := _battle([], 8, 0.14, true)
	var state := sim.deployment
	var spec := DeployableLevels.definition(id)
	var hits := []
	var clocks := []
	var check := {"sim": weakref(sim)}
	sim.melee_hit_presented.connect(func(serial: int, _at: Vector2, lost: int) -> void:
		var witness: BattleSimulation = check.sim.get_ref()
		var enemy := witness.active[serial]
		hits.append([serial, lost, enemy.hp, enemy.blocked_by])
	)
	sim.ranger_combat.attack_presented.connect(func(_unit: DeploymentState.Placement, _serial: int, clip: StringName) -> void:
		var witness: BattleSimulation = check.sim.get_ref()
		if clip == &"Attack":
			clocks.append(witness.clock.tick)
	)
	_check(state.deploy(spec, Vector2i(6, 3), -1).is_empty(), spec.label + " legally deploys facing the route")
	while clocks.size() < 5 and sim.clock.tick < 4000 and sim.clock.is_running():
		sim.clock.advance_frame()
	_check(clocks.size() == 5 and clocks[1] - clocks[0] == interval and clocks[2] - clocks[1] == interval,
		spec.label + " emits Attack at its canonical interval")
	_check(not hits.is_empty() and hits[0][1] == damage and hits[0][2] == 400 - damage,
		spec.label + " removes the true amount of HP from E01")
	_check(hits.any(func(hit: Array) -> bool: return hit[3] == id), spec.label + " damages an enemy it is actually blocking")
	if id != PATROL:
		_check(hits.size() > clocks.size(), spec.label + " frontal attack can damage multiple enemies")
	else:
		_check(hits.size() == clocks.size(), spec.label + " hits one enemy per attack even with multiple held targets")

func _facing() -> void:
	var sim := _battle([], 2)
	var state := sim.deployment
	var patrol := DeployableLevels.definition(PATROL)
	state.deploy(patrol, Vector2i(6, 3), 1)
	while sim.clock.tick < 2500:
		sim.clock.advance_frame()
	var unit := state.placed[PATROL]
	_check(unit.blocking_count == 2 and sim.active[1].hp == E01.max_hp and sim.active[2].hp == E01.max_hp,
		"An away-facing Patrolman still blocks but never attacks behind itself")

func _charges() -> void:
	var sim := _battle([], 24)
	var state := sim.deployment
	var guard := DeployableLevels.definition(GUARD)
	var scout := DeployableLevels.definition(SCOUT)
	_check(state.deploy(guard, Vector2i(6, 3), -1).is_empty(), "Guard starts deployed")
	_check(state.deploy(scout, Vector2i(1, 0), 1).is_empty(), "Untrained Scout starts deployed")
	var unit := state.placed[GUARD]
	var ready := BattleSkillStatus.read(unit, state)
	var locked := BattleSkillStatus.read(state.placed[SCOUT], state)
	_check(ready.mode == BattleSkillStatus.Mode.READY and ready.charges == 4 and ready.maximum == 4
		and ready.progress == -1.0, "Full Guard skill shows four ready charges")
	_check(locked.mode == BattleSkillStatus.Mode.LOCKED and locked.reason.contains("Records"),
		"Locked Scout shows its Records prerequisite")
	var early := state.deploy(guard, Vector2i(8, 3), -1)
	_check(not early.is_empty() and state.cooldown_ticks(GUARD) == 1920, "Repeat Guard waits 32 combat seconds")
	while state.cooldown_ticks(GUARD) > 0:
		sim.clock.advance_frame()
	_check(state.deploy(guard, Vector2i(8, 3), -1).is_empty(), "Same type can deploy again legally")
	var copy := state.placed[&"ranger.guard_veteran#2"]
	var fired := sim.tap_unit(GUARD)
	if not fired:
		fired = sim.tap_unit(copy.id)
		var previous := unit
		unit = copy
		copy = previous
	_check(fired, "Tapping a Guard with a legal frontal target spends a real skill")
	var partly := BattleSkillStatus.read(unit, state)
	_check(partly.mode == BattleSkillStatus.Mode.READY and partly.charges == 3 and partly.remaining_ticks == 780
		and BattleSkillStatus.read(copy, state).charges == 4, "One recovering charge does not disable a ready skill or consume a copy's charge")
	sim.clock.set_speed(2)
	sim.clock.paused = true
	sim.clock.advance_frame()
	_check(BattleSkillStatus.read(unit, state).remaining_ticks == partly.remaining_ticks, "Paused display holds the actual deadline")
	sim.clock.paused = false
	sim.clock.advance_frame()
	partly = BattleSkillStatus.read(unit, state)
	_check(partly.remaining_ticks == 778 and is_equal_approx(partly.progress, 2.0 / 780.0), "2× fills at two clock steps")
	unit.jammed_until = sim.clock.tick + 10
	unit.skill_recharge_tick += 120
	var jammed := BattleSkillStatus.read(unit, state)
	_check(jammed.mode == BattleSkillStatus.Mode.LOCKED and jammed.remaining_ticks == 898,
		"Jammed label and extended deadline come from the current placement")
	while unit.skill_recharge_tick > 0 and not sim.clock.stopped:
		sim.clock.advance_frame()
	_check(BattleSkillStatus.read(unit, state).just_ready and BattleSkillStatus.read(unit, state).charges == 4,
		"Newly recovered charge uses the clock-based Ready transition")
	var medic := DeployableLevels.definition(MEDIC) as RangerSpec
	var trained := DeploymentState.Placement.new(medic, Vector2i(2, 0), 1, medic.cost, sim.clock.tick,
		[medic.records_enhancement])
	trained.spend_skill_charge(sim.clock.tick)
	var spent := BattleSkillStatus.read(trained, state)
	_check(spent.mode == BattleSkillStatus.Mode.SPENT and spent.progress < 0.0 and spent.charges == 0,
		"One-use Medic skill shows spent with no invented recovery")
	_check(state.retreat(unit.id) and state.cooldown_ticks(GUARD) == 1920 and state.placed.has(copy.id),
		"Retreat keeps the other copy and restarts the shared type cooldown")

func _facility_stock() -> void:
	var sim := _battle([], 20, 90.0)
	var state := sim.deployment
	var cabin := DeployableLevels.definition(CABIN)
	var post := DeployableLevels.definition(POST)
	state.deploy(post, Vector2i(1, 0), 1)
	var paid := state.tokens
	_check(state.cooldown_ticks(POST) == 0 and state.build_ticks_left(&"facility.logistics_post#1") == 0,
		"First Post remains free and instant")
	state.deploy(cabin, Vector2i(5, 0), 1)
	var unit := state.placed[CABIN]
	_check(BattleSkillStatus.read(unit, state).mode == BattleSkillStatus.Mode.LOCKED
		and state.cooldown_ticks(CABIN) == 2640 and state.build_ticks_left(CABIN) == 360,
		"Facility stock stays locked during the unchanged construction time")
	_check(state.cancel_construction(CABIN) and state.tokens == paid and state.cooldown_ticks(CABIN) == 2640,
		"Cancel refunds paid Tokens and retains the per-type cooldown")
	while state.cooldown_ticks(CABIN) > 0 and not sim.clock.stopped:
		sim.clock.advance_frame()
	_check(state.deploy(cabin, Vector2i(5, 0), 1).is_empty(), "Facility is re-eligible when its shared cooldown expires")
	var replacement := state.placed[&"facility.medic_cabin#2"]
	while replacement.stock == 0 and not sim.clock.stopped:
		sim.clock.advance_frame()
	var stock := BattleSkillStatus.read(replacement, state)
	_check(stock.charges == 1 and stock.maximum == 2 and stock.progress >= 0.0
		and stock.just_ready, "Real Facility stock is ready while its next kit is restocking")

func _chaos_values() -> void:
	var arena := ChaosConfiguration.new()
	arena.select_route(&"T02")
	arena.set_quantity(0, &"E01", 3)
	var guard := DeployableLevels.definition(GUARD)
	var effects := BattleModifiers.new([&"B15"])
	var stage := arena.build_stage()
	_check(stage.opening_delay_seconds == 18.0 and stage.waves[0].groups[0].interval_seconds == 2.5,
		"Chapter 2 pacing does not change standalone arena preparation")
	var state := DeploymentState.new(T01.map, CombatClock.new(), 100, null, [], effects)
	state.deploy(guard, Vector2i(6, 3), -1)
	_check(state.cooldown_ticks(GUARD) == 1248, "B15 composes with the shared new Ranger cooldown")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
