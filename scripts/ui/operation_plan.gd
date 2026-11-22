class_name OperationPlan
extends RefCounted

var operation: StoryOperation
var selected_buff: PlanningBuff
var choices: Array[DeploymentSpec] = []
var selected_ids: Array[StringName] = []
var ranger_limit := 0
var facility_limit := 0
var show_hints := true
var _unlocked: Array[StringName]
var _unit_levels: Dictionary

func _init(definition: StoryOperation, unlocked: Array[StringName]) -> void:
	operation = definition
	_unlocked = unlocked.duplicate()

func configure_campaign(progress: CampaignProgress, previous_selection: Variant = null) -> void:
	ranger_limit = progress.room_capacity(HeadquartersCatalog.HR)
	facility_limit = progress.room_capacity(HeadquartersCatalog.MECHANICAL)
	_unlocked = progress.unlocked_buffs()
	_unit_levels = progress.snapshot().deployable_levels
	if selected_buff != null and not buff_error(selected_buff).is_empty():
		selected_buff = null
	choices.clear()
	selected_ids.clear()
	if operation.opening_rules.starter_only:
		return
	for spec in operation.roster.entries:
		if not progress.owns(spec.id) or spec.id in operation.supply_ids:
			continue
		if not spec.is_ranger() and (facility_limit == 0 or (spec.logistics_post and operation.opening_rules.fixed_stockpile)):
			continue
		choices.append(spec)
	for spec in choices:
		if previous_selection == null or spec.id in previous_selection:
			select_unit(spec, true)

func select_unit(spec: DeploymentSpec, selected: bool) -> bool:
	if spec not in choices:
		return false
	if not selected:
		selected_ids.erase(spec.id)
		return true
	if spec.id in selected_ids:
		return true
	var limit := ranger_limit if spec.is_ranger() else facility_limit
	if selected_count(spec.is_ranger()) >= limit:
		return false
	selected_ids.append(spec.id)
	return true

func selected_count(rangers: bool) -> int:
	var count := 0
	for spec in choices:
		if spec.is_ranger() == rangers and spec.id in selected_ids:
			count += 1
	return count

func buff_error(buff: PlanningBuff) -> String:
	if buff == null or buff not in operation.buff_choices:
		return "This R&D effect is unavailable."
	if operation.optional_buff_limit == 0:
		return "This operation has no R&D slots."
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
	# B05 is the current implemented planning effect.
	selected_buff = buff
	return true

func deployment_entries() -> Array[DeploymentSpec]:
	var entries: Array[DeploymentSpec] = []
	var selection := selected_ids if operation.campaign_spec else operation.ranger_ids
	for spec in operation.roster.entries:
		if spec.id in selection or spec.id in operation.supply_ids:
			entries.append(effective_spec(spec))
	return entries

func effective_spec(spec: DeploymentSpec) -> DeploymentSpec:
	var adjusted := spec
	if operation.campaign_spec:
		# Mission-issued cards keep their authored levels on every attempt.
		if spec.id not in operation.supply_ids:
			adjusted = DeployableLevels.effective(spec, int(_unit_levels.get(String(spec.id), spec.level)))
		adjusted = CampaignDebuffs.deployable(adjusted, operation.fixed_debuff_ids)
	if selected_buff != null and spec.is_ranger():
		if adjusted == spec:
			adjusted = spec.duplicate() as DeploymentSpec
		adjusted.attack_damage = roundi(adjusted.attack_damage * (100.0 + selected_buff.ranger_damage_percent) / 100.0)
	return adjusted

func can_start() -> bool:
	if operation.stage == null or not operation.stage.validation_error().is_empty() or operation.stage.enemy_count() == 0:
		return false
	var opening := DeploymentState.new(operation.stage.map, CombatClock.new(), operation.opening_tokens, operation.opening_rules)
	return opening.has_legal_opening(deployment_entries())
