class_name OperationPlan
extends RefCounted

var operation: StoryOperation
var chaos: bool
var selected_buff: BattleModifier:
	get:
		return null if _buffs.is_empty() else BattleModifiers.CATALOG.definition(_buffs[0])
var choices: Array[DeploymentSpec] = []
var selected_ids: Array[StringName] = []
var ranger_limit := 0
var facility_limit := 0
var show_hints := true
var _unlocked: Array[StringName]
var _enhancements: Array[StringName] = []
var _unit_levels: Dictionary
var _buffs: Array[StringName] = []
var _debuffs: Array[StringName] = []
var _resolved: ModifierResolution

func _init(definition: StoryOperation, unlocked: Array[StringName], as_chaos := false) -> void:
	operation = definition
	_unlocked = unlocked.duplicate()
	chaos = as_chaos

func configure_campaign(progress: CampaignProgress, previous_selection: Variant = null) -> void:
	ranger_limit = progress.room_capacity(HeadquartersCatalog.HR)
	facility_limit = progress.room_capacity(HeadquartersCatalog.MECHANICAL)
	_unlocked = progress.unlocked_buffs()
	_enhancements = progress.records_enhancements()
	_unit_levels = progress.snapshot().deployable_levels
	_resolved = null
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
		_resolved = null
		return true
	if spec.id in selected_ids:
		return true
	var limit := ranger_limit if spec.is_ranger() else facility_limit
	if selected_count(spec.is_ranger()) >= limit:
		return false
	selected_ids.append(spec.id)
	_resolved = null
	return true

func selected_count(rangers: bool) -> int:
	var count := 0
	for spec in choices:
		if spec.is_ranger() == rangers and spec.id in selected_ids:
			count += 1
	return count

func modifier_choices(buffs: bool) -> Array[BattleModifier]:
	return BattleModifiers.CATALOG.entries.filter(func(modifier: BattleModifier) -> bool:
		return modifier.is_buff() == buffs and (operation.campaign_spec or modifier.id in operation.buff_ids)
	)

func modifier_selected(id: StringName) -> bool:
	return id in _buffs or id in _debuffs

func modifier_count(buffs: bool) -> int:
	return _buffs.size() if buffs else _debuffs.size()

func modifier_selection() -> Array[StringName]:
	return _buffs + _debuffs

func restore_modifier_selection(ids: Array[StringName]) -> void:
	_buffs.clear()
	_debuffs.clear()
	for id in ids:
		var modifier := BattleModifiers.CATALOG.definition(id)
		if modifier != null:
			var selection := _buffs if modifier.is_buff() else _debuffs
			selection.append(id)
	_resolved = null

func update_stage(value: BattleStage) -> void:
	operation.stage = value
	_resolved = null

func buff_error(buff: BattleModifier) -> String:
	if buff == null or not buff.is_buff() or (not operation.campaign_spec and buff.id not in operation.buff_ids):
		return "This R&D effect is unavailable."
	if buff.id not in _unlocked:
		return "Locked · " + research_requirement(buff.id)
	if not operation.campaign_spec:
		return _setup().resolve([buff.id], [], false).selection_error
	return modifier_error(buff)

func modifier_error(modifier: BattleModifier) -> String:
	if modifier_selected(modifier.id):
		return ""
	var buffs := _buffs.duplicate()
	var debuffs := _debuffs.duplicate()
	if modifier.is_buff():
		if modifier.id not in _unlocked:
			return "Locked · " + research_requirement(modifier.id)
		buffs.append(modifier.id)
	else:
		debuffs.append(modifier.id)
	return _setup().resolve(buffs, debuffs, false).selection_error

func select_buff(buff: BattleModifier) -> bool:
	# Legacy single-choice planner uses the same catalogue and runtime rules.
	if buff != null and not buff_error(buff).is_empty():
		return false
	_buffs.clear()
	if buff != null:
		_buffs.append(buff.id)
	_resolved = null
	return true

func set_modifier(modifier: BattleModifier, enabled: bool) -> bool:
	var selection := _buffs if modifier.is_buff() else _debuffs
	if enabled:
		if modifier.id in selection or not modifier_error(modifier).is_empty():
			return false
		selection.append(modifier.id)
	else:
		selection.erase(modifier.id)
	_resolved = null
	return true

func effective_spec(spec: DeploymentSpec) -> DeploymentSpec:
	var effects := BattleModifiers.new(operation.fixed_debuff_ids + _buffs + _debuffs)
	return effects.deployable(_leveled(spec))

func deployment_entries() -> Array[DeploymentSpec]:
	return resolved().entries

func resolved() -> ModifierResolution:
	if _resolved == null:
		_resolved = _setup().resolve(_buffs, _debuffs)
	return _resolved

func can_start() -> bool:
	return resolved().can_start()

func _setup() -> ModifierSetup:
	var result := ModifierSetup.new()
	result.stage = operation.stage
	result.opening = operation.opening_rules
	result.starting_tokens = operation.opening_tokens
	result.fixed_debuffs = operation.fixed_debuff_ids
	result.unlocked_buffs = _unlocked
	result.enhancements = _enhancements
	result.chaos = chaos
	result.buff_limit = operation.optional_buff_limit
	var selection := selected_ids if operation.campaign_spec else operation.ranger_ids
	for spec in operation.roster.entries:
		if spec.id in selection or spec.id in operation.supply_ids:
			result.loadout.append(_leveled(spec))
	return result

func _leveled(spec: DeploymentSpec) -> DeploymentSpec:
	var effective := spec
	if operation.campaign_spec and spec.id not in operation.supply_ids:
		effective = DeployableLevels.effective(spec, int(_unit_levels.get(String(spec.id), spec.level)))
	return DeployableLevels.with_records_stats(effective, _enhancements)

static func research_requirement(id: StringName) -> String:
	for room: HeadquartersRoom in CampaignProgress.HEADQUARTERS.rooms:
		if room.role != HeadquartersRoom.Role.RESEARCH:
			continue
		var tier := room.tier_unlocks.find(String(id))
		if tier >= 0:
			return "%s Lv.%d" % [room.label, tier + 1]
	return "Headquarters research"
