class_name ModifierSetup
extends RefCounted

var stage: BattleStage
var loadout: Array[DeploymentSpec] = []
var opening := LogisticsRules.new()
var starting_tokens := 0
var fixed_debuffs: Array[StringName] = []
var unlocked_buffs: Array[StringName] = []
var enhancements: Array[StringName] = []
var buff_limit := 1
var chaos := false

func resolve(buffs: Array[StringName], debuffs: Array[StringName] = [], build_snapshot := true) -> ModifierResolution:
	var result := ModifierResolution.new()
	result.stage = stage
	result.selection_error = _selection_error(buffs, debuffs)
	if not result.selection_error.is_empty():
		return result
	var effects := BattleModifiers.new(fixed_debuffs + buffs + debuffs)
	result.opening = effects.logistics(opening)
	result.tokens = LogisticsRules.FIXED_STOCKPILE if result.opening.fixed_stockpile else effects.opening_tokens(starting_tokens)
	for spec in loadout:
		if spec.logistics_post and result.opening.fixed_stockpile:
			continue
		result.entries.append(effects.deployable(spec))
		if spec.is_ranger():
			result.ranger_slots += 1
		else:
			result.facility_slots += 1
	var state := DeploymentState.new(stage.map, CombatClock.new(), result.tokens, result.opening)
	if not state.has_legal_opening(result.entries):
		result.opening_error = "Start requires an affordable legal deployment."
	if build_snapshot:
		result.stage = effects.stage(stage)
	var eligibility := ModifierEligibility.new(stage, result.entries, state, effects, enhancements)
	for id in buffs + debuffs:
		var definition := BattleModifiers.CATALOG.definition(id)
		var reason := _stockpile_error(result) if definition.applies_to == BattleModifier.AppliesTo.STOCKPILE else eligibility.error(definition)
		if not reason.is_empty():
			result.selection_error = "%s · %s" % [definition.display_name, reason]
			return result
	if not build_snapshot:
		return result
	for id in fixed_debuffs:
		var definition := BattleModifiers.CATALOG.definition(id)
		var reason := eligibility.error(definition)
		if not reason.is_empty():
			result.inactive_fixed[id] = reason
	if chaos and result.can_start():
		for id in buffs + debuffs:
			result.score_entries[id] = BattleModifiers.CATALOG.definition(id).chaos_points
	return result

func _selection_error(buffs: Array[StringName], debuffs: Array[StringName]) -> String:
	if stage == null or not stage.validation_error().is_empty() or stage.enemy_count() == 0:
		return "Choose a valid arena with a populated wave."
	if not chaos and not debuffs.is_empty():
		return "Story debuffs are fixed by the operation."
	if not chaos and buffs.size() > buff_limit:
		return "This operation allows %d distinct %s." % [buff_limit, "buff" if buff_limit == 1 else "buffs"]
	var units := {}
	for spec in loadout:
		if spec == null or units.has(spec.id):
			return "Equip each deployable at most once."
		units[spec.id] = true
	var seen := {}
	for id in fixed_debuffs + debuffs + buffs:
		var definition := BattleModifiers.CATALOG.definition(id)
		if definition == null or definition.is_buff() != (id in buffs):
			return "Unknown modifier or wrong selection category."
		if seen.has(id):
			return "Select each modifier once."
		seen[id] = true
		if definition.is_buff() and id not in unlocked_buffs:
			return "%s is locked by Headquarters research." % definition.display_name
	if (&"D05" in fixed_debuffs or &"D05" in debuffs or opening.fixed_stockpile) and &"B13" in buffs:
		return "Emergency Requisition and Fixed Stockpile cannot be combined."
	return ""

func _stockpile_error(result: ModifierResolution) -> String:
	var normal := DeploymentState.new(stage.map, CombatClock.new(), starting_tokens, opening)
	var posts := loadout.filter(func(spec: DeploymentSpec) -> bool: return spec.logistics_post)
	if not normal.has_legal_opening(posts):
		return "Requires an otherwise legal loadout with a Logistics Post."
	if not result.opening_error.is_empty():
		return "Requires a legal Post-free deployment within 120 Tokens."
	return ""
