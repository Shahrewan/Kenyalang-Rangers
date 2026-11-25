extends SceneTree

const WAVES := [
	[6, 8], [8, 10], [9, 11, 13], [10, 12, 14], [14, 18, 1],
	[16, 20, 24], [18, 22, 26], [20, 24, 28], [20, 25, 30], [22, 26, 30, 32],
	[24, 30, 35], [25, 30, 35, 38], [30, 33, 38, 1], [28, 32, 36, 42], [25, 30, 36, 45, 1],
]
const MAPS := ["T01", "T01", "T01", "T01", "T01", "T02", "T02", "T03", "T03", "T04", "T04", "T05", "T05", "T06", "T06"]
const TIERS := [1, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5]

var _checks := 0
var _failed := 0
var _path := "user://c14-resources-%d.json" % OS.get_process_id()

func _initialize() -> void:
	var content := CampaignContent.new()
	_check(content.error.is_empty() and content.operations.size() == WAVES.size(), "W13 imports all 15 operations")
	if content.operations.size() == WAVES.size():
		_manifest(content)
		_debuffs(content)
		_openings(content)
		_settlement(content)
		_medic(content)
	for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".legacy", ".legacy.bak", ".rewards", ".rewards.bak", ".rewards.tmp", ".rewards.bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Campaign resources: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _manifest(content: CampaignContent) -> void:
	var previous: StringName
	var maps := {}
	var debuffs := {}
	var dialogue_count := 0
	for i in content.operations.size():
		var operation := content.operations[i]
		var stage := operation.stage
		var id := stage.stage_id
		var counts: Array[int] = []
		for wave in stage.waves:
			var count := 0
			for group in wave.groups:
				count += group.count
			counts.append(count)
		_check(counts == WAVES[i] and operation.prerequisite == previous and operation.min_control_level == TIERS[i], "%s matches GDD counts, order and Control tier" % id)
		_check(stage.validation_error().is_empty() and String(stage.map.map_id) == MAPS[i] and stage.map.size == Vector2i(12, 5), "%s uses the valid W08 board" % id)
		if maps.has(stage.map.map_id):
			_check(maps[stage.map.map_id] == stage.map, "%s shares its region geometry resource" % id)
		else:
			maps[stage.map.map_id] = stage.map
		for modifier in operation.fixed_debuff_ids:
			debuffs[modifier] = true
		_check(operation.fixed_debuff_ids.size() == (1 if i < 5 else 2), "%s has the fixed Story slot count" % id)
		_check(["first_clear_funds", "first_perfect_funds", "replay_funds"].all(func(key: String) -> bool: return ProfileFile.whole_between(operation.rewards.get(key), 1, FundsWallet.CAP)), "%s only settles approved reward amounts" % id)
		_check(operation.dialogue.all(func(beat: Dictionary) -> bool: return beat.status == "approved_c26_placeholder")
			and operation.hints.all(func(hint: Dictionary) -> bool: return hint.status == "approved_c26_placeholder"), "%s uses the reviewed placeholder script" % id)
		dialogue_count += operation.dialogue.size()
		previous = id
	_check(maps.size() == 6 and debuffs.size() == 15 and dialogue_count == 73, "Six maps, fifteen fixed effects and 73 beats")
	var mulu := content.operation(&"C2-01").stage
	_check(mulu.routes[0].cells.front() == Vector2i(0, 1) and mulu.routes[1].cells.front() == Vector2i(0, 3) and mulu.routes[0].cells.slice(6) == mulu.routes[1].cells.slice(6), "Gunung Mulu uses Entry A and B and merges at (5,2)")
	_check(mulu.routes[0].cells[6] == Vector2i(5, 2) and mulu.routes[0].cells.back() == mulu.map.tunnel, "Both Gunung Mulu routes converge at the recorded merge and tunnel")

