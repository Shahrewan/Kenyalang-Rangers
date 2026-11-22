extends SceneTree

const STAGE := preload("res://data/stages/c05_first_contact.tres")
const POST: FacilitySpec = preload("res://data/facilities/logistics_post.tres")
const CABIN: FacilitySpec = preload("res://data/facilities/medic_cabin.tres")
const SKILL_RELAY: FacilitySpec = preload("res://data/facilities/skill_relay_station.tres")
const DISPATCH: FacilitySpec = preload("res://data/facilities/dispatch_relay.tres")
const SONIC: FacilitySpec = preload("res://data/facilities/sonic_turret.tres")
const ELECTRIC: FacilitySpec = preload("res://data/facilities/electric_pulse_turret.tres")
const CANOPY: FacilitySpec = preload("res://data/facilities/canopy_defense_launcher.tres")
const TOWER: FacilitySpec = preload("res://data/facilities/sentry_tower.tres")
const FIREBREAK: FacilitySpec = preload("res://data/facilities/firebreak_beacon.tres")
const CALLTOWER: FacilitySpec = preload("res://data/facilities/specialist_calltower.tres")
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
	_sonic_turret()
	_electric_turret()
	_canopy_launcher()
	_tower_slots_and_detection()
	_firebreak_heat()
	_specialist_discount()
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

func _sonic_turret() -> void:
	var battle := _encounter()
	var state := battle.deployment
	var upgraded := SONIC.duplicate() as FacilitySpec
	upgraded.level = 100
	state.deploy(upgraded, Vector2i(1, 0), 1)
	var ground_one := _enemy(battle, 100, 0.7)
	var ground_two := _enemy(battle, 101, 1.7)
	var distant := _enemy(battle, 102, 4.2)
	var aerial := _enemy(battle, 103, 1.0)
	aerial.definition.aerial = true
	_frames(battle, 419)
	_check(state.build_ticks_left(SONIC.id) == 1 and ground_one.hp == 500, "Level 100 Sonic retains the full seven-second construction with no early shot")
	_frames(battle, 1)
	_check(ground_one.hp == 488 and ground_two.hp == 488 and distant.hp == 500 and aerial.hp == 500, "Sonic hits each ground target in its square for 12 HP")
	var distance := ground_one.distance
	_frames(battle, 1)
	_check(ground_one.sonic_slow_until == 510 and is_equal_approx(ground_one.distance - distance, 0.065 * CombatClock.STEP_SECONDS), "Sonic's separate slow changes movement")
	battle.clock.paused = true
	_frames(battle, 180)
	_check(battle.clock.tick == 421 and ground_one.hp == 488 and state.placed[SONIC.id].next_attack_tick == 588, "Pause holds the Sonic cadence and slow")
	battle.clock.paused = false
	_frames(battle, 167)
	_check(ground_one.hp == 476, "Sonic attacks again after 2.8 combat seconds")

func _electric_turret() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(ELECTRIC, Vector2i(1, 0), 1)
	var tech := _enemy(battle, 100, 1.8)
	tech.definition.technological = true
	var ground := _enemy(battle, 101, 1.1)
	_frames(battle, 480)
	_check(tech.hp == 480 and ground.hp == 500 and state.placed[ELECTRIC.id].burst_remaining == 2, "Electric Pulse begins a three-hit burst with the rounded Technological bonus")
	_frames(battle, 11)
	_check(tech.hp == 480, "Electric burst hits remain separated in time")
	battle.clock.set_speed(2)
	_frames(battle, 1)
	_check(tech.hp == 460 and battle.clock.tick == 493, "Second burst hit uses combat time at two-times speed")
	battle.clock.set_speed(1)
	_frames(battle, 11)
	_check(tech.hp == 440 and state.placed[ELECTRIC.id].next_attack_tick == 834, "Third hit starts a 5.5-second recovery")
	tech.distance = 7.0
	_frames(battle, 329)
	_check(ground.hp == 500, "Electric Pulse stays in recovery until the next burst")
	_frames(battle, 1)
	_check(ground.hp == 485 and state.placed[ELECTRIC.id].burst_remaining == 2, "The next burst deals 15 HP to a non-Technological target")

func _canopy_launcher() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(CANOPY, Vector2i(5, 2), 1)
	var air := _enemy(battle, 100, 2.1)
	air.definition.aerial = true
	var near := _enemy(battle, 101, 4.8)
	var leading := _enemy(battle, 102, 8.0)
	_frames(battle, 540)
	_check(air.hp == 466 and near.hp == 483 and leading.hp == 500, "Canopy centers its splash on Aerial priority with 34 aerial and 17 ground damage")
	_check(state.placed[CANOPY.id].next_attack_tick == 750, "Canopy schedules its next attack after 3.5 combat seconds")

