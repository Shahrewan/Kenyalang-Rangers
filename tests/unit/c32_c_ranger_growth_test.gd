extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const MAP: BattleMap = preload("res://data/stages/t01_forgotten_patrol.tres")
const LEVELS := [1, 20, 40, 60, 80, 100]
const OUTPUTS := [&"max_hp", &"attack_damage", &"heal_hp", &"repair_hp", &"field_damage", &"arrival_damage_step"]
const SKILL_OUTPUTS := [&"damage", &"healing"]
# HP, basic attack, auto-heal, repair, field damage, arrival step, skill damage, skill healing.
const ENDPOINTS := {
	"scout_sniper": [[100, 24, 0, 0, 0, 0, 24, 0], [125, 29, 0, 0, 0, 0, 29, 0]],
	"crowd_controller": [[120, 30, 0, 0, 0, 0, 50, 0], [150, 36, 0, 0, 0, 0, 60, 0]],
	"guard_veteran": [[230, 32, 0, 0, 0, 0, 46, 0], [288, 38, 0, 0, 0, 0, 55, 0]],
	"patrolman": [[320, 12, 0, 0, 0, 0, 0, 0], [400, 14, 0, 0, 0, 0, 0, 0]],
	"barricade_ops": [[520, 8, 0, 0, 0, 0, 0, 0], [650, 10, 0, 0, 0, 0, 0, 0]],
	"k9_ranger": [[230, 12, 0, 0, 0, 0, 0, 0], [288, 14, 0, 0, 0, 0, 0, 0]],
	"combat_medic": [[110, 0, 24, 0, 0, 0, 0, 65], [138, 0, 29, 0, 0, 0, 0, 78]],
	"kenyalang_seer": [[120, 13, 0, 0, 0, 0, 0, 0], [150, 16, 0, 0, 0, 0, 0, 0]],
	"outpost_mechanic": [[140, 10, 0, 20, 0, 0, 0, 0], [175, 12, 0, 24, 0, 0, 0, 0]],
	"woods_tracker": [[100, 22, 0, 0, 22, 0, 0, 0], [125, 26, 0, 0, 26, 0, 0, 0]],
	"saboteurist": [[130, 18, 0, 0, 20, 0, 0, 0], [163, 22, 0, 0, 24, 0, 0, 0]],
	"strike_team": [[100, 18, 0, 0, 80, 40, 0, 0], [125, 22, 0, 0, 96, 48, 0, 0]],
}
const SCOUT := &"ranger.scout_sniper"
const PATROL := &"ranger.patrolman"
const POST := &"facility.logistics_post"
const TRACKER := &"ranger.woods_tracker"
const MEDIC := &"ranger.combat_medic"
const GROUND := Vector2i(2, 1)
const ELEVATED := Vector2i(1, 0)

var _checks := 0
var _failures := 0
var _path := "user://c32-c-growth-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var units := DeployableLevels.catalog(true)
	_check(units.size() == ENDPOINTS.size(), "The roster has all 12 Ranger definitions")
	for base: RangerSpec in units:
		_test_levels(base)
	_test_progression()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".settings"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C32-C Ranger growth: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_levels(base: RangerSpec) -> void:
	var name := String(base.id).get_slice(".", 1)
	var row: Array = ENDPOINTS[name]
	var previous: Array = row[0]
	for level: int in LEVELS:
		var tag := "%s Lv.%d" % [base.label, level]
		var spec := DeployableLevels.effective(base, level) as RangerSpec
		var expected: Array[int] = []
		var actual := _outputs(spec)
		for i in actual.size():
			expected.append(roundi(lerpf(row[0][i], row[1][i], (level - 1) / 99.0)))
		_check(spec != base and spec.level == level and actual == expected and _nondecreasing(actual, previous),
			tag + " interpolates every raw output on an independent spec")
		_check(_same_configuration(spec, base, OUTPUTS + [&"level", &"active_skill"])
			and _same_configuration(spec.active_skill, base.active_skill, SKILL_OUTPUTS),
			tag + " retains role, eligibility, geometry, charges, timing and effects")
		_test_combat(spec, expected, tag)
		previous = actual
	_check(base.level == 1 and _outputs(base) == row[0], base.label + " catalog and skill remain at the authored baseline")