func _debuffs(content: CampaignContent) -> void:
	var early := content.operation(&"C1-01")
	var e01 := early.stage.waves[0].groups[0].enemy
	var pursuit := _enemy(content.operation(&"C1-02"), &"E01")
	var tough := BattleModifiers.new([&"D08"]).enemy(e01)
	_check(is_equal_approx(pursuit.tiles_per_second, e01.tiles_per_second * 1.10) and tough.max_hp == 115, "D02 speed and D08 HP derive from the base enemy")
	var scout := _unit(content, &"ranger.scout_sniper") as RangerSpec
	var modified := BattleModifiers.new([&"D03", &"D04", &"D12"]).deployable(scout) as RangerSpec
	_check(modified.max_hp == roundi(scout.max_hp * 0.85) and modified.cost == 14 and is_equal_approx(modified.active_skill.recharge_seconds, scout.active_skill.recharge_seconds * 1.2), "D03, D04 and D12 apply through the effective Ranger definition")
	_check(scout.cost == 12 and modified.active_skill != scout.active_skill, "Campaign effects preserve the base kit")
	var smoke := _enemy(content.operation(&"C2-01"), &"E06")
	var plain_smoke := _enemy(content.operation(&"C2-02"), &"E06")
	_check(smoke != null and plain_smoke != null and is_equal_approx(smoke.ability.duration_seconds, plain_smoke.ability.duration_seconds + 2.0), "D06 extends smoke by two combat seconds")
	var drone := _enemy(content.operation(&"C2-03"), &"E08")
	var base_drone := _enemy(content.operation(&"C2-04"), &"E08")
	_check(drone != null and base_drone != null and is_equal_approx(drone.tiles_per_second, base_drone.tiles_per_second * 1.25), "D11 affects aerial movement")
	_check(_effective_stage(content.operation(&"C2-03")).waves[0].rest_after_seconds == 12.0 and is_equal_approx(_effective_stage(content.operation(&"C2-04")).waves[0].groups[0].interval_seconds, 2.4), "D07 keeps the original rest reduction and D13 composes with the Chapter 2 pacing profile")
	var siege := _enemy(content.operation(&"C2-02"), &"E11")
	var normal_siege := CampaignContent.ENEMIES.entries.filter(func(entry: BattleEnemyDefinition) -> bool: return entry.enemy_id == &"E11")[0] as BattleEnemyDefinition
	_check(siege.is_siege_capable() and siege.attack_damage == roundi(normal_siege.attack_damage * 1.25), "D09 modifies only the Siege-capable definition")
	var cabin := _unit(content, &"facility.medic_cabin")
	var slow := BattleModifiers.new([&"D10"]).deployable(cabin)
	_check(is_equal_approx(slow.build_seconds, cabin.build_seconds * 1.25), "D10 modifies timed construction")
	var late := content.operation(&"C2-09")
	var ordinary := _effective_stage(late).waves[0].groups[0].enemy
	_check(ordinary.escape_penalty == 15 and _enemy(late, &"E15").escape_causes_defeat, "D15 rounds ordinary loss and preserves fatal E15")
	var key := &"C2-07"
	for operation in content.operations:
		var is_heat := operation.stage.stage_id in [key, &"C2-08"]
		var heat_scale := 1.3 if is_heat else 1.0
		if operation.stage.stage_id == &"C2-08":
			heat_scale = 1.3 * 0.32
		_check(operation.has_heat == is_heat and is_equal_approx(_effective_stage(operation).heat_gain_scale, heat_scale), "%s has correct D14 and Heat visibility" % operation.stage.stage_id)