func _tower_slots_and_detection() -> void:
	var battle := _encounter()
	var state := battle.deployment
	var anchor := Vector2i(5, 2)
	var above := anchor + Vector2i.UP
	_check(not state.deploy(TOWER, Vector2i(5, 0), 1).is_empty() and state.tokens == 300, "Tower placement requires in-bounds clearance above")
	state.deploy(TOWER, anchor, 1)
	var tower := state.placed[TOWER.id]
	_check(state.occupancy.size() == 2 and state.occupancy[anchor] == TOWER.id and state.occupancy[above] == TOWER.id, "Tower occupies its base and reserves the cell above")
	_check(not state.deploy(SCOUT, anchor, 1).is_empty() and state.tokens == 235, "The mount is unavailable until the Tower is complete")
	var hidden := _enemy(battle, 100, 1.2)
	hidden.definition.concealed = true
	_frames(battle, 539)
	_check(not hidden.is_targetable() and hidden.hp == 500, "An unfinished Tower provides no detection")
	_frames(battle, 1)
	_check(hidden.is_targetable() and hidden.hp == 500, "A completed Tower reveals without dealing damage")
	_check(not state.deploy(SCOUT, above, 1).is_empty() and state.deploy(SCOUT, anchor, 1).is_empty(), "The base mounts an eligible Ranger and the clearance cell stays reserved")
	var rider := state.placed[SCOUT.id]
	_check(tower.mounted_ranger == SCOUT.id and rider.mount_tower == TOWER.id and state.interaction_id(anchor) == SCOUT.id, "The mount shares the elevated base and receives Ranger taps")
	_check(not state.deploy(MECHANIC, anchor, 1).is_empty() and state.occupancy.size() == 2 and state.tokens == 223, "The mount cannot accept a second Ranger")
	_frames(battle, 1)
	_check(hidden.hp == 476 and hidden.grid_cell().x == 2, "The mounted Ranger hits from its extended square range")
	state.receive_hit(TOWER.id, 420, EnemyAttackProfile.Kind.SIEGE)
	_check(not state.occupancy.has(above) and state.occupancy[anchor] == SCOUT.id and rider.mount_tower.is_empty() and rider.hp == 100, "Siege destruction frees clearance and dismounts the Ranger onto the legal elevated base")
	_frames(battle, 1)
	_check(not hidden.is_targetable() and not state.can_attack(rider, hidden.grid_cell(), false), "Tower destruction removes detection and the range extension")

func _firebreak_heat() -> void:
	var battle := _encounter(20.0)
	var state := battle.deployment
	state.deploy(FIREBREAK, Vector2i(1, 0), 1)
	var source := _enemy(battle, 100, 1.0)
	source.definition.heat_per_second = 10.0
	_frames(battle, 60)
	_check(is_equal_approx(battle.heat, 10.0), "An unfinished Firebreak does not slow Heat buildup")
	source.definition.heat_per_second = 0.0
	_frames(battle, 300)
	source.definition.heat_per_second = 10.0
	_frames(battle, 60)
	_check(is_equal_approx(battle.heat, 16.0), "Firebreak reduces Heat accrual by 40 percent without eliminating it")
	battle.clock.dialogue_open = true
	_frames(battle, 200)
	_check(is_equal_approx(battle.heat, 16.0) and battle.integrity == 100, "Dialogue freezes Heat and its Integrity pressure")
	battle.clock.dialogue_open = false
	battle.clock.set_speed(2)
	_frames(battle, 20)
	_check(is_zero_approx(battle.heat) and battle.integrity == 85 and state.placed[FIREBREAK.id].hp == 220, "At capacity Heat resets and removes Integrity while preserving Facility HP")

func _specialist_discount() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(CALLTOWER, Vector2i(1, 0), 1)
	var calltower := state.placed[CALLTOWER.id]
	_frames(battle, 959)
	_check(not battle.tap_unit(CALLTOWER.id) and state.specialist_discount == 0, "Calltower discount needs completed construction and a stock cycle")
	_frames(battle, 1)
	_check(battle.tap_unit(CALLTOWER.id) and state.specialist_discount == 8 and calltower.stock == 0, "Tap claims one stored Specialist discount")
	_frames(battle, 600)
	_check(not battle.tap_unit(CALLTOWER.id) and calltower.stock == 1 and state.specialist_discount == 8, "A second stored discount cannot stack with a pending one")
	var specialist := GUARD.duplicate() as RangerSpec
	specialist.id = &"qa.specialist"
	specialist.ranger_class = RangerSpec.RangerClass.SPECIALIST
	specialist.cost = 18
	_check(state.cost_for(specialist) == 10 and state.cost_for(GUARD) == 16, "Preview discounts only a Specialist by eight Tokens")
	state.deploy(GUARD, Vector2i(3, 1), 1)
	var balance := state.tokens
	_check(not state.deploy(specialist, Vector2i(5, 2), 1).is_empty() and state.tokens == balance and state.specialist_discount == 8, "An ordinary placement or invalid Specialist drop leaves the claim intact")
	_check(state.deploy(specialist, Vector2i(6, 3), 1).is_empty() and state.tokens == balance - 10 and state.specialist_discount == 0 and state.cost_for(specialist) == 18, "Only a successful Specialist deployment consumes the discount")

func _encounter(heat_capacity := 0.0) -> BattleSimulation:
	var stage := STAGE.duplicate() as BattleStage
	stage.opening_delay_seconds = 120.0
	stage.heat_capacity = heat_capacity
	stage.heat_integrity_loss = 15 if heat_capacity > 0.0 else 0
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
