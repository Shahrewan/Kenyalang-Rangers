extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const MAP: BattleMap = preload("res://data/stages/t01_forgotten_patrol.tres")
const SCOUT: RangerSpec = preload("res://data/rangers/scout_sniper.tres")
const GUARD: RangerSpec = preload("res://data/rangers/guard_veteran.tres")
const SPECIALIST: RangerSpec = preload("res://data/rangers/saboteurist.tres")
const LEVELS := [1, 20, 40, 60, 80, 100]
# Role order. HP pair, effective FacilitySpec property, base and endpoint.
const ENDPOINTS := [
	[160, 200, &"", 10, 15],
	[170, 213, &"heal_per_kit", 65, 78],
	[190, 238, &"cooldown_reduction_seconds", 3.0, 3.6],
	[200, 250, &"cooldown_reduction_seconds", 3.0, 3.6],
	[250, 313, &"attack_damage", 12, 14],
	[300, 375, &"attack_damage", 15, 18],
	[380, 475, &"attack_damage", 34, 41],
	[420, 525, &"detection_radius", 4, 5],
	[220, 275, &"heat_slow_percent", 40, 48],
	[240, 300, &"discount_tokens", 8, 10],
	[270, 338, &"attack_rate_bonus_percent", 25, 30],
	[330, 413, &"incoming_reduction_percent", 25, 30],
	[330, 413, &"outgoing_reduction_percent", 20, 24],
]
const BAY := Vector2i(1, 0)
const TOWER_BAY := Vector2i(5, 2)
const POST := &"facility.logistics_post"
const FIREBREAK := &"facility.firebreak_beacon"
const SONIC := &"facility.sonic_turret"

var _path := "user://c32-b-growth-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var seen: Array[int] = []
	for base: FacilitySpec in DeployableLevels.catalog(false):
		seen.append(base.role)
		_test_levels(base)
	seen.sort()
	_check(seen == range(ENDPOINTS.size()), "Each of the 13 roles is verified")
	_test_stacking()
	_test_progression()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".settings"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C32-B Facility growth: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _test_levels(base: FacilitySpec) -> void:
	var row: Array = ENDPOINTS[base.role]
	var effect: StringName = row[2]
	var original := DeployableLevels.effective(base, 1) as FacilitySpec
	var previous_hp: int = row[0]
	var previous_output: float = row[3]
	for level: int in LEVELS:
		var spec := DeployableLevels.effective(base, level) as FacilitySpec
		var tag := "%s Lv.%d" % [spec.label, level]
		var fraction := (level - 1) / 99.0
		var hp := roundi(lerpf(row[0], row[1], fraction))
		# Logistics has fractional carry; the relays keep precise seconds.
		var raw := lerpf(row[3], row[4], fraction)
		var expected := raw if effect.is_empty() or row[3] is float else float(roundi(raw))
		var actual := _post_average(spec.level) if effect.is_empty() else float(spec.get(effect))
		_check(spec != base and spec.level == level and spec.max_hp == hp and spec.max_hp >= previous_hp,
			tag + " HP follows the rounded linear curve on an independent spec")
		_check(is_equal_approx(actual, expected) and actual >= previous_output,
			tag + " main output follows its linear curve")
		_unchanged(spec, original, effect, tag)
		_test_combat(spec, hp, expected, tag)
		previous_hp = spec.max_hp
		previous_output = actual
	_check(base.level == 1 and base.max_hp == row[0] and (effect.is_empty() or base.get(effect) == row[3]),
		base.label + " authored resource retains original values")

func _unchanged(spec: FacilitySpec, original: FacilitySpec, effect: StringName, tag: String) -> void:
	var changed := PackedStringArray()
	for property in spec.get_property_list():
		var key: StringName = property.name
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and key not in [&"level", &"max_hp", effect]:
			if spec.get(key) != original.get(key):
				changed.append(String(key))
	_check(changed.is_empty() and spec.footprint(TOWER_BAY) == original.footprint(TOWER_BAY)
		and spec.reserved(TOWER_BAY) == original.reserved(TOWER_BAY),
		tag + " only scales the authored fields " + ", ".join(changed))

