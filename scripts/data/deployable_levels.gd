class_name DeployableLevels
extends RefCounted

const MAX_LEVEL := 100
const TOTAL_COST := 1000000
const MILESTONES := [20, 40, 60, 80, 100]
const FIELD_RANGERS := preload("res://data/rangers/c14_campaign_roster.tres")
const FACILITIES := preload("res://data/facilities/catalog.tres")

static func catalog(rangers: bool) -> Array[DeploymentSpec]:
	return FIELD_RANGERS.entries.duplicate() if rangers else FACILITIES.entries.duplicate()

static func definition(id: StringName) -> DeploymentSpec:
	for roster in [FIELD_RANGERS, FACILITIES]:
		for entry: DeploymentSpec in roster.entries:
			if entry.id == id:
				return entry
	return null

static func cumulative(level: int) -> int:
	var x := _fraction(level)
	return roundi(TOTAL_COST * (0.15 * x + 0.85 * x * x))

static func cost(from: int, target: int) -> int:
	return cumulative(target) - cumulative(from)

static func effective(spec: DeploymentSpec, level: int) -> DeploymentSpec:
	var unit := spec.duplicate() as DeploymentSpec
	unit.level = clampi(level, 1, MAX_LEVEL)
	var growth := spec.growth
	if growth == null or unit.level == 1:
		return unit
	unit.max_hp = _output(spec.max_hp, growth.hp, unit.level)
	unit.attack_damage = _output(spec.attack_damage, growth.attack_damage, unit.level)
	if unit is RangerSpec:
		unit.heal_hp = _output(unit.heal_hp, growth.healing, unit.level)
		unit.repair_hp = _output(unit.repair_hp, growth.repair, unit.level)
		if unit.active_skill != null and growth.skill_damage > 0:
			unit.active_skill = unit.active_skill.duplicate() as RangerSkill
			unit.active_skill.damage = _output(unit.active_skill.damage, growth.skill_damage, unit.level)
	elif unit is FacilitySpec:
		unit.heal_per_kit = _output(unit.heal_per_kit, growth.healing, unit.level)
		if unit.cooldown_reduction_seconds > 0.0 and growth.cooldown_reduction_seconds > 0.0:
			unit.cooldown_reduction_seconds = lerpf(unit.cooldown_reduction_seconds, growth.cooldown_reduction_seconds, _fraction(unit.level))
		unit.detection_radius = _output(unit.detection_radius, growth.detection_radius, unit.level)
		unit.heat_slow_percent = _output(unit.heat_slow_percent, growth.heat_slow_percent, unit.level)
		unit.discount_tokens = _output(unit.discount_tokens, growth.discount_tokens, unit.level)
		unit.attack_rate_bonus_percent = _output(unit.attack_rate_bonus_percent, growth.attack_rate_bonus_percent, unit.level)
		unit.incoming_reduction_percent = _output(unit.incoming_reduction_percent, growth.incoming_reduction_percent, unit.level)
		unit.outgoing_reduction_percent = _output(unit.outgoing_reduction_percent, growth.outgoing_reduction_percent, unit.level)
	return unit

static func with_records_stats(spec: DeploymentSpec, enhancements: Array[StringName]) -> DeploymentSpec:
	var ranger := spec as RangerSpec
	if ranger == null or ranger.records_enhancement.is_empty() or not ranger.records_enhancement in enhancements:
		return spec
	if ranger.records_bonus_hp == 0 and ranger.records_heal_interval_seconds == 0.0 and ranger.records_redeploy_reduction_seconds == 0.0:
		return spec
	var tuned := ranger.duplicate() as RangerSpec
	tuned.max_hp += maxi(0, ranger.records_bonus_hp)
	if ranger.heal_hp > 0 and ranger.records_heal_interval_seconds > 0.0:
		tuned.attack_seconds = minf(ranger.attack_seconds, ranger.records_heal_interval_seconds)
	tuned.redeploy_seconds = maxf(0.0, ranger.redeploy_seconds - maxf(0.0, ranger.records_redeploy_reduction_seconds))
	return tuned

static func _output(base: int, endpoint: int, level: int) -> int:
	return roundi(lerpf(base, endpoint, _fraction(level))) if base > 0 and endpoint > 0 else base

static func _fraction(level: int) -> float:
	return (clampi(level, 1, MAX_LEVEL) - 1) / float(MAX_LEVEL - 1)