func _outputs(spec: RangerSpec) -> Array[int]:
	var result: Array[int] = []
	for property: StringName in OUTPUTS:
		result.append(spec.get(property))
	for property: StringName in SKILL_OUTPUTS:
		result.append(spec.active_skill.get(property) if spec.active_skill != null else 0)
	return result

func _nondecreasing(current: Array[int], previous: Array) -> bool:
	for i in current.size():
		if current[i] < previous[i]:
			return false
	return true

func _same_configuration(left: Resource, right: Resource, excluded: Array) -> bool:
	if left == null or right == null:
		return left == right
	for property in left.get_property_list():
		var key: StringName = property.name
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and key not in excluded and left.get(key) != right.get(key):
			return false
	return true

func _test_combat(spec: RangerSpec, expected: Array[int], tag: String) -> void:
	var enhancements: Array[StringName] = []
	if not spec.records_enhancement.is_empty():
		enhancements.append(spec.records_enhancement)
	var battle := _battle(enhancements)
	var state := battle.deployment
	var tuned := DeployableLevels.with_records_stats(spec, enhancements) as RangerSpec
	var anchor := GROUND if spec.uses_ground() else ELEVATED
	var direction := -1 if spec.id == PATROL else 1
	_check(state.deploy(tuned, anchor, direction).is_empty(), tag + " can deploy on its authored tile type")
	var unit := state.placed[spec.id]
	_check(unit.hp == expected[0] + spec.records_bonus_hp and unit.paid_cost == spec.cost
		and state.occupancy.size() == spec.footprint(anchor).size()
		and state.cooldown_ticks(spec.id) == CombatClock.ticks_for(spec.redeploy_seconds - spec.records_redeploy_reduction_seconds),
		tag + " starts with scaled HP and original placement price, footprint and Records rules")

	if spec.id == MEDIC:
		_medic(battle, spec, expected, tag)
		return
	if spec.id == &"ranger.strike_team":
		_strike(battle, unit, expected, tag)
		# A separate placement can exercise the normal two-tile melee attack.
		battle = _battle()
		state = battle.deployment
		state.deploy(spec, anchor, direction)
		unit = state.placed[spec.id]
		_advance(battle, 120)

	var target_cell := state.coverage(tuned, anchor, direction)[0] if spec.is_melee() else Vector2i(2, 1)
	var target := _enemy(battle, target_cell)
	target.definition.technological = spec.id in [&"ranger.crowd_controller", &"ranger.saboteurist"]
	target.definition.aerial = spec.id in [SCOUT, &"ranger.kenyalang_seer"]
	if spec.id == PATROL:
		target.route.cells = [Vector2i(1, 1), GROUND, Vector2i(7, 1)]
		target.distance = 0.49
		target.definition.tiles_per_second = 1.0
	_advance(battle, maxi(1, unit.next_attack_tick - battle.clock.tick))
	var ordinary := expected[1]
	if spec.id == PATROL:
		ordinary += 6
	elif spec.id == &"ranger.crowd_controller":
		ordinary = roundi(ordinary * 1.3)
	_check(target.hp == 500 - ordinary and unit.basic_interval_ticks == CombatClock.ticks_for(spec.attack_seconds),
		tag + " removes the expected HP at the original basic attack interval")
	match spec.id:
		SCOUT:
			_scout(battle, target, expected, tag)
		&"ranger.guard_veteran":
			var neighbor := _enemy(battle, Vector2i(4, 1))
			_check(unit.skill_charges == 4 and battle.tap_unit(spec.id) and unit.skill_charges == 3
				and neighbor.hp == 500 - expected[6] and target.hp == 500 - ordinary - expected[6]
				and target.stunned_until == battle.clock.tick + 60 and unit.skill_recharge_tick == battle.clock.tick + 780
				and unit.next_attack_tick == battle.clock.tick + 120,
				tag + " scales frontal skill damage and preserves stun, charges and cadence")
		&"ranger.crowd_controller":
			var neighbor := _enemy(battle, Vector2i(1, 1))
			_check(battle.tap_unit(spec.id) and neighbor.hp == 500 - expected[6]
				and target.hp == 500 - ordinary - expected[6] and battle.ranger_combat.movement_scale(target, battle.clock.tick) == 0.5,
				tag + " hits the EMP splash with scaled damage and unchanged slow")
		&"ranger.k9_ranger":
			var hidden := _enemy(battle, Vector2i(3, 1))
			hidden.definition.concealed = true
			_check(battle.tap_unit(spec.id) and hidden.is_targetable(battle.clock.tick)
				and hidden.hp == 500 and hidden.howl_slow_until == battle.clock.tick + 240
				and hidden.howl_speed_scale == 0.5 and unit.skill_recharge_tick == battle.clock.tick + 720,
				tag + " Howl still reveals and slows without direct damage")
		&"ranger.kenyalang_seer":
			_seer(battle, target, unit, expected[1], tag)
		&"ranger.outpost_mechanic":
			_mechanic(battle, expected[3], tag)
		TRACKER:
			_tracker(tuned, expected[4], tag)
		&"ranger.saboteurist":
			var neighbor := _enemy(battle, Vector2i(2, 2))
			_advance(battle, 119)
			var before := state.tokens
			_check(target.tech_interference_until > battle.clock.tick and state.retreat(spec.id)
				and target.hp == 500 - ordinary - expected[4] and neighbor.hp == 500 - expected[4]
				and target.stunned_until == battle.clock.tick + 120 and neighbor.stunned_until == 0
				and state.tokens == before + 6 and state.cooldown_ticks(spec.id) == 840,
				tag + " scales retreat damage while keeping interference, stun, refund and cooldown")

