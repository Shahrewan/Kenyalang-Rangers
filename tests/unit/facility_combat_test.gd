extends SceneTree

const STAGE := preload("res://data/stages/c05_first_contact.tres")
const POST: FacilitySpec = preload("res://data/facilities/logistics_post.tres")
const CABIN: FacilitySpec = preload("res://data/facilities/medic_cabin.tres")
const SKILL_RELAY: FacilitySpec = preload("res://data/facilities/skill_relay_station.tres")
const DISPATCH: FacilitySpec = preload("res://data/facilities/dispatch_relay.tres")
const SCOUT: RangerSpec = preload("res://data/rangers/scout_sniper.tres")
const GUARD: RangerSpec = preload("res://data/rangers/guard_veteran.tres")
const MECHANIC: RangerSpec = preload("res://data/rangers/outpost_mechanic.tres")

var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_placement_and_siege()
	_attacks_in_combat()
	_medic_stock()
	_mechanic_repair()
	_relay_cooldowns()
	print("Facility checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _placement_and_siege() -> void:
	var battle := _encounter()
	var state := battle.deployment
	var anchor := Vector2i(1, 0)
	_check(not state.deploy(CABIN, Vector2i(11, 4), 1).is_empty() and state.tokens == 300, "An off-board Facility footprint cannot spend Tokens")
	_check(state.deploy(CABIN, anchor, 1).is_empty() and state.tokens == 278 and state.occupancy.size() == 2, "A paid Facility reserves two raised cells")
	var cabin := state.placed[CABIN.id]
	_check(not state.deploy(POST, anchor, 1).is_empty() and state.posts_deployed == 0 and state.tokens == 278, "An overlapping Post cannot use the first-free grant")
	for kind in [EnemyAttackProfile.Kind.MELEE, EnemyAttackProfile.Kind.RANGED, EnemyAttackProfile.Kind.PROJECTILE]:
		_check(not state.receive_hit(CABIN.id, 50, kind) and cabin.hp == 170, "Ordinary damage kind %d cannot harm construction" % kind)
	battle.clock.paused = true
	_check(not state.receive_hit(CABIN.id, 60, EnemyAttackProfile.Kind.SIEGE) and cabin.hp == 170, "Pause holds incoming Siege damage")
	battle.clock.paused = false
	_check(state.receive_hit(CABIN.id, 60, EnemyAttackProfile.Kind.SIEGE) and cabin.hp == 110 and state.build_ticks_left(CABIN.id) == 360, "Siege damages an unfinished Facility with its build timer intact")
	_check(not state.retreat(CABIN.id) and state.cancel_construction(CABIN.id) and state.tokens == 300 and state.occupancy.is_empty(), "Cancelling damaged construction returns exactly the paid cost and releases both cells")
	_check(not state.cancel_construction(CABIN.id) and state.tokens == 300, "Cancellation cannot refund twice")
	state.deploy(POST, anchor, 1)
	_check(state.tokens == 300 and state.build_ticks_left(&"facility.logistics_post#1") == 0 and state.cooldown_ticks(POST.id) == 0, "First catalog Post is free, instant and cooldown-free")
	_frames(battle, 600)
	_check(state.tokens == 310, "Level 1 catalog Post yields 10 Tokens per 10 combat seconds")

func _attacks_in_combat() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(CABIN, Vector2i(1, 0), 1)
	state.deploy(SCOUT, Vector2i(1, 2), 1)
	var ranged := _enemy(battle, 100, 1.0)
	_set_attack(ranged, EnemyAttackProfile.Kind.RANGED, 10)
	var projectile := _enemy(battle, 101, 1.0)
	_set_attack(projectile, EnemyAttackProfile.Kind.PROJECTILE, 10)
	var melee := _enemy(battle, 102, 1.0)
	_set_attack(melee, EnemyAttackProfile.Kind.MELEE, 10)
	_frames(battle, 1)
	_check(state.placed[CABIN.id].hp == 170 and state.placed[SCOUT.id].hp == 80, "Live ranged and projectile attacks hit the elevated Ranger and leave the site alone")
	var siege := _enemy(battle, 103, 1.0)
	_set_attack(siege, EnemyAttackProfile.Kind.SIEGE, 60, 0.5)
	_frames(battle, 1)
	_check(siege.aim_target == CABIN.id and state.placed[CABIN.id].hp == 170, "A Siege windup targets the construction site explicitly")
	battle.clock.dialogue_open = true
	_frames(battle, 120)
	_check(battle.clock.tick == 2 and state.placed[CABIN.id].hp == 170, "Dialogue holds a live Siege windup")
	battle.clock.dialogue_open = false
	_frames(battle, 30)
	_check(state.placed[CABIN.id].hp == 110, "Siege lands after the exact windup and damages construction during a battle")
	_check(not state.receive_hit(SCOUT.id, 60, EnemyAttackProfile.Kind.SIEGE), "Dedicated Siege hits cannot target a Ranger")

	battle = _encounter()
	state = battle.deployment
	state.deploy(POST, Vector2i(1, 0), 1)
	siege = _enemy(battle, 100, 1.0)
	_set_attack(siege, EnemyAttackProfile.Kind.SIEGE, 60)
	_frames(battle, 1)
	var post_id := &"facility.logistics_post#1"
	_check(state.placed[post_id].hp == 100 and not state.cancel_construction(post_id), "A completed Post takes Siege damage and cannot be cancelled")
	_frames(battle, 60)
	_check(state.placed[post_id].hp == 40, "The 160 HP Post survives two 60 HP Siege attacks")
	_frames(battle, 60)
	_check(not state.placed.has(post_id) and state.occupancy.is_empty() and state.tokens == 300, "The third Siege hit destroys the Post, releases its cells and grants no refund")
	_frames(battle, 600)
	_check(state.tokens == 300 and state.cost_for(POST) == 20, "A destroyed Post stops payouts and the next still uses the repeat price")

func _medic_stock() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(CABIN, Vector2i(1, 0), 1)
	state.deploy(SCOUT, Vector2i(1, 2), 1)
	var cabin := state.placed[CABIN.id]
	var scout := state.placed[SCOUT.id]
	_check(not battle.tap_unit(CABIN.id) and cabin.stock == 0, "Kits cannot be armed under construction")
	_frames(battle, 839)
	_check(cabin.stock == 0, "Kit generation starts after construction and needs its full cycle")
	battle.clock.paused = true
	_frames(battle, 1200)
	_check(cabin.stock == 0 and battle.clock.tick == 839, "Paused time cannot generate a kit")
	battle.clock.paused = false
	_frames(battle, 1)
	_check(cabin.stock == 1, "The first kit arrives at the combat deadline")
	_frames(battle, 960)
	_check(cabin.stock == 2, "Medic stock caps at two kits")
	state.receive_hit(SCOUT.id, 80, EnemyAttackProfile.Kind.PROJECTILE)
	state.receive_hit(CABIN.id, 60, EnemyAttackProfile.Kind.SIEGE)
	_check(battle.tap_unit(CABIN.id) and cabin.stock == 2 and scout.hp == 20, "Tapping the Cabin arms a kit without spending it")
	state.select_target(cabin.anchor)
	_check(not battle.confirm_skill_target() and cabin.stock == 2 and cabin.hp == 110, "A kit cannot repair a Facility")
	state.select_target(scout.anchor)
	_check(battle.confirm_skill_target() and scout.hp == 85 and cabin.stock == 1, "Confirming an injured Ranger restores 65 HP and consumes one kit")
	battle.tap_unit(CABIN.id)
	state.select_target(scout.anchor)
	_check(battle.confirm_skill_target() and scout.hp == 100 and cabin.stock == 0, "A second kit caps healing at maximum HP")

func _mechanic_repair() -> void:
	var battle := _encounter()
	var state := battle.deployment
	var barricade := DeploymentSpec.new()
	barricade.id = &"ranger.barricade_ops"
	barricade.kind = DeploymentSpec.Kind.GROUND_PAIR
	barricade.max_hp = 520
	state.deploy(MECHANIC, Vector2i(1, 2), 1)
	state.deploy(CABIN, Vector2i(1, 0), 1)
	state.deploy(barricade, Vector2i(1, 1), 1)
	state.deploy(GUARD, Vector2i(3, 1), -1)
	state.receive_hit(CABIN.id, 40, EnemyAttackProfile.Kind.SIEGE)
	state.receive_hit(barricade.id, 30, EnemyAttackProfile.Kind.MELEE)
	state.receive_hit(GUARD.id, 100, EnemyAttackProfile.Kind.MELEE)
	_frames(battle, 179)
	_check(state.placed[CABIN.id].hp == 130, "Mechanic repair waits for its three-second cadence")
	_frames(battle, 1)
	_check(state.placed[CABIN.id].hp == 150 and state.build_ticks_left(CABIN.id) == 180, "Mechanic restores 20 HP to an eligible construction site")
	_frames(battle, 180)
	_check(state.placed[barricade.id].hp == 510 and state.placed[GUARD.id].hp == 130, "Mechanic repairs Barricade Ops and leaves ordinary Rangers to healing")

func _relay_cooldowns() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(SKILL_RELAY, Vector2i(1, 0), 1)
	state.deploy(SCOUT, Vector2i(1, 2), 1)
	state.deploy(GUARD, Vector2i(6, 3), 1)
	var scout := state.placed[SCOUT.id]
	var guard := state.placed[GUARD.id]
	scout.skill_charges = 0
	scout.skill_recharge_tick = 918
	guard.skill_charges = 2
	guard.skill_recharge_tick = 1000
	_frames(battle, 839)
	_check(scout.skill_charges == 0 and scout.skill_recharge_tick == 918, "Skill Relay pulse waits for construction and its interval")
	_frames(battle, 1)
	_check(scout.skill_charges == 1 and scout.skill_recharge_tick == 0 and guard.skill_recharge_tick == 1000, "Skill Relay restores the nearby pending charge and leaves an out-of-range charge alone")

	battle = _encounter()
	state = battle.deployment
	state.deploy(DISPATCH, Vector2i(1, 0), 1)
	state.deploy(GUARD, Vector2i(6, 3), 1)
	state.deploy(SCOUT, Vector2i(1, 2), 1)
	scout = state.placed[SCOUT.id]
	scout.skill_charges = 0
	scout.skill_recharge_tick = 1440
	_frames(battle, 900)
	state.retreat(GUARD.id)
	state.deploy(CABIN, Vector2i(5, 0), 1)
	_frames(battle, 60)
	_check(state.cooldown_ticks(GUARD.id) == 60 and state.cooldown_ticks(CABIN.id) == 480, "Dispatch reduces existing Ranger and Facility deployment cooldowns")
	_check(state.build_ticks_left(CABIN.id) == 300 and scout.skill_recharge_tick == 1440, "Dispatch leaves construction and active-skill timers alone")

func _encounter() -> BattleSimulation:
	var stage := STAGE.duplicate() as BattleStage
	stage.opening_delay_seconds = 120.0
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(stage.map, battle.clock, 300, null, [SCOUT.records_enhancement])
	return battle

func _enemy(battle: BattleSimulation, id: int, progress: float) -> BattleEnemy:
	var definition := BattleEnemyDefinition.new()
	definition.max_hp = 500
	definition.tiles_per_second = 0.10
	var enemy := BattleEnemy.new(definition, STAGE.routes[0])
	enemy.distance = progress
	battle.active[id] = enemy
	return enemy

func _set_attack(enemy: BattleEnemy, kind: EnemyAttackProfile.Kind, damage: int, windup := 0.0) -> void:
	var profile := EnemyAttackProfile.new()
	profile.kind = kind
	profile.windup_seconds = windup
	enemy.definition.attack_profile = profile
	enemy.definition.attack_damage = damage
	enemy.definition.attack_seconds = 1.0

func _frames(battle: BattleSimulation, count: int) -> void:
	for frame in count:
		battle.clock.advance_frame()

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failed += 1