func _openings(content: CampaignContent) -> void:
	var profile := CampaignProgress.new(_path)
	var first := content.operation(&"C1-01")
	var next := content.operation(&"C1-02")
	var plan := OperationPlan.new(first, [])
	plan.configure_campaign(profile)
	_check(plan.deployment_entries().size() == 3 and plan.can_start() and plan.selected_ids.is_empty(), "C1-01 supplies three cards outside regular slots")
	var rules := plan.resolved().opening
	var state := DeploymentState.new(first.stage.map, CombatClock.new(), 0, rules)
	var post := _unit(content, &"facility.logistics_post")
	_check(state.deploy(post, Vector2i(1, 0), 1).is_empty() and state.placed[&"facility.logistics_post#1"].build_deadline == 0, "Starter Post deploys free and instantly on a legal pair")
	for i in LogisticsRules.PAYOUT_TICKS:
		state.clock.advance_frame()
	_check(state.tokens == 9, "D01 generates nine Tokens after ten combat seconds")
	_check(not profile.begin_attempt(next), "Fresh profile cannot enter C1-02 ahead of C1-01")
	profile.begin_attempt(first)
	var first_clear := profile.complete(first, false)
	_check(first_clear.credited == 10000 and not first_clear.first_perfect, "A normal C1-01 clear earns 10,000 without a perfect")
	plan = OperationPlan.new(next, [])
	plan.configure_campaign(profile)
	_check(not plan.can_start() and plan.facility_limit == 0 and profile.funds() == 20000, "C1-02 requires Mechanical and the first clear funds its exact price")
	_check(profile.purchase_room(HeadquartersCatalog.MECHANICAL).is_empty() and profile.funds() == 0, "Mechanical is funded without injected time or a perfect")
	plan.configure_campaign(profile)
	state = DeploymentState.new(next.stage.map, CombatClock.new(), 0, next.opening_rules)
	_check(plan.can_start() and plan.facility_limit == 2 and state.deploy(post, Vector2i(1, 0), 1).is_empty() and state.tokens == 0, "C1-02 has a legal free ordinary Post after Mechanical")
	var stockpile := content.operation(&"C1-05")
	plan = OperationPlan.new(stockpile, [])
	plan.configure_campaign(profile)
	state = DeploymentState.new(stockpile.stage.map, CombatClock.new(), stockpile.opening_tokens, stockpile.opening_rules)
	_check(plan.can_start() and state.tokens == 120 and not state.deploy(post, Vector2i(1, 0), 1).is_empty() and post not in plan.choices, "C1-05 starts with exactly 120 and rejects Posts in plan and battle")
	plan = OperationPlan.new(first, [])
	plan.configure_campaign(profile)
	_check(plan.deployment_entries().size() == 3 and plan.selected_ids.is_empty() and plan.can_start(), "C1-01 replay receives its own Starter Post even with built Mechanical")
	var heat := content.operation(&"C2-07")
	plan = OperationPlan.new(heat, [])
	plan.configure_campaign(profile)
	var firebreak := _unit(content, &"facility.firebreak_beacon")
	var effective := plan.deployment_entries().filter(func(spec: DeploymentSpec) -> bool: return spec.id == firebreak.id)
	_check(effective.size() == 1 and effective[0].cost == firebreak.cost and firebreak.id not in plan.selected_ids, "Firebreak supply uses its ordinary price outside Mechanical slots")
	plan = OperationPlan.new(content.operation(&"C2-08"), [])
	plan.configure_campaign(profile)
	_check(firebreak not in plan.choices and String(firebreak.id) not in profile.snapshot().owned, "Firebreak is neither owned nor supplied to C2-08")