func _scout(battle: BattleSimulation, target: BattleEnemy, expected: Array[int], tag: String) -> void:
	var unit := battle.deployment.placed[SCOUT]
	var before := target.hp
	_check(battle.tap_unit(SCOUT) and battle.deployment.select_target(target.grid_cell())
		and target.hp == before and battle.confirm_skill_target() and target.hp == before - expected[6]
		and unit.skill_recharge_tick == battle.clock.tick + 720,
		tag + " confirms the scaled Focus skill after Records and retains the refill")
	_advance(battle, unit.next_attack_tick - battle.clock.tick)
	_check(target.hp == before - expected[6] - roundi(expected[1] * 1.25),
		tag + " keeps the separate Records marked-target bonus on scaled attack damage")
	var locked := _battle()
	locked.deployment.deploy(unit.spec, ELEVATED, 1)
	_check(not locked.tap_unit(SCOUT) and locked.deployment.placed[SCOUT].skill_charges == 0,
		tag + " paid levels alone leave Focus locked")

func _medic(battle: BattleSimulation, spec: RangerSpec, expected: Array[int], tag: String) -> void:
	var state := battle.deployment
	state.deploy(DeployableLevels.definition(PATROL), GROUND, 1)
	var ally := state.placed[PATROL]
	var enemy := _enemy(battle, Vector2i(1, 1))
	state.receive_hit(PATROL, 160, EnemyAttackProfile.Kind.RANGED)
	_advance(battle, 1)
	var before := ally.hp
	_check(before == ally.spec.max_hp - 160 + expected[2] and enemy.hp == 500
		and state.placed[spec.id].next_attack_tick == 133, tag + " heals on the ordinary cadence without attacking")
	ally.jammed_until = 200
	_check(battle.tap_unit(MEDIC) and state.select_target(GROUND) and ally.hp == before
		and battle.confirm_skill_target() and ally.hp == before + expected[7] and ally.jammed_until == 0
		and state.placed[MEDIC].skill_charges == 0 and state.placed[MEDIC].skill_recharge_tick == 0,
		tag + " confirmed Records treatment delivers scaled healing and keeps one-use cleanse")
	var locked := _battle()
	locked.deployment.deploy(spec, ELEVATED, 1)
	_check(not locked.tap_unit(MEDIC) and locked.deployment.placed[MEDIC].skill_charges == 0,
		tag + " purchase preserves the treatment gate")

