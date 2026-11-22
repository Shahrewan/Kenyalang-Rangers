extends SceneTree

const TRIAL := preload("res://data/stages/c16_modifier_trial.tres")
const MULU := preload("res://data/stages/campaign/t02_gunung_mulu.tres")
const E01 := preload("res://data/enemies/e01_forest_trespasser.tres")
const SMOKE := preload("res://data/enemies/e06_smoke_infiltrator.tres")
const DRONE := preload("res://data/enemies/e08_recon_drone.tres")
const SIEGE := preload("res://data/enemies/e11_demolitionist.tres")
const BREACHER := preload("res://data/enemies/e13_heavy_breacher.tres")
const IGNITION := preload("res://data/enemies/e14_ignition_operator.tres")
const FATAL := preload("res://data/enemies/e15_wildlife_trafficker.tres")

var _checks := 0
var _failed := 0

func _initialize() -> void:
	_recon_reveal_and_waves()
	_damage_and_speed()
	_cooldown_and_silence()
	_logistics_and_siege()
	_support_and_weakness()
	_disruption_weakness()
	_heat_and_escape()
	print("Modifier combat: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _recon_reveal_and_waves() -> void:
	var stage := MULU.duplicate() as BattleStage
	stage.opening_delay_seconds = 8.0
	stage.waves = [_wave([_group(SMOKE, 0), _group(E01, 1)], 10.0), _wave([_group(E01, 1)])]
	var battle := _battle(stage, [&"B01", &"B03", &"D06", &"D07", &"D13"])
	_frames(battle, 180)
	_check(battle.recon_entries().is_empty(), "Recon does not announce early")
	_frames(battle, 1)
	_check(battle.recon_entries() == stage.map.spawns and battle.recon_seconds_left() == 5, "Recon identifies both actual entry gates at five combat seconds")
	battle.clock.paused = true
	_frames(battle, 60)
	battle.clock.dialogue_open = true
	battle.clock.paused = false
	_frames(battle, 60)
	_check(battle.clock.tick == 181 and battle.recon_seconds_left() == 5 and battle.active.is_empty(), "Pause and dialogue freeze recon and the incoming wave")
	battle.clock.dialogue_open = false
	_frames(battle, 300)
	var infiltrator := battle.active[1]
	_check(battle.recon_entries().is_empty() and infiltrator.is_targetable(battle.clock.tick) and infiltrator.revealed_until == 661, "First arrival clears recon and gets a three-second reveal")
	_check(infiltrator.smoke_until == 751, "D06 extends the actual initial smoke by two seconds")
	_frames(battle, 95)
	_check(battle.active.size() == 1, "D13 still respects the modified arrival interval")
	_frames(battle, 1)
	_check(battle.active.size() == 2 and battle.active[2].route.cells.front() == Vector2i(0, 3), "D13 delivers the second group exactly 96 ticks later at its own gate")
	_frames(battle, 84)
	_check(not infiltrator.is_targetable(battle.clock.tick), "Visibility Sweep expires while the longer smoke still conceals")
	_frames(battle, 90)
	_check(infiltrator.is_targetable(battle.clock.tick), "Smoke expiry returns normal targeting")
	battle.defeat_enemy(1)
	battle.defeat_enemy(2)
	_frames(battle, 359)
	_check(battle.active.is_empty() and battle.recon_entries() == [Vector2i(0, 3)], "Next populated wave warns at the retained rest and correct gate")
	_frames(battle, 1)
	_check(battle.active.size() == 1 and battle.wave_number == 2, "D07 shortens the ten-second rest to six combat seconds")

func _damage_and_speed() -> void:
	var battle := _battle(_stage(E01), [&"B05", &"B06", &"B09", &"B14", &"D03", &"D12"], 120)
	var scout := _unit(battle, &"ranger.scout_sniper")
	battle.deployment.deploy(scout, Vector2i(1, 0), -1)
	_frames(battle, 1)
	var soldier := battle.deployment.placed[scout.id]
	_check(battle.deployment.tokens == 106 and soldier.hp == 75, "Effective D12 cost and shifted HP are used in the actual drop")
	_check(battle.active[1].hp == 66 and soldier.next_attack_tick == 109, "B05 and B14 raise real damage and B06 changes the next auto-attack")
	_check(soldier.spec.attack_range == DeployableLevels.definition(scout.id).attack_range, "Damage and HP effects preserve attack geometry")
	var aerial := _battle(_stage(DRONE), [&"D02", &"D08", &"D11"])
	_frames(aerial, 2)
	var enemy := aerial.active[1]
	_check(enemy.hp == roundi(DRONE.max_hp * 1.15), "D08 increases actual spawned HP")
	_check(is_equal_approx(enemy.distance, DRONE.tiles_per_second * 1.35 * CombatClock.STEP_SECONDS), "D02 and D11 add once on live aerial movement")

func _cooldown_and_silence() -> void:
	for ids in [[&"B07"], [&"D04"], [&"B07", &"D04"]]:
		var selected: Array[StringName] = []
		selected.assign(ids)
		var battle := _battle(_stage(E01), selected, 100)
		var guard := _unit(battle, &"ranger.guard_veteran")
		battle.deployment.deploy(guard, Vector2i(2, 1), -1)
		_frames(battle, 1)
		_check(battle.tap_ranger(guard.id), "Guard uses its skill with %s" % [ids])
		var seconds := 13.0
		if &"D04" in ids:
			seconds *= 1.2
		if &"B07" in ids:
			seconds /= 1.2
		var placed := battle.deployment.placed[guard.id]
		_check(placed.skill_charges == 3 and placed.skill_recharge_tick == 1 + CombatClock.ticks_for(seconds), "Live recharge deadline uses %s in the documented order" % [ids])
	var silent := _battle(_stage(BREACHER), [&"B15"], 120)
	var guard := _unit(silent, &"ranger.guard_veteran")
	var cabin := _unit(silent, &"facility.medic_cabin")
	var state := silent.deployment
	state.deploy(guard, Vector2i(2, 1), -1)
	state.deploy(cabin, Vector2i(1, 0), 1)
	var building := state.placed[cabin.id]
	building.stock = 1
	_check(state.placed[guard.id].skill_charges == 0 and not silent.tap_ranger(guard.id) and "Silent Mobilization" in state.last_skill_error, "B15 blocks Ranger skills and grants no charges")
	_check(not silent.tap_unit(cabin.id) and state.armed.is_empty() and building.stock == 1, "B15 blocks a Facility skill before arming or spending stock")
	_check(state.retreat(guard.id) and state.cooldown_ticks(guard.id) == 195, "B15 applies the 35% shorter redeploy cooldown")
	_check(state.cooldown_ticks(cabin.id) == 468 and state.build_ticks_left(cabin.id) == 360, "Facility cooldown shortens while construction time stays fixed")

func _logistics_and_siege() -> void:
	var quiet := _stage(E01)
	quiet.opening_delay_seconds = 40.0
	var mixed := _battle(quiet, [&"B13", &"B15", &"D01"])
	var post := _unit(mixed, &"facility.logistics_post")
	_check(mixed.deployment.tokens == 35 and mixed.deployment.deploy(post, Vector2i(1, 0), 1).is_empty(), "B13's extra Tokens reach the live opening")
	_frames(mixed, 600)
	_check(mixed.deployment.tokens == 43, "Requisition, Silent Mobilization and Thin Supply Line resolve to eight Tokens per payout")

	var siege_stage := _stage(SIEGE)
	var battle := _battle(siege_stage, [&"D09", &"D10"], 100)
	var state := battle.deployment
	post = _unit(battle, &"facility.logistics_post")
	var first := &"facility.logistics_post#1"
	var second := &"facility.logistics_post#2"
	state.deploy(post, Vector2i(5, 0), 1)
	state.deploy(post, Vector2i(1, 0), 1)
	_check(state.build_ticks_left(first) == 0 and state.build_ticks_left(second) == 450 and state.tokens == 80, "D10 keeps the free Post instant and lengthens only the timed build")
	_check(not state.receive_hit(second, 99, EnemyAttackProfile.Kind.RANGED), "Ordinary damage still cannot harm the construction site")
	_frames(battle, 36)
	_check(state.placed[second].hp == 160, "Siege windup leaves HP intact before its deadline")
	_frames(battle, 1)
	_check(state.placed[second].hp == 85 and state.build_ticks_left(second) > 0 and state.placed[first].hp == 160, "D09 delivers 75 HP of explicit Siege to the legal unfinished target")

func _support_and_weakness() -> void:
	var battle := _battle(_stage(BREACHER), [&"B08", &"B10", &"B11", &"B12"], 120)
	var blocker := _unit(battle, &"ranger.patrolman").duplicate() as DeploymentSpec
	blocker.attack_damage = 0
	var state := battle.deployment
	state.deploy(blocker, Vector2i(1, 1), -1)
	_frames(battle, 1)
	var enemy := battle.active[1]
	var unit := state.placed[blocker.id]
	battle._receive_enemy_hit(enemy, blocker.id, EnemyAttackProfile.Kind.MELEE)
	_check(unit.hp == 275, "B11 leaves damage unchanged while the Ranger is not blocking")
	enemy.distance = 0.49
	_frames(battle, 1)
	battle._receive_enemy_hit(enemy, blocker.id, EnemyAttackProfile.Kind.MELEE)
	_check(unit.blocking_count == 1 and unit.hp == 235, "B11 reduces damage while the Ranger is actually holding the enemy")
	_check(state.heal_ranger(blocker.id, 20) == 24 and unit.hp == 259, "B10 scales received healing")
	var hit_tick := enemy.ability_fire_tick
	_frames(battle, hit_tick - battle.clock.tick)
	_check(unit.brace_charges == 0 and unit.knocked_down_until == 0, "B12 ignores the first actual Knockdown")
	_frames(battle, 450)
	_check(unit.knocked_down_until > battle.clock.tick, "The second Knockdown affects the same placement")
	state.retreat(blocker.id)
	_frames(battle, 300)
	state.deploy(blocker, Vector2i(2, 1), -1)
	_check(state.placed[blocker.id].brace_charges == 1, "Redeployment grants a fresh Brace charge")

	enemy.stunned_until = battle.clock.tick + 1
	enemy.sonic_slow_until = battle.clock.tick + 1
	enemy.add_damage_mark(battle.clock.tick, battle.clock.tick + 1, 2)
	enemy.add_damage_mark(battle.clock.tick, battle.clock.tick + 1, 2)
	var hp := enemy.hp
	battle.damage_enemy(1, 100)
	_check(hp - enemy.hp == 125, "Exploit Weakness adds one 20% bonus despite multiple effects and marks")
	_frames(battle, 1)
	hp = enemy.hp
	battle.damage_enemy(1, 100)
	_check(hp - enemy.hp == 100, "Expired effects no longer qualify")

func _disruption_weakness() -> void:
	var battle := _battle(_stage(E01), [&"B08"], 120)
	var beacon := _unit(battle, &"facility.disruption_beacon")
	battle.deployment.deploy(beacon, Vector2i(1, 0), 1)
	_frames(battle, 1)
	var enemy := battle.active[1]
	battle.damage_enemy(1, 10)
	_check(enemy.hp == 90, "An unfinished Disruption Beacon provides no weakness")
	_frames(battle, 419)
	enemy.distance = 0.0
	battle.damage_enemy(1, 10)
	_check(enemy.hp == 78, "An enemy inside the completed Disruption zone takes the B08 bonus")
	enemy.distance = 4.0
	enemy.revealed_until = battle.clock.tick + 60
	battle.damage_enemy(1, 10)
	_check(enemy.hp == 68, "Reveal alone does not apply the B08 bonus outside the Disruption zone")

func _heat_and_escape() -> void:
	var heated := _stage(IGNITION)
	heated.heat_capacity = 100.0
	heated.heat_integrity_loss = 10
	heated.opening_delay_seconds = 7.0
	var battle := _battle(heated, [&"B02", &"D14"], 120)
	var beacon := _unit(battle, &"facility.firebreak_beacon")
	battle.deployment.deploy(beacon, Vector2i(1, 0), 1)
	_frames(battle, 421)
	_check(is_equal_approx(battle.heat, IGNITION.heat_per_second * CombatClock.STEP_SECONDS * 1.05 * 0.60), "Heat modifiers combine once before Firebreak's runtime multiplier")
	var normal := _battle(_stage(E01), [&"B04", &"D15"])
	_escape(normal)
	_check(normal.escaped == 1 and normal.integrity == 89 and not normal.is_perfect(), "The reduced ordinary penalty still records an escape")
	var fatal := _battle(_stage(FATAL), [&"B04", &"D15"])
	_escape(fatal)
	_check(fatal.integrity == 0 and fatal.fatal_escape_id == FATAL.enemy_id and fatal.outcome == BattleSimulation.Outcome.LOST, "Safe Extraction cannot soften a fatal escape")

func _escape(battle: BattleSimulation) -> void:
	_frames(battle, 1)
	var enemy := battle.active[1]
	enemy.distance = enemy.route.cells.size() - 1.00001
	_frames(battle, 1)

func _battle(stage: BattleStage, ids: Array[StringName], tokens := 0) -> BattleSimulation:
	var effects := BattleModifiers.new(ids)
	var battle := BattleSimulation.new(effects.stage(stage))
	battle.deployment = DeploymentState.new(stage.map, battle.clock, effects.opening_tokens(tokens), effects.logistics(LogisticsRules.new()), [], battle.effects)
	return battle

func _stage(enemy: BattleEnemyDefinition) -> BattleStage:
	var stage := TRIAL.duplicate() as BattleStage
	stage.opening_delay_seconds = 0
	stage.heat_capacity = 0
	stage.heat_integrity_loss = 0
	stage.waves = [_wave([_group(enemy, 0)])]
	return stage

func _group(enemy: BattleEnemyDefinition, route: int) -> BattleSpawnGroup:
	var group := BattleSpawnGroup.new()
	group.enemy = enemy
	group.route_index = route
	group.count = 1
	group.interval_seconds = 2.0
	return group

func _wave(groups: Array[BattleSpawnGroup], rest := 0.0) -> BattleWave:
	var wave := BattleWave.new()
	wave.groups = groups
	wave.rest_after_seconds = rest
	return wave

func _frames(battle: BattleSimulation, count: int) -> void:
	for i in count:
		battle.clock.advance_frame()

func _unit(battle: BattleSimulation, id: StringName) -> DeploymentSpec:
	return battle.effects.deployable(DeployableLevels.definition(id))

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