func _settlement(content: CampaignContent) -> void:
	var legacy := CampaignSave.fresh()
	legacy.records["C1-01"] = {"cleared": true, "perfect": false}
	_check(ProfileFile.replace(_path + ".legacy", legacy, false), "Write a v2 pre-C26 clear fixture")
	var returning := CampaignProgress.new(_path + ".legacy")
	var live_first := content.operation(&"C1-01")
	returning.begin_attempt(live_first)
	var later_perfect := returning.complete(live_first, true)
	returning = CampaignProgress.new(_path + ".legacy")
	_check(not later_perfect.first_clear and later_perfect.first_perfect and later_perfect.credited == 5500
		and returning.funds() == 15500 and returning.record_for(&"C1-01").perfect, "Earlier first clear remains consumed while a later perfect still records")
	var profile := CampaignProgress.new(_path + ".rewards")
	var trial := content.operation(&"C1-01").duplicate() as StoryOperation
	trial.rewards = {"first_clear_funds": 120, "first_perfect_funds": 30, "replay_funds": 7, "story_completion_reward_present": true, "story_completion_funds": 500}
	trial.clear_unlock_ids = [&"facility.sonic_turret"]
	profile.set_leader_name("Ranger")
	_check(profile.begin_attempt(trial), "First attempt can be persisted before battle")
	profile = CampaignProgress.new(_path + ".rewards")
	_check(profile.snapshot().pending_attempt == "C1-01" and profile.abandon_attempt() and profile.snapshot().funds == 10000, "Interrupted attempt persists and abandonment earns zero")
	profile.begin_attempt(trial)
	var first := profile.complete(trial, false)
	_check(first.credited == 620 and first.first_clear and first.unlocked == [&"facility.sonic_turret"] and not first.first_perfect, "First ordinary clear settles base and completion exactly once")
	_check(profile.complete(trial, true).is_empty(), "Outcome cannot settle twice without a new attempt")
	profile.begin_attempt(trial)
	var perfect := profile.complete(trial, true)
	_check(perfect.credited == 37 and perfect.first_perfect and not perfect.first_clear and perfect.unlocked.is_empty(), "First perfect during replay earns its milestone and replay only")
	profile.begin_attempt(trial)
	var replay := profile.complete(trial, false)
	_check(replay.credited == 7 and profile.record_for(&"C1-01").perfect and profile.snapshot().funds == 10664, "Subsequent replay earns only replay Funds and preserves perfect")
	var damaged := FileAccess.open(_path + ".rewards", FileAccess.WRITE)
	damaged.store_string("{")
	damaged.close()
	profile = CampaignProgress.new(_path + ".rewards")
	_check(profile.record_for(&"C1-01").perfect and profile.snapshot().funds == 10657, "Unreadable primary recovers the last readable profile")

func _medic(content: CampaignContent) -> void:
	var stage := content.operation(&"C1-01").stage
	var sim := BattleSimulation.new(stage)
	var medic := _unit(content, &"ranger.combat_medic") as RangerSpec
	var patrol := _unit(content, &"ranger.patrolman")
	sim.deployment = DeploymentState.new(stage.map, sim.clock, 100)
	sim.deployment.deploy(medic, Vector2i(5, 2), 1)
	sim.deployment.deploy(patrol, Vector2i(6, 3), -1)
	var ally := sim.deployment.placed[patrol.id]
	ally.hp -= 60
	sim.clock.dialogue_open = true
	sim.clock.advance_frame()
	_check(ally.hp == patrol.max_hp - 60, "Combat Medic does not heal in dialogue")
	sim.clock.dialogue_open = false
	sim.clock.advance_frame()
	_check(ally.hp == patrol.max_hp - 60 + medic.heal_hp, "Combat Medic restores nearby Ranger HP on the shared clock")

	# Let the next Medic action choose between two independent Patrolmen.
	while sim.deployment.cooldown_ticks(patrol.id) > 0:
		sim.clock.advance_frame()
	var second_tile := Vector2i(7, 3)
	_check(sim.deployment.deploy(patrol, second_tile, -1).is_empty(), "A second Patrolman joins the Medic's range")
	var second := sim.deployment.placed[sim.deployment.interaction_id(second_tile)]
	second.hp -= 60
	sim.clock.advance_frame()
	_check(ally.hp == patrol.max_hp and second.hp == patrol.max_hp - 60 + medic.heal_hp, "Medic heals the injured copy through its placement ID")

func _enemy(operation: StoryOperation, id: StringName) -> BattleEnemyDefinition:
	for wave in _effective_stage(operation).waves:
		for group in wave.groups:
			if group.enemy.enemy_id == id:
				return group.enemy
	return null

func _effective_stage(operation: StoryOperation) -> BattleStage:
	return BattleModifiers.new(operation.fixed_debuff_ids).stage(operation.stage)

func _unit(content: CampaignContent, id: StringName) -> DeploymentSpec:
	for spec in content.roster.entries:
		if spec.id == id:
			return spec
	return null

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