func _seer(battle: BattleSimulation, target: BattleEnemy, unit: DeploymentState.Placement, damage: int, tag: String) -> void:
	var second := _enemy(battle, Vector2i(3, 1))
	var third := _enemy(battle, Vector2i(4, 1))
	var fourth := _enemy(battle, Vector2i(5, 1))
	second.definition.danger = 5
	second.definition.concealed = true
	_check(battle.tap_unit(unit.id) and second.is_targetable(battle.clock.tick)
		and second.damage_mark_bonus(battle.clock.tick) == 2 and second.hp == 500,
		tag + " Scan stays non-damaging and applies the original 2% mark")
	_advance(battle, unit.next_attack_tick - battle.clock.tick)
	_check(target.hp == 500 - damage * 2 and second.hp == 500 - roundi(damage * 1.02)
		and third.hp == 500 - damage and fourth.hp == 500,
		tag + " boomerang hits an aerial target and exactly two distinct targets with scaled damage")

func _mechanic(battle: BattleSimulation, repair: int, tag: String) -> void:
	var state := battle.deployment
	state.deploy(DeployableLevels.definition(POST), Vector2i(1, 2), 1)
	var id := state.interaction_id(Vector2i(1, 2))
	state.receive_hit(id, 50, EnemyAttackProfile.Kind.SIEGE)
	state.deploy(DeployableLevels.definition(PATROL), GROUND, 1)
	state.receive_hit(PATROL, 80, EnemyAttackProfile.Kind.RANGED)
	_advance(battle, 178)
	var damaged := state.placed[id].hp
	_check(damaged == 110, tag + " repair waits for its original three-second deadline")
	_advance(battle, 1)
	_check(state.placed[id].hp == damaged + repair and state.placed[PATROL].hp == 240,
		tag + " repairs actual Facility HP and leaves a wounded ordinary Ranger alone")

func _tracker(spec: RangerSpec, damage: int, tag: String) -> void:
	var battle := _battle([spec.records_enhancement])
	var state := battle.deployment
	var target := _enemy(battle, Vector2i(8, 3))
	target.definition.danger = 4
	var nearby := _enemy(battle, Vector2i(9, 3))
	var aerial := _enemy(battle, Vector2i(8, 3))
	aerial.definition.aerial = true
	aerial.definition.danger = 5
	_check(state.deploy(spec, GROUND, 1).is_empty() and target.hp == 500 - damage and target.immobilized_until == 120
		and nearby.hp == 500 and nearby.immobilized_until == 120 and aerial.hp == 500 and aerial.immobilized_until == 0,
		tag + " scaled net hits only the eligible center and retains the immobilization area")
	_check(state.retreat(spec.id) and state.tokens == 295 and state.cooldown_ticks(spec.id) == 360,
		tag + " landed net still refunds half the paid Tokens and reduces the Records-adjusted cooldown")

func _strike(battle: BattleSimulation, unit: DeploymentState.Placement, expected: Array[int], tag: String) -> void:
	var state := battle.deployment
	var spec := unit.ranger
	var targets: Array[BattleEnemy] = []
	for i in 3:
		var enemy := _enemy(battle, Vector2i(8 + i, 3))
		enemy.definition.danger = 4 - i
		targets.append(enemy)
	var aerial := _enemy(battle, Vector2i(8, 3))
	aerial.definition.aerial = true
	aerial.definition.danger = 5
	for rank in 3:
		var before: Array[int] = []
		for enemy: BattleEnemy in targets:
			before.append(enemy.hp)
		_advance(battle, 119)
		_check(unit.arrival_tick == battle.clock.tick + 1 and unit.paid_cost == 16 + 4 * rank and targets[0].hp == before[0],
			tag + " reserves two tiles and delays rank %d arrival at original cost" % rank)
		_advance(battle, 1)
		var accurate := true
		for index in 3:
			var damage := expected[4] + rank * expected[5] if index <= rank else 0
			accurate = accurate and targets[index].hp == before[index] - damage
		_check(accurate and unit.arrival_tick == 0 and aerial.hp == 500,
			tag + " scales rank %d damage on the correct number of ground targets" % rank)
		if rank < 2:
			state.retreat(unit.id)
			_advance(battle, state.cooldown_ticks(spec.id))
			state.deploy(spec, GROUND, 1)
			unit = state.placed[state.interaction_id(GROUND)]