func _test_combat(spec: FacilitySpec, hp: int, effect: float, tag: String) -> void:
	var modifier_ids: Array[StringName] = []
	match spec.role:
		FacilitySpec.Role.LOGISTICS_POST, FacilitySpec.Role.DISPATCH_RELAY:
			modifier_ids = [&"B15"]
		FacilitySpec.Role.FIREBREAK:
			modifier_ids = [&"B02"]
		FacilitySpec.Role.COORDINATION_HUB:
			modifier_ids = [&"B06"]

	var battle := _encounter(modifier_ids)
	var state := battle.deployment
	var anchor := TOWER_BAY if spec.role == FacilitySpec.Role.SENTRY_TOWER else BAY
	var price := state.cost_for(spec)
	_check(state.deploy(spec, anchor, 1).is_empty(), tag + " deploys legally")
	var id := state.interaction_id(anchor)
	var unit := state.placed[id]
	var expected_build := 0 if spec.logistics_post else CombatClock.ticks_for(spec.build_seconds)
	var expected_cooldown := 0 if spec.logistics_post else CombatClock.ticks_for(spec.build_cooldown_seconds)
	if spec.role == FacilitySpec.Role.DISPATCH_RELAY:
		expected_cooldown = CombatClock.ticks_for(spec.build_cooldown_seconds * 0.65)
	_check(unit.hp == hp and unit.build_deadline == expected_build and unit.paid_cost == price
		and state.cooldown_ticks(spec.id) == expected_cooldown
		and state.occupancy.size() == 2 and state.occupancy.get(anchor + (Vector2i.UP if spec.kind == DeploymentSpec.Kind.SENTRY else Vector2i.RIGHT)) == id,
		tag + " uses scaled construction HP, original footprint, price and cooldown rules")
	_check(not state.receive_hit(id, 22, EnemyAttackProfile.Kind.RANGED) and unit.hp == hp
		and state.receive_hit(id, 9, EnemyAttackProfile.Kind.SIEGE) and unit.hp == hp - 9,
		tag + " rejects ordinary damage and receives Siege")

	match spec.role:
		FacilitySpec.Role.LOGISTICS_POST:
			_post(battle, effect, tag)
		FacilitySpec.Role.MEDIC_CABIN:
			state.deploy(SCOUT, Vector2i(1, 2), 1)
			var scout := state.placed[SCOUT.id]
			state.receive_hit(SCOUT.id, 80, EnemyAttackProfile.Kind.PROJECTILE)
			battle.clock.paused = true
			_advance(battle, 60)
			_check(unit.stock == 0 and battle.clock.tick == 0, tag + " stock waits on paused clock")
			battle.clock.paused = false
			_advance(battle, unit.next_utility_tick)
			var before := scout.hp
			_check(unit.stock == 1 and battle.tap_unit(id) and state.select_target(scout.anchor)
				and battle.confirm_skill_target() and unit.stock == 0 and scout.hp - before == int(effect),
				tag + " confirmed kit delivers scaled healing")
		FacilitySpec.Role.SKILL_RELAY:
			state.deploy(GUARD, Vector2i(2, 1), -1)
			_enemy(battle, Vector2i(1, 1))
			var guard := state.placed[GUARD.id]
			_advance(battle, 300)
			var used := battle.tap_unit(GUARD.id)
			var before := guard.skill_recharge_tick
			_advance(battle, unit.next_utility_tick - battle.clock.tick)
			_check(used and before > battle.clock.tick and guard.skill_recharge_tick == before - CombatClock.ticks_for(effect),
				tag + " subtracts scaled combat ticks from a real spent charge")
		FacilitySpec.Role.DISPATCH_RELAY:
			_advance(battle, unit.next_utility_tick - 1)
			state.deploy(GUARD, Vector2i(2, 1), 1)
			var before := state.cooldown_ticks(GUARD.id)
			var dispatch_before := state.cooldown_ticks(id)
			_advance(battle, 1)
			var reduced := 1 + CombatClock.ticks_for(effect)
			_check(state.cooldown_ticks(GUARD.id) == before - reduced
				and state.cooldown_ticks(id) == dispatch_before - reduced,
				tag + " cuts existing modified Ranger and Facility deployment cooldowns")
		FacilitySpec.Role.SONIC_TURRET:
			var ground := _enemy(battle, Vector2i(1, 1))
			var air := _enemy(battle, Vector2i(2, 1))
			air.definition.aerial = true
			_advance(battle, expected_build)
			_check(ground.hp == 500 - int(effect) and air.hp == 500 and ground.sonic_speed_scale == 0.65
				and ground.sonic_slow_until == expected_build + 90,
				tag + " hits ground HP, retains slow and excludes aerial targets")
		FacilitySpec.Role.ELECTRIC_TURRET:
			var ground := _enemy(battle, Vector2i(1, 1))
			var tech := _enemy(battle, Vector2i(2, 1))
			tech.definition.technological = true
			_advance(battle, expected_build)
			_check(ground.hp == 500 - int(effect), tag + " uses scaled basic damage on the first burst hit")
			ground.distance = 1.0 # Leave the fixture range so the remaining hits retarget.
			_advance(battle, CombatClock.ticks_for(spec.burst_step_seconds) * 2)
			_check(tech.hp == 500 - 2 * roundi(effect * 1.3) and unit.burst_remaining == 0,
				tag + " preserves burst length, basic damage and Technological bonus")
		FacilitySpec.Role.CANOPY_LAUNCHER:
			var air := _enemy(battle, Vector2i(1, 1))
			air.definition.aerial = true
			var ground := _enemy(battle, Vector2i(2, 1))
			var outside_splash := _enemy(battle, Vector2i(4, 1))
			_advance(battle, expected_build)
			_check(air.hp == 500 - int(effect) and ground.hp == 500 - roundi(effect * 0.5) and outside_splash.hp == 500,
				tag + " applies aerial priority, splash and original ground multiplier")
		FacilitySpec.Role.SENTRY_TOWER:
			var near := _enemy(battle, anchor + Vector2i.RIGHT * int(effect))
			var far := _enemy(battle, anchor + Vector2i.RIGHT * (int(effect) + 1))
			near.definition.concealed = true
			far.definition.concealed = true
			_advance(battle, expected_build - 1)
			_check(not near.tower_detected and not far.tower_detected, tag + " has no detection during construction")
			_advance(battle, 1)
			_check(near.tower_detected and not far.tower_detected and state.deploy(SCOUT, anchor, 1).is_empty()
				and state.placed[SCOUT.id].mount_tower == id
				and state.can_attack(state.placed[SCOUT.id], anchor + Vector2i.RIGHT * (SCOUT.attack_range + 1), false),
				tag + " reveals its scaled radius and preserves mounted Ranger range")
		FacilitySpec.Role.FIREBREAK:
			var heat_source := _enemy(battle, Vector2i(1, 1))
			heat_source.definition.heat_per_second = 10.0
			_advance(battle, expected_build - 1)
			var before := battle.heat
			battle.clock.set_speed(2)
			_advance(battle, 30)
			_check(is_equal_approx(battle.heat - before, 10.0 * 0.75 * (1.0 - effect / 100.0)),
				tag + " mitigates actual Heat with B02 at 2×")
		FacilitySpec.Role.SPECIALIST_CALLTOWER:
			_advance(battle, unit.next_utility_tick)
			_check(battle.tap_unit(id) and state.specialist_discount == int(effect) and unit.stock == 0
				and state.cost_for(GUARD) == GUARD.cost, tag + " claims scaled stock for Specialists only")
			var before := state.tokens
			_check(state.deploy(SPECIALIST, Vector2i(2, 1), 1).is_empty()
				and state.tokens == before - maxi(0, SPECIALIST.cost - int(effect)) and state.specialist_discount == 0,
				tag + " consumes the discount on a legal deployment")
		FacilitySpec.Role.COORDINATION_HUB:
			state.deploy(SCOUT, Vector2i(1, 2), 1)
			var target := _enemy(battle, Vector2i(1, 1))
			_advance(battle, expected_build)
			var interval := ceili(120 / (1.12 * (1.0 + effect / 100.0)))
			var before := target.hp
			_advance(battle, state.placed[SCOUT.id].next_attack_tick - battle.clock.tick)
			_check(state.placed[SCOUT.id].basic_interval_ticks == interval and target.hp == before - SCOUT.attack_damage,
				tag + " changes actual Ranger attack cadence with B06")
		FacilitySpec.Role.REINFORCED_COVER, FacilitySpec.Role.DISRUPTION:
			state.deploy(GUARD, Vector2i(2, 1), -1)
			_advance(battle, expected_build)
			var enemy := _gunner(battle)
			_advance(battle, 1)
			_check(state.placed[GUARD.id].hp == GUARD.max_hp - roundi(100.0 - effect),
				tag + " reduces the actual enemy attack")
			if spec.role == FacilitySpec.Role.DISRUPTION:
				_check(battle.facility_combat.ability_delay(state, enemy.grid_cell(), battle.clock.tick) == 60,
					tag + " keeps the authored one-second ability delay")

