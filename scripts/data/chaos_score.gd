class_name ChaosScore
extends RefCounted

const SLOT_COST := 100
const THRESHOLDS := [1000, 2000, 3000]

var configured_enemies := 0
var enemy_points := 0
var ranger_slots: int
var facility_slots: int
var modifiers: Dictionary[StringName, int]
var debuff_points := 0
var buff_points := 0

func _init(plan: ModifierResolution) -> void:
	ranger_slots = plan.ranger_slots
	facility_slots = plan.facility_slots
	modifiers = plan.score_entries.duplicate()
	for value: int in modifiers.values():
		debuff_points += maxi(value, 0)
		buff_points += mini(value, 0)
	for wave in plan.stage.waves:
		for group in wave.groups:
			if group.count > 0:
				configured_enemies += group.count
				enemy_points += group.count * group.enemy.chaos_points

func slot_points() -> int:
	return -(ranger_slots + facility_slots) * SLOT_COST

func points() -> int:
	return enemy_points + debuff_points + buff_points + slot_points()

static func payout(score: int) -> int:
	if score >= 3000:
		return 300000 + 120 * (score - 3000)
	if score >= 2000:
		return 130000 + 70 * (score - 2000)
	if score >= 1000:
		return 40000 + 40 * (score - 1000)
	return 20 * maxi(0, score)

static func tier(score: int) -> int:
	return int(score >= 1000) + int(score >= 2000) + int(score >= 3000)

static func tier_id(threshold: int) -> String:
	return "chaos_tier.%d" % threshold

static func tier_facilities() -> Array[FacilitySpec]:
	var facilities: Array[FacilitySpec] = []
	for threshold: int in THRESHOLDS:
		for facility: FacilitySpec in DeployableLevels.FACILITIES.entries:
			if facility.chaos_threshold == threshold:
				facilities.append(facility)
	return facilities
