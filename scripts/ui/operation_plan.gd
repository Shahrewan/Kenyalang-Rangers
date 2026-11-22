class_name OperationPlan
extends RefCounted

var operation: StoryOperation
var selected_buff: PlanningBuff
var _unlocked: Array[StringName]

func _init(definition: StoryOperation, unlocked: Array[StringName]) -> void:
	operation = definition
	_unlocked = unlocked.duplicate()

func buff_error(buff: PlanningBuff) -> String:
	if buff == null or buff not in operation.buff_choices:
		return "This R&D effect is unavailable."
	if buff.needs_heat and not operation.has_heat:
		return "Requires a stage with Heat."
	if buff.id not in _unlocked:
		return "Locked · " + buff.requirement
	if buff.ranger_damage_percent == 0:
		return "Effect is unavailable in this build."
	return ""

func select_buff(buff: PlanningBuff) -> bool:
	if buff != null and not buff_error(buff).is_empty():
		return false
	# C1 selects one distinct effect. Selecting another replaces the previous pick.
	selected_buff = buff
	return true

func deployment_entries() -> Array[DeploymentSpec]:
	var entries: Array[DeploymentSpec] = []
	for spec in operation.roster.entries:
		if spec.id in operation.ranger_ids or spec.id in operation.supply_ids:
			if selected_buff != null and spec.is_ranger():
				var adjusted := spec.duplicate() as DeploymentSpec
				adjusted.attack_damage = roundi(spec.attack_damage * (100.0 + selected_buff.ranger_damage_percent) / 100.0)
				entries.append(adjusted)
			else:
				entries.append(spec)
	return entries

func can_start() -> bool:
	if operation.stage == null or not operation.stage.validation_error().is_empty() or operation.stage.enemy_count() == 0:
		return false
	var opening := DeploymentState.new(operation.stage.map, CombatClock.new(), 0, operation.opening_rules)
	return opening.has_legal_opening(deployment_entries())
