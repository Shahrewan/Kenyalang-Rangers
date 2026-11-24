class_name BattleSkillStatus
extends RefCounted

enum Mode { READY, RECOVERING, LOCKED, SPENT }

var label: String
var charges: int
var maximum: int
var mode: Mode
var reason := ""
var progress := -1.0
var remaining_ticks := 0
var just_ready := false

static func read(unit: DeploymentState.Placement, state: DeploymentState) -> BattleSkillStatus:
	if unit == null or unit.spec.skill == DeploymentSpec.Skill.NONE:
		return null
	var skill := unit.ranger.active_skill if unit.ranger != null else null
	var facility := unit.facility
	if skill == null and (facility == null or facility.stock_capacity <= 0):
		return null
	var result := BattleSkillStatus.new()
	var tick := state.clock.tick
	result.reason = state.skill_block_reason(unit)
	if skill != null:
		result.label = skill.label
		result.charges = unit.skill_charges
		result.maximum = skill.max_charges
		if unit.skill_recharge_tick > tick:
			result._recover(tick, unit.skill_recharge_tick, unit.skill_recharge_started)
	else:
		result.label = "Medical kits" if facility.role == FacilitySpec.Role.MEDIC_CABIN else "Specialist discount"
		result.charges = unit.stock
		result.maximum = facility.stock_capacity
		if result.reason.is_empty() and facility.role == FacilitySpec.Role.SPECIALIST_CALLTOWER and state.specialist_discount > 0:
			result.reason = "Discount queued"
		if result.charges < result.maximum and tick >= unit.build_deadline and unit.next_utility_tick > tick \
				and state.effects.amount(&"disable_skills") == 0:
			var interval := CombatClock.ticks_for(facility.work_seconds)
			result._recover(tick, unit.next_utility_tick, unit.next_utility_tick - interval)
	result.mode = Mode.SPENT
	if not result.reason.is_empty():
		result.mode = Mode.LOCKED
	elif result.charges > 0:
		result.mode = Mode.READY
		result.just_ready = tick - unit.skill_ready_since < 24
	elif result.remaining_ticks > 0:
		result.mode = Mode.RECOVERING
	return result

func _recover(tick: int, deadline: int, start: int) -> void:
	remaining_ticks = deadline - tick
	progress = clampf(1.0 - float(remaining_ticks) / maxi(1, deadline - start), 0.0, 1.0)

func detail() -> String:
	var state_label := ""
	match mode:
		Mode.LOCKED: state_label = reason
		Mode.READY: state_label = "Ready"
		Mode.RECOVERING: state_label = "Recovering"
		Mode.SPENT: state_label = "Spent"
	var recovery := " · next in %ds" % ceili(float(remaining_ticks) / CombatClock.TICKS_PER_SECOND) if remaining_ticks > 0 else ""
	return "%s %d/%d · %s%s" % [label, charges, maximum, state_label, recovery]