func _post(battle: BattleSimulation, base_yield: float, tag: String) -> void:
	var state := battle.deployment
	var initial := state.tokens
	_advance(battle, LogisticsRules.PAYOUT_TICKS - 1)
	_check(state.tokens == initial, tag + " waits for the full ten-second payout interval")
	_advance(battle, 1)
	var first_pay := state.tokens - initial
	_advance(battle, 2 * LogisticsRules.PAYOUT_TICKS)
	var total_pay := state.tokens - initial
	_check(first_pay == floori(base_yield * 1.2 + 0.000001)
		and total_pay == floori(base_yield * 3.6 + 0.000001)
		and state.placed[&"facility.logistics_post#1"].yield_remainder
			== roundi(fposmod(base_yield * 3.6 + 0.000001, 1.0) * LogisticsRules.YIELD_DENOMINATOR),
		tag + " free Post pays the exact carry curve across three cycles with B15")

func _post_average(level: int) -> float:
	return LogisticsRules.new().post_yield_numerator(level) / float(LogisticsRules.YIELD_DENOMINATOR)

func _test_stacking() -> void:
	var battle := _encounter([&"B11"])
	var state := battle.deployment
	var cover := DeployableLevels.effective(DeployableLevels.definition(&"facility.reinforced_cover_station"), 100)
	var disrupt := DeployableLevels.effective(DeployableLevels.definition(&"facility.disruption_beacon"), 100)
	state.deploy(cover, BAY, 1)
	state.deploy(disrupt, Vector2i(1, 2), 1)
	var patrol := DeployableLevels.definition(&"ranger.patrolman")
	state.deploy(patrol, Vector2i(2, 1), -1)
	_advance(battle, 420)
	var enemy := _gunner(battle)
	enemy.route.cells = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(7, 1)]
	enemy.distance = 0.49
	enemy.definition.tiles_per_second = 1.0
	_advance(battle, 1)
	_check(state.placed[patrol.id].blocking_count == 1 and state.placed[patrol.id].hp == patrol.max_hp - 47,
		"Cover × Disruption × B11 apply once to a blocked attack (100 × .70 × .76 × .88 = 47)")
	battle = _encounter([&"B02"])
	state = battle.deployment
	var beacon := DeployableLevels.definition(FIREBREAK)
	state.deploy(beacon, BAY, 1)
	_advance(battle, CombatClock.ticks_for(beacon.build_cooldown_seconds))
	state.deploy(DeployableLevels.effective(beacon, 100), Vector2i(5, 0), 1)
	_advance(battle, CombatClock.ticks_for(beacon.build_seconds))
	var source := _enemy(battle, Vector2i(1, 1))
	source.definition.heat_per_second = 10.0
	_advance(battle, 60)
	_check(is_equal_approx(battle.heat, 3.9), "Two built Firebreaks use only the strongest reduction, then B02")

