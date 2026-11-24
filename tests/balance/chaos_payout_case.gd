extends RefCounted
## Fixed, legal Chaos recipes for the economy model. All damage comes from fielded Rangers.

const PATROL := &"ranger.patrolman"
const GUARD := &"ranger.guard_veteran"
const SCOUT := &"ranger.scout_sniper"
const MEDIC := &"ranger.combat_medic"
const POST := &"facility.logistics_post"
const DEBUFFS: Array[StringName] = [&"D02", &"D03", &"D05", &"D07", &"D08", &"D12", &"D13", &"D15"]

static func play(profile: CampaignProgress, content: CampaignContent, wave_sizes: Array, modifier_floor := -1) -> Dictionary:
	var short_run := wave_sizes == [2, 1]
	var loadout := [PATROL, POST] if short_run else [PATROL, GUARD, SCOUT, MEDIC, POST]
	var config := ChaosConfiguration.new()
	config.select_route(&"T01")
	for i in wave_sizes.size():
		config.set_quantity(i, &"E01", int(wave_sizes[i]))
	var operation := StoryOperation.new()
	operation.campaign_spec = true
	operation.roster = content.roster
	operation.stage = config.build_stage()
	operation.opening_rules = LogisticsRules.new()
	var plan := OperationPlan.new(operation, [], true)
	plan.configure_campaign(profile, loadout)
	plan.restore_modifier_selection(DEBUFFS)
	var resolution := plan.resolved()
	var run := profile.begin_chaos(config, resolution, plan.selected_ids, DEBUFFS)
	if run == null:
		return {"error": resolution.selection_error}
	var battle := BattleSimulation.new(resolution.stage)
	battle.deployment = DeploymentState.new(resolution.stage.map, battle.clock, resolution.tokens,
		resolution.opening, profile.records_enhancements(), battle.effects)
	var entries := {}
	for spec in resolution.entries:
		entries[spec.id] = spec
	var orders := [[PATROL, Vector2i(2, 1)]] if short_run else [
		[GUARD, Vector2i(3, 1)], [SCOUT, Vector2i(2, 0)], [MEDIC, Vector2i(1, 0)],
		[PATROL, Vector2i(4, 1)], [SCOUT, Vector2i(2, 2)], [SCOUT, Vector2i(5, 1)],
		[GUARD, Vector2i(6, 3)],
	]
	for step in 75000:
		if battle.clock.stopped:
			break
		if step % 30 == 0:
			for order in orders.duplicate():
				if entries.has(order[0]) and battle.deployment.deploy(entries[order[0]], order[1], -1).is_empty():
					orders.erase(order)
			for unit in battle.deployment.placed.values():
				if unit.spec.id == GUARD:
					battle.tap_unit(unit.id)
		battle.clock.advance_frame()
	if not run.record_outcome(battle):
		profile.abandon_chaos(run)
		return {"error": "Chaos fixture exceeded its time limit"}
	var original := run.score.points()
	# The optional sensitivity case changes only the positive credit used for settlement.
	if modifier_floor >= 0:
		run.score.debuff_points = mini(run.score.debuff_points, maxi(modifier_floor, run.score.enemy_points))
	var receipt := profile.settle_chaos(run)
	if receipt.is_empty():
		return {"error": "Chaos settlement failed"}
	receipt.merge({"original_score": original, "score": run.score.points(), "ticks": battle.clock.tick,
		"defeated": run.configured_defeated, "escapes": run.escaped, "qualifies": run.qualifies(),
		"enemy_points": run.score.enemy_points, "positive_modifiers": run.score.debuff_points})
	return receipt
