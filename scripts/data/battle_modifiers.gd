class_name BattleModifiers
extends RefCounted

const CATALOG: ModifierCatalog = preload("res://data/modifiers/catalog.tres")

var ids: Array[StringName] = []
var _totals: Dictionary[StringName, float] = {}

func _init(selected: Array[StringName] = []) -> void:
	for id in selected:
		var definition := CATALOG.definition(id)
		if definition == null or id in ids:
			continue
		ids.append(id)
		for key: StringName in definition.effects:
			_totals[key] = amount(key) + definition.effects[key]

func amount(key: StringName) -> float:
	return _totals.get(key, 0.0)

func scale(key: StringName) -> float:
	return (100.0 + amount(key)) / 100.0

func opening_tokens(base: int) -> int:
	return LogisticsRules.FIXED_STOCKPILE if amount(&"fixed_stockpile") > 0.0 else base + int(amount(&"opening_tokens"))

func logistics(base: LogisticsRules) -> LogisticsRules:
	var rules := base.duplicate() as LogisticsRules
	rules.fixed_stockpile = rules.fixed_stockpile or amount(&"fixed_stockpile") > 0.0
	rules.yield_percent += int(amount(&"post_yield_percent"))
	return rules

func deployable(source: DeploymentSpec) -> DeploymentSpec:
	if ids.is_empty():
		return source
	var tuned := source.duplicate() as DeploymentSpec
	if tuned.is_ranger():
		tuned.max_hp = roundi(tuned.max_hp * scale(&"ranger_hp_percent"))
		tuned.attack_damage = roundi(tuned.attack_damage * scale(&"ranger_damage_percent"))
		tuned.cost = ceili(tuned.cost * (100 + int(amount(&"ranger_cost_percent"))) / 100.0)
		if tuned is RangerSpec and tuned.active_skill != null:
			tuned.active_skill = tuned.active_skill.duplicate() as RangerSkill
			tuned.active_skill.damage = roundi(tuned.active_skill.damage * scale(&"ranger_damage_percent"))
			tuned.active_skill.recharge_seconds *= scale(&"skill_duration_percent") / scale(&"skill_recovery_percent")
	else:
		tuned.build_seconds *= scale(&"build_time_percent")
	return tuned

func enemy(source: BattleEnemyDefinition) -> BattleEnemyDefinition:
	var tuned := source.duplicate() as BattleEnemyDefinition
	var speed_bonus := amount(&"enemy_speed_percent")
	if tuned.aerial:
		speed_bonus += amount(&"aerial_speed_percent")
	tuned.tiles_per_second *= (100.0 + speed_bonus) / 100.0
	tuned.max_hp = roundi(tuned.max_hp * scale(&"enemy_hp_percent"))
	if tuned.is_siege_capable():
		tuned.attack_damage = roundi(tuned.attack_damage * scale(&"siege_damage_percent"))
	if not tuned.escape_causes_defeat:
		tuned.escape_penalty = escape_penalty(tuned.escape_penalty)
	if tuned.ability != null and tuned.ability.effect == EnemyAbility.Effect.SMOKE and amount(&"smoke_seconds") > 0:
		tuned.ability = tuned.ability.duplicate() as EnemyAbility
		tuned.ability.duration_seconds += amount(&"smoke_seconds")
	if tuned is BossSpec:
		var phases: Array[BossPhase] = []
		for phase: BossPhase in tuned.phases:
			var copy := phase.duplicate() as BossPhase
			if copy.reinforcement != null:
				copy.reinforcement = enemy(copy.reinforcement)
			phases.append(copy)
		tuned.phases = phases
	return tuned

func escape_penalty(base: int) -> int:
	if base <= 0:
		return base
	var penalty := ceili(base * scale(&"escape_increase_percent"))
	return maxi(1, roundi(penalty * scale(&"escape_reduction_percent")))

func stage(base: BattleStage) -> BattleStage:
	if ids.is_empty():
		return base
	var result := base.duplicate() as BattleStage
	result.modifier_ids = ids.duplicate()
	result.heat_gain_scale *= scale(&"heat_gain_percent")
	var definitions: Dictionary[BattleEnemyDefinition, BattleEnemyDefinition] = {}
	var waves: Array[BattleWave] = []
	for wave in base.waves:
		var copy := BattleWave.new()
		copy.rest_after_seconds = wave.rest_after_seconds * scale(&"wave_rest_percent")
		for group in wave.groups:
			var altered := group.duplicate() as BattleSpawnGroup
			altered.interval_seconds *= scale(&"spawn_interval_percent")
			if altered.count > 0:
				if not definitions.has(group.enemy):
					definitions[group.enemy] = enemy(group.enemy)
				altered.enemy = definitions[group.enemy]
			copy.groups.append(altered)
		waves.append(copy)
	result.waves = waves
	return result