func _test_progression() -> void:
	var fixture := CampaignSave.fresh()
	fixture.leader_name = "Growth QA"
	fixture.funds = 1_200_000
	fixture.owned.append(String(SONIC))
	ProfileFile.replace(_path, fixture, false)
	var progress := CampaignProgress.new(_path)
	_check(not progress.level_quote(SONIC, 100).error.is_empty()
		and not progress.level_quote(FIREBREAK, 100).error.is_empty(),
		"Purchases require Mechanical and ownership")
	_check(progress.purchase_room(HeadquartersCatalog.MECHANICAL).is_empty(), "Mechanical builds at its existing price")
	var cost := progress.level_quote(SONIC, 100)
	_check(cost.cost == 1_000_000 and cost.balance == 180_000 and progress.purchase_levels(SONIC, 100).is_empty(),
		"Permanent upgrade charges the existing exact 1M and quote balance")
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	progress = app._campaign_progress
	_check(progress.funds() == 180_000 and progress.deployable_level(SONIC) == 100,
		"The launcher cold-loads the paid Facility level and wallet")
	var story := OperationPlan.new(CampaignContent.new().operation(&"C1-02"), [])
	story.configure_campaign(progress, [SCOUT.id, POST, SONIC])
	_check(_check_plan(story, 100), "Story planner and live deployment use the purchased Sonic")
	var chaos_setup := ChaosConfiguration.new()
	chaos_setup.select_route(&"T01")
	chaos_setup.set_quantity(0, chaos_setup.enemies()[0].enemy_id, 5)
	var chaos: OperationPlan = app._new_chaos_plan(chaos_setup.build_stage(), "Growth QA", [SCOUT.id, POST, SONIC])
	var leveled_score := ChaosScore.new(chaos.resolved())
	_check(_check_plan(chaos, 100), "Chaos launcher and live deployment use the purchased Sonic")
	fixture = progress.snapshot()
	fixture.deployable_levels.erase(String(SONIC))
	ProfileFile.replace(_path, fixture, false)
	chaos.configure_campaign(CampaignProgress.new(_path), chaos.selected_ids.duplicate())
	var base_score := ChaosScore.new(chaos.resolved())
	_check(_check_plan(chaos, 1) and base_score.points() == leveled_score.points()
		and base_score.configured_enemies == leveled_score.configured_enemies,
		"Chaos keeps the same eligibility and score without purchased levels")
	var heat_op := CampaignContent.new().operation(&"C2-07")
	var heat_story := OperationPlan.new(heat_op, [])
	heat_story.configure_campaign(progress, [SCOUT.id, POST])
	var supply := _entry(heat_story, FIREBREAK)
	_check(supply != null and supply.level == 1 and supply.max_hp == 220 and supply.heat_slow_percent == 40
		and not progress.owns(FIREBREAK) and FIREBREAK not in heat_story.selected_ids,
		"C2-07 supplies a separate unowned Level 1 Firebreak")
	fixture.owned.append(String(FIREBREAK))
	fixture.deployable_levels[String(FIREBREAK)] = 100
	ProfileFile.replace(_path, fixture, false)
	heat_story.configure_campaign(CampaignProgress.new(_path), [SCOUT.id, POST, FIREBREAK])
	supply = _entry(heat_story, FIREBREAK)
	_check(supply != null and supply.level == 1 and supply.heat_slow_percent == 40 and FIREBREAK not in heat_story.selected_ids,
		"C2-07 stage supply remains Level 1 even if a returning profile owns a maxed copy")
	app.free()

