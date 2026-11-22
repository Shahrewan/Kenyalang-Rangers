class_name CampaignDebuffs
extends RefCounted

const TITLES := {
	&"D01": "Thin Supply Line", &"D02": "Urgent Pursuit", &"D03": "Field Fatigue",
	&"D04": "Radio Static", &"D05": "Fixed Stockpile", &"D06": "Persistent Concealment",
	&"D07": "Limited Respite", &"D08": "Toughened Crew", &"D09": "High-Impact Siege",
	&"D10": "Delayed Construction", &"D11": "Aerial Tailwind", &"D12": "Strained Logistics",
	&"D13": "Compressed Arrivals", &"D14": "Heat Surge", &"D15": "Critical Escape",
}

const DESCRIPTIONS := {
	&"D01": "Logistics Posts generate 10% fewer Tokens.",
	&"D02": "Enemies move 10% faster.",
	&"D03": "Rangers have 15% less maximum HP.",
	&"D04": "Ranger skills take 20% longer to recharge.",
	&"D05": "Start with 120 Tokens. Logistics Posts are unavailable.",
	&"D06": "Enemy smoke lasts two seconds longer.",
	&"D07": "Rest between waves is 40% shorter.",
	&"D08": "Enemies have 15% more maximum HP.",
	&"D09": "Siege damage increases by 25%.",
	&"D10": "Facility construction takes 25% longer.",
	&"D11": "Aerial enemies move 25% faster.",
	&"D12": "Rangers cost 10% more Tokens, rounded up.",
	&"D13": "Enemies arrive 20% closer together.",
	&"D14": "Heat accumulates 30% faster.",
	&"D15": "Ordinary escapes cost 50% more Integrity, rounded up.",
}

static func enemy(source: BattleEnemyDefinition, ids: Array[StringName]) -> BattleEnemyDefinition:
	var tuned := source.duplicate() as BattleEnemyDefinition
	if &"D02" in ids:
		tuned.tiles_per_second *= 1.10
	if &"D11" in ids and tuned.aerial:
		tuned.tiles_per_second *= 1.25
	if &"D08" in ids:
		tuned.max_hp = roundi(tuned.max_hp * 1.15)
	if &"D09" in ids and tuned.is_siege_capable():
		tuned.attack_damage = roundi(tuned.attack_damage * 1.25)
	if &"D15" in ids and not tuned.escape_causes_defeat:
		tuned.escape_penalty = ceili(tuned.escape_penalty * 1.50)
	if &"D06" in ids and tuned.ability != null and tuned.ability.effect == EnemyAbility.Effect.SMOKE:
		tuned.ability = tuned.ability.duplicate() as EnemyAbility
		tuned.ability.duration_seconds += 2.0
	if tuned is BossSpec:
		var phases: Array[BossPhase] = []
		for phase: BossPhase in tuned.phases:
			var copy := phase.duplicate() as BossPhase
			if copy.reinforcement != null:
				copy.reinforcement = enemy(copy.reinforcement, ids)
			phases.append(copy)
		tuned.phases = phases
	return tuned

static func deployable(source: DeploymentSpec, ids: Array[StringName]) -> DeploymentSpec:
	var tuned := source.duplicate() as DeploymentSpec
	if tuned.is_ranger():
		if &"D03" in ids:
			tuned.max_hp = roundi(tuned.max_hp * 0.85)
		if &"D12" in ids:
			tuned.cost = ceili(tuned.cost * 110.0 / 100.0)
		if &"D04" in ids and tuned is RangerSpec and tuned.active_skill != null:
			tuned.active_skill = tuned.active_skill.duplicate() as RangerSkill
			tuned.active_skill.recharge_seconds *= 1.20
	elif &"D10" in ids:
		tuned.build_seconds *= 1.25
	return tuned

static func opening(base: LogisticsRules, stage_id: StringName, ids: Array[StringName]) -> LogisticsRules:
	var rules := base.duplicate() as LogisticsRules
	rules.starter_only = stage_id == &"C1-01"
	rules.fixed_stockpile = &"D05" in ids
	rules.yield_percent = 90 if &"D01" in ids else 100
	return rules

static func rest(seconds: float, ids: Array[StringName]) -> float:
	return seconds * 0.6 if &"D07" in ids else seconds

static func spacing(seconds: float, ids: Array[StringName]) -> float:
	return seconds * 0.8 if &"D13" in ids else seconds