func _test_progression() -> void:
	var content := CampaignContent.new()
	var operation := content.operation(&"C2-07")
	var fixture := CampaignSave.fresh()
	fixture.leader_name = "Ranger QA"
	fixture.funds = 3_000_000
	fixture.rooms[String(HeadquartersCatalog.CONTROL)] = operation.min_control_level
	fixture.rooms[String(HeadquartersCatalog.MECHANICAL)] = 1
	fixture.rooms[String(HeadquartersCatalog.RECORDS)] = 5
	fixture.encyclopaedia.perfect_chapters = ["records_chapter.woods_tracker", "records_chapter.scout_sniper",
		"records_chapter.patrolman", "records_chapter.combat_medic"]
	for prior: StoryOperation in content.operations:
		if prior == operation:
			break
		fixture.records[String(prior.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in prior.clear_unlock_ids:
			if String(id) not in fixture.owned:
				fixture.owned.append(String(id))
	_check(ProfileFile.replace(_path, fixture, false), "Save a funded fixture with the original recruit and Records gates")
	var progress := CampaignProgress.new(_path)
	for spec: RangerSpec in DeployableLevels.catalog(true):
		_check(progress.owns(spec.id) and progress.purchase_levels(spec.id, 40).is_empty(), spec.label + " buys Lv.40 after recruitment")
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	progress = app._campaign_progress
	_check(progress.funds() == 707_988 and progress.snapshot().deployable_levels.size() == 12,
		"All 12 purchases and exact remaining Funds cold-load")
	var story := OperationPlan.new(operation, [])
	var chaos_config := ChaosConfiguration.new()
	chaos_config.select_route(&"T01")
	chaos_config.set_quantity(0, &"E01", 5)
	for base: RangerSpec in DeployableLevels.catalog(true):
		var selection: Array[StringName] = [base.id, POST]
		story.configure_campaign(progress, selection)
		var chaos: OperationPlan = app._new_chaos_plan(chaos_config.build_stage(), "Ranger QA", selection)
		_check(_paid_drop(story, base) and _paid_drop(chaos, base),
			base.label + " saved level reaches actual Story and Chaos deployment")
	var tutorial := OperationPlan.new(content.operation(&"C1-01"), [])
	tutorial.configure_campaign(progress)
	_check(_entry(tutorial, SCOUT).level == 1 and _entry(tutorial, PATROL).level == 1,
		"Story tutorial still uses its authored Ranger supplies")
	app.free()

func _entry(plan: OperationPlan, id: StringName) -> DeploymentSpec:
	for spec: DeploymentSpec in plan.deployment_entries():
		if spec.id == id:
			return spec
	return null

func _paid_drop(plan: OperationPlan, base: RangerSpec) -> bool:
	var setup := plan.resolved()
	var spec := _entry(plan, base.id) as RangerSpec
	if not setup.can_start() or spec == null or spec.level != 40:
		return false
	var state := DeploymentState.new(setup.stage.map, CombatClock.new(), setup.tokens, setup.opening, plan._enhancements)
	var post := _entry(plan, POST)
	for cell: Vector2i in state.map.elevated:
		if state.deploy(post, cell, 1).is_empty():
			break
	for frame in 3 * LogisticsRules.PAYOUT_TICKS:
		state.clock.advance_frame()
	var cells := state.map.ground if spec.uses_ground() else state.map.elevated
	for cell: Vector2i in cells:
		if state.deploy(spec, cell, 1).is_empty():
			var permanent_hp := roundi(lerpf(base.max_hp, ENDPOINTS[String(base.id).get_slice(".", 1)][1][0], 39.0 / 99))
			return state.placed[spec.id].hp == permanent_hp + base.records_bonus_hp
	return false

func _battle(enhancements: Array[StringName] = []) -> BattleSimulation:
	var stage := BattleStage.new()
	stage.map = MAP
	stage.opening_delay_seconds = 300.0
	var wave := BattleWave.new()
	var group := BattleSpawnGroup.new()
	group.count = 1
	wave.groups.append(group)
	stage.waves.append(wave)
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(MAP, battle.clock, 300, null, enhancements)
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

func _advance(battle: BattleSimulation, frames: int) -> void:
	for frame in frames:
		battle.clock.advance_frame()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		printerr("FAIL ", message)
		_failures += 1