func _check_plan(plan: OperationPlan, level: int) -> bool:
	if not plan.can_start():
		return false
	var spec := _entry(plan, SONIC)
	var setup := plan.resolved()
	var state := DeploymentState.new(setup.stage.map, CombatClock.new(), setup.tokens, setup.opening)
	var post := _entry(plan, POST)
	if spec == null or post == null or not state.deploy(post, BAY, 1).is_empty():
		return false
	for frame in 4 * LogisticsRules.PAYOUT_TICKS:
		state.clock.advance_frame()
	return spec.level == level and state.deploy(spec, Vector2i(5, 0), 1).is_empty() and state.placed[SONIC].hp == (313 if level == 100 else 250)

func _entry(plan: OperationPlan, id: StringName) -> FacilitySpec:
	for spec: DeploymentSpec in plan.deployment_entries():
		if spec.id == id:
			return spec as FacilitySpec
	return null

func _encounter(ids: Array[StringName]) -> BattleSimulation:
	var stage := BattleStage.new()
	stage.map = MAP
	stage.opening_delay_seconds = 120.0
	stage.heat_capacity = 1000.0
	var wave := BattleWave.new()
	var group := BattleSpawnGroup.new()
	group.count = 1
	wave.groups.append(group)
	stage.waves.append(wave)
	var modifiers := BattleModifiers.new(ids)
	stage.heat_gain_scale = modifiers.scale(&"heat_gain_percent")
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(stage.map, battle.clock, 300, modifiers.logistics(LogisticsRules.new()), [], modifiers)
	return battle

func _enemy(battle: BattleSimulation, cell: Vector2i) -> BattleEnemy:
	var definition := BattleEnemyDefinition.new()
	definition.max_hp = 500
	definition.tiles_per_second = 0.0
	var route := BattleRoute.new()
	route.cells = [cell, cell + Vector2i.RIGHT * 5, cell + Vector2i.RIGHT * 6]
	var enemy := BattleEnemy.new(definition, route)
	battle.active[battle.active.size()] = enemy
	return enemy

func _gunner(battle: BattleSimulation) -> BattleEnemy:
	var enemy := _enemy(battle, Vector2i(1, 1))
	enemy.definition.attack_damage = 100
	enemy.definition.attack_profile = EnemyAttackProfile.new()
	enemy.definition.attack_profile.kind = EnemyAttackProfile.Kind.RANGED
	return enemy

func _advance(battle: BattleSimulation, frames: int) -> void:
	for frame in frames:
		battle.clock.advance_frame()

func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		printerr("FAIL ", description)
		_failed += 1
