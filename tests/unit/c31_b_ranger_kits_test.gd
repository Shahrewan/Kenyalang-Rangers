extends SceneTree

const T01 := preload("res://data/stages/c05_first_contact.tres")
const E01 := preload("res://data/enemies/e01_forest_trespasser.tres")
const K9 := &"ranger.k9_ranger"
const SEER := &"ranger.kenyalang_seer"
const TRACKER := &"ranger.woods_tracker"
const SABOTEUR := &"ranger.saboteurist"
const STRIKE := &"ranger.strike_team"
const IDS := [TRACKER, K9, SEER, SABOTEUR, STRIKE]

var _checks := 0
var _failures := 0
var _save := "user://c31b-rangers-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_k9()
	_seer()
	_tracker()
	_saboteur()
	_strike()
	await _ownership()
	print("C31-B Ranger field kits: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _battle(modifiers: Array[StringName] = []) -> BattleSimulation:
	var stage := T01.duplicate() as BattleStage
	stage.opening_delay_seconds = 600
	var sim := BattleSimulation.new(BattleModifiers.new(modifiers).stage(stage))
	sim.deployment = DeploymentState.new(stage.map, sim.clock, 500, null, [], sim.effects)
	return sim

func _enemy(sim: BattleSimulation, id: int, cell: Vector2i, danger := 1, tech := false, aerial := false, concealed := false) -> BattleEnemy:
	var spec := E01.duplicate() as BattleEnemyDefinition
	spec.tiles_per_second = 0.0
	spec.max_hp = 400
	spec.danger = danger
	spec.technological = tech
	spec.aerial = aerial
	spec.concealed = concealed
	var enemy := BattleEnemy.new(spec, T01.routes[0])
	enemy.distance = enemy.route.cells.find(cell)
	sim.active[id] = enemy
	return enemy

func _step(sim: BattleSimulation, frames: int) -> void:
	for _frame in frames:
		sim.clock.advance_frame()

func _k9() -> void:
	var sim := _battle()
	var state := sim.deployment
	var spec := DeployableLevels.definition(K9)
	_check(not state.deploy(spec, Vector2i(5, 2), -1).is_empty(), "K9 uses ground placement despite having ranged coverage")
	_check(state.deploy(spec, Vector2i(5, 3), -1).is_empty() and state.placed[K9].spec.block_capacity == 1,
		"K9 occupies one ground tile and can block one")
	_check(state.occupancy.size() == 1 and not state.can_attack(state.placed[K9], Vector2i(6, 3), true),
		"The dog reserves no cell and the rifle excludes aerial targets")
	var ground := _enemy(sim, 1, Vector2i(6, 3))
	var hidden := _enemy(sim, 2, Vector2i(4, 3), 2, false, false, true)
	var far := _enemy(sim, 3, Vector2i(8, 3), 1, false, false, true)
	_step(sim, 1)
	_check(ground.hp == 388 and hidden.hp == 400, "Tranquilizer hits a visible target behind the initial facing for 12 HP")
	_check(sim.tap_unit(K9) and hidden.is_targetable(sim.clock.tick) and hidden.hp == 400 and ground.hp == 388,
		"Howl reveals concealment and deals zero damage to every enemy")
	_check(not far.is_targetable(sim.clock.tick) and sim.ranger_combat.movement_scale(hidden, sim.clock.tick) == 0.5,
		"Howl slows enemies in its area and leaves out-of-range enemies alone")
	var skill := BattleSkillStatus.read(state.placed[K9], state)
	sim.clock.paused = true
	_step(sim, 12)
	_check(BattleSkillStatus.read(state.placed[K9], state).remaining_ticks == skill.remaining_ticks, "Howl orb is paused")
	sim.clock.paused = false
	sim.clock.set_speed(2)
	_step(sim, 120)
	_check(not hidden.is_targetable(sim.clock.tick) and sim.ranger_combat.movement_scale(hidden, sim.clock.tick) == 1.0,
		"Reveal and slow expire after four combat seconds at 2×")
	var disabled := _battle([&"B15"])
	disabled.deployment.deploy(spec, Vector2i(5, 3), -1)
	_check(BattleSkillStatus.read(disabled.deployment.placed[K9], disabled.deployment).mode == BattleSkillStatus.Mode.LOCKED
		and not disabled.tap_unit(K9), "Silent Mobilization locks the actual orb and active skill")

func _seer() -> void:
	var sim := _battle()
	var state := sim.deployment
	var spec := DeployableLevels.definition(SEER)
	_check(not state.deploy(spec, Vector2i(4, 2), 1).is_empty() and state.deploy(spec, Vector2i(6, 2), 1).is_empty(),
		"Seer needs elevated ground")
	var trailing := _enemy(sim, 1, Vector2i(4, 3))
	var airborne := _enemy(sim, 2, Vector2i(5, 3), 2, false, true)
	var primary := _enemy(sim, 3, Vector2i(6, 3))
	var hidden := _enemy(sim, 4, Vector2i(8, 3), 5, false, true, true)
	_step(sim, 1)
	_check([trailing.hp, airborne.hp, primary.hp, hidden.hp] == [387, 387, 387, 400],
		"Boomerang strikes ground and aerial, bouncing to two distinct neighbors")
	_check(sim.tap_unit(SEER) and hidden.is_targetable(sim.clock.tick) and hidden.hp == 400
		and hidden.damage_mark_bonus(sim.clock.tick) == 2 and primary.damage_mark_bonus(sim.clock.tick) == 0,
		"Scan reveals and marks the highest Danger with zero HP damage")
	# Call the real resolution repeatedly to isolate cap arithmetic from individual recharge.
	for i in 11:
		sim.ranger_combat.use_skill(state.placed[SEER], Vector2i.ZERO, state, 0)
	_check(hidden.damage_mark_bonus(sim.clock.tick) == 20, "Eleven additional Scans still cap at ten +2% marks")
	sim.damage_enemy(4, 50)
	_check(hidden.hp == 340, "Seer marks modify actual incoming HP damage")
	_check(hidden.damage_mark_bonus(sim.clock.tick + 1200) == 0, "Scan marks expire on combat ticks")

func _tracker() -> void:
	var sim := _battle()
	var state := sim.deployment
	var spec := DeployableLevels.definition(TRACKER)
	var scout := DeployableLevels.definition(&"ranger.scout_sniper")
	state.deploy(scout, Vector2i(1, 0), 1)
	var main := _enemy(sim, 1, Vector2i(6, 3), 4)
	var near := _enemy(sim, 2, Vector2i(5, 3))
	var far := _enemy(sim, 3, Vector2i(8, 3), 3)
	_check(state.deploy(spec, Vector2i(4, 3), -1).is_empty() and main.hp == 378 and near.hp == 400 and far.hp == 400,
		"Tracker deals 22 HP only to the highest Danger net center")
	_check(main.immobilized_until == 120 and near.immobilized_until == 120 and far.immobilized_until == 0,
		"Net immobilizes the center and nearby ground targets")
	var tokens := state.tokens
	_check(state.retreat(TRACKER) and state.tokens == tokens + spec.cost / 2 and main.hp == 378
		and state.cooldown_ticks(scout.id) == 1200 and state.cooldown_ticks(TRACKER) == 480,
		"Qualified retreat refunds paid Tokens, reduces every deployed type timer and deals zero damage")
	var unqualified := _battle()
	var empty := unqualified.deployment
	empty.deploy(spec, Vector2i(4, 3), 1)
	tokens = empty.tokens
	_check(empty.retreat(TRACKER) and empty.tokens == tokens and empty.cooldown_ticks(TRACKER) == 720,
		"Retreat before landing any net grants no refund or cooldown reduction")
	var enhanced := DeployableLevels.with_records_stats(spec, [&"records_chapter.woods_tracker"])
	_check(enhanced.max_hp > spec.max_hp and enhanced.redeploy_seconds < spec.redeploy_seconds,
		"The existing Records chapter improves Tracker HP and own redeployment")

func _saboteur() -> void:
	var sim := _battle()
	var state := sim.deployment
	var spec := DeployableLevels.definition(SABOTEUR)
	var tech := _enemy(sim, 1, Vector2i(5, 3), 2, true)
	var ordinary := _enemy(sim, 2, Vector2i(5, 3), 5)
	var at_edge := _enemy(sim, 3, Vector2i(7, 3), 4, true)
	_check(state.deploy(spec, Vector2i(6, 3), -1).is_empty(), "Saboteurist deploys as a ground Specialist")
	_check(tech.tech_interference_until == 120 and ordinary.tech_interference_until == 0,
		"Initial pulse disrupts technology without suppressing ordinary enemies")
	_step(sim, 1)
	_check(tech.hp == 382 and ordinary.hp == 400, "Basic attack deals 18 HP and ignores even higher-Danger organic foes")
	var outside := _enemy(sim, 4, Vector2i(8, 3), 4, true)
	_step(sim, 118)
	_check(outside.tech_interference_until == 0, "Pulse does not grow early")
	_step(sim, 1)
	_check(outside.tech_interference_until == 240 and sim.ranger_combat.movement_scale(outside, sim.clock.tick) == 1.0,
		"Pulse grows at two seconds and does not freeze movement")
	var tokens := state.tokens
	_check(state.retreat(SABOTEUR) and state.tokens == tokens + spec.cost / 2 and tech.hp == 362 and ordinary.hp == 380 and at_edge.hp == 380,
		"Retreat refunds half the paid cost and deals 20 nearby AoE to both enemy kinds")
	_check(tech.stunned_until == 240 and at_edge.stunned_until == 240 and ordinary.stunned_until == 0 and outside.hp == 400,
		"Retreat freezes only nearby technological foes for two seconds")

func _strike() -> void:
	var sim := _battle()
	var state := sim.deployment
	var spec := DeployableLevels.definition(STRIKE)
	var anchor := Vector2i(8, 3)
	var low := _enemy(sim, 1, Vector2i(4, 3))
	var highest := _enemy(sim, 2, Vector2i(5, 3), 5)
	var second := _enemy(sim, 3, Vector2i(6, 3), 3)
	var aerial := _enemy(sim, 4, Vector2i(7, 3), 5, false, true)
	_check(not state.deploy(spec, Vector2i(10, 3), -1).is_empty() and state.tokens == 500 and state.occupancy.is_empty(),
		"Invalid pair spends no Tokens and reserves neither cell")
	_check(state.deploy(spec, anchor, -1).is_empty() and state.interaction_id(anchor + Vector2i.RIGHT) == STRIKE
		and state.tokens == 500 - spec.cost, "Strike reserves two ground cells and pays once")
	_check(not state.receive_hit(STRIKE, 5, EnemyAttackProfile.Kind.RANGED), "An incoming strike has no on-field HP target")
	_step(sim, 119)
	sim.clock.dialogue_open = true
	_step(sim, 10)
	_check(highest.hp == 400 and state.placed[STRIKE].arrival_tick == 120, "Delayed strike waits through a full-screen dialogue")
	sim.clock.dialogue_open = false
	_step(sim, 1)
	_check(highest.hp == 320 and second.hp == 400 and aerial.hp == 400, "First arrival hits the highest eligible Danger once for 80")
	_check(state.retreat(STRIKE) and state.cost_for(spec) == spec.cost + 4 and state.occupancy.is_empty(), "Manual retreat frees both cells and escalates the next cost")
	_step(sim, state.cooldown_ticks(STRIKE))
	state.deploy(spec, anchor, -1)
	var copy := state.interaction_id(anchor)
	_step(sim, 120)
	_check(highest.hp == 200 and second.hp == 280 and low.hp == 400 and state.placed[copy].arrival_rank == 1,
		"Second arrival strikes two distinct targets for 120 each")
	state.retreat(copy)
	_step(sim, state.cooldown_ticks(STRIKE))
	state.deploy(spec, anchor, -1)
	copy = state.interaction_id(anchor)
	_step(sim, 120)
	_check(highest.hp == 40 and second.hp == 120 and low.hp == 240 and aerial.hp == 400,
		"Third arrival uses 160 HP on three distinct ground targets")
	state.retreat(copy)
	_check(state.cost_for(spec) == spec.cost + 8, "Additional retreats cap the escalation")
	var fresh := _battle()
	fresh.deployment.deploy(spec, anchor, -1)
	fresh.deployment.retreat(STRIKE)
	_check(fresh.deployment.cost_for(spec) == spec.cost + 4, "Voluntary withdrawal while inbound counts toward the next drop")
	var defeated := _battle()
	defeated.deployment.deploy(spec, anchor, -1)
	_step(defeated, 120)
	defeated.deployment.receive_hit(STRIKE, 1000, EnemyAttackProfile.Kind.RANGED)
	_check(defeated.deployment.cost_for(spec) == spec.cost and defeated.deployment.occupancy.is_empty(),
		"Defeat releases both cells without awarding an escalation")
	var strained := _battle([&"D12"])
	var price := strained.effects.deployable(spec)
	strained.deployment.deploy(price, anchor, -1)
	strained.deployment.retreat(STRIKE)
	_check(strained.deployment.cost_for(price) == 22, "Strained Logistics rounds the whole escalated cost up once")
	_check(strained.deployment.claim_specialist_discount(3) and strained.deployment.cost_for(price) == 19,
		"The existing Calltower discount applies after escalation and D12")
	var calibrated := BattleModifiers.new([&"B05"]).deployable(spec) as RangerSpec
	_check(calibrated.field_damage == 88 and calibrated.arrival_damage_step == 44,
		"The existing Ranger damage buff applies to Strike arrival at every rank")

func _ownership() -> void:
	var content := CampaignContent.new()
	var profile := CampaignSave.fresh()
	profile.leader_name = "Kits QA"
	profile.rooms["room.human_resources"] = 5
	profile.rooms["room.mechanical"] = 3
	var unlocks := [&"C1-04", &"C2-01", &"C2-03", &"C2-05", &"C2-06"]
	for i in IDS.size():
		var id: StringName = IDS[i]
		var unlock := content.operation(unlocks[i])
		_check(id in unlock.clear_unlock_ids and (DeployableLevels.definition(id) as RangerSpec).recruitment_stage == unlocks[i],
			String(id) + " keeps its authored recruitment clear")
	ProfileFile.replace(_save, profile, false)
	var old := CampaignProgress.new(_save)
	var op := content.operation(&"C2-07")
	var plan := OperationPlan.new(op, [])
	plan.configure_campaign(old, [])
	_check(plan.choices.all(func(spec: DeploymentSpec) -> bool: return spec.id not in IDS),
		"Returning profiles cannot equip unowned Rangers")
	for id in IDS:
		profile.owned.append(String(id))
		profile.deployable_levels[String(id)] = 7
	ProfileFile.replace(_save, profile, false)
	if "facility.logistics_post" not in profile.owned:
		profile.owned.append("facility.logistics_post")
		ProfileFile.replace(_save, profile, false)
	var returning := CampaignProgress.new(_save)
	plan.configure_campaign(returning, IDS + [&"facility.logistics_post"])
	_check(plan.selected_count(true) == IDS.size()
		and plan.deployment_entries().filter(func(spec: DeploymentSpec) -> bool: return spec.id in IDS and spec.level == 7).size() == IDS.size(),
		"Story uses recruited IDs and reloads their saved upgrade levels")
	var app := preload("res://scenes/menus/launcher.tscn").instantiate()
	app.campaign_save_path = _save
	root.add_child(app)
	await process_frame
	var configuration := ChaosConfiguration.new()
	configuration.route_id = &"T02"
	configuration.set_quantity(0, &"E01", 2)
	var chaos: OperationPlan = app._new_chaos_plan(configuration.build_stage(), "Kits QA", IDS + [&"facility.logistics_post"])
	_check(chaos.can_start() and chaos.selected_count(true) == IDS.size() and chaos.deployment_entries().size() == IDS.size() + 1,
		"Rainforest Chaos uses the same ownership and loadout rules")
	app.free()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(_save + suffix)

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", label)
