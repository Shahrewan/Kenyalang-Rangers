class_name CampaignContent
extends RefCounted

const SOURCE := "res://docs/production/w13/"
const ENEMIES := preload("res://data/enemies/catalog.tres")
const BOSSES := preload("res://data/bosses/catalog.tres")
const RANGERS := DeployableLevels.FIELD_RANGERS
const FACILITIES := DeployableLevels.FACILITIES
const LEGACY_PLAN := preload("res://data/stages/c09_first_contact_operation.tres")
const BASE_RULES := preload("res://data/stages/c04_logistics_rules.tres")
const MAPS := {
	&"T01": preload("res://data/stages/c05_first_contact.tres"),
	&"T02": preload("res://data/stages/campaign/t02_gunung_mulu.tres"),
	&"T03": preload("res://data/stages/campaign/t03_batang_ai.tres"),
	&"T04": preload("res://data/stages/campaign/t04_tanjung_datu.tres"),
	&"T05": preload("res://data/stages/campaign/t05_imbak_canyon.tres"),
	&"T06": preload("res://data/stages/campaign/t06_sepilok_kabili.tres"),
}
const STARTERS := [&"ranger.scout_sniper", &"ranger.patrolman", &"facility.logistics_post"]
const EVENTS := [
	"operation_opening", "before_wave_first_spawn", "wave_resolved", "boss_intro",
	"boss_phase_changed", "victory", "defeat", "after_victory_dialogue",
]

var operations: Array[StoryOperation] = []
var speakers: Dictionary
var error := ""
var roster := DeploymentRoster.new()
var _by_id: Dictionary[StringName, StoryOperation] = {}
var _enemies: Dictionary[StringName, BattleEnemyDefinition] = {}
var _units: Dictionary[StringName, DeploymentSpec] = {}

func _init() -> void:
	for entry in ENEMIES.entries + BOSSES.entries:
		_enemies[entry.enemy_id] = entry
	roster.entries.assign(RANGERS.entries + FACILITIES.entries)
	for entry in roster.entries:
		_units[entry.id] = entry
	var manifest := _read_json(SOURCE + "campaign.json")
	if manifest.get("schema_version") != 1 or not manifest.get("content_paths") is Array:
		error = "Campaign manifest is unreadable or uses an unsupported schema."
		return
	var ids: Array = manifest.get("mission_ids", [])
	var paths: Array = manifest.content_paths
	if ids.size() != 15 or paths.size() != ids.size():
		error = "The Campaign manifest needs its fifteen ordered operations."
		return
	speakers = manifest.get("speakers", {})
	var noncombat: Dictionary = manifest.get("noncombat_events", {})
	for i in ids.size():
		var id := StringName(str(ids[i]))
		var path := "stages/%s.json" % String(id).to_lower()
		if paths[i] != path:
			error = "An operation has an invalid content path."
			break
		var data := _read_json(SOURCE + path)
		var previous: StringName = operations.back().stage.stage_id if not operations.is_empty() else &""
		var operation := _build(data, id, previous, i + 1, noncombat)
		if operation == null:
			error = "%s could not be imported. %s" % [id, error]
			break
		operations.append(operation)
		_by_id[id] = operation
	if not error.is_empty():
		operations.clear()
		_by_id.clear()

func operation(id: StringName) -> StoryOperation:
	return _by_id.get(id)

func label_for(id: StringName) -> String:
	var unit := DeployableLevels.definition(id)
	return unit.label if unit != null else String(id)

func has_combat_kit(id: StringName) -> bool:
	return _units.has(id)

func enemy_name(id: StringName) -> String:
	return _enemies[id].display_name if _enemies.has(id) else String(id)

func _build(data: Dictionary, id: StringName, previous: StringName, order: int, noncombat: Dictionary) -> StoryOperation:
	if StringName(str(data.get("id", ""))) != id or _by_id.has(id):
		return _fail("Operation ID does not match the manifest.")
	var meta: Dictionary = data.get("operation", {})
	if int(meta.get("order", 0)) != order or _optional_id(meta.get("requires_previous_clear")) != previous:
		return _fail("Prerequisite does not follow the published order.")
	var map_id := StringName(str(meta.get("map_id", "")))
	var template: BattleStage = MAPS.get(map_id)
	if template == null:
		return _fail("Unknown tactical map.")
	var result := StoryOperation.new()
	result.campaign_spec = true
	result.title = data.title
	result.region = meta.region
	result.prerequisite = previous
	result.min_control_level = int(meta.min_control_level)
	result.optional_buff_limit = int(meta.max_distinct_optional_buffs)
	result.opening_tokens = int(data.opening.tokens_before_eligible_effects)
	result.roster = roster
	result.buff_choices.assign(LEGACY_PLAN.buff_choices)
	result.fixed_debuff_ids.assign(meta.fixed_debuff_ids.map(func(value: String) -> StringName: return StringName(value)))
	if result.min_control_level < 1 or result.min_control_level > 5:
		return _fail("Invalid Control visibility tier.")
	var titles := PackedStringArray()
	for debuff in result.fixed_debuff_ids:
		if not CampaignDebuffs.TITLES.has(debuff):
			return _fail("Unknown fixed debuff.")
		titles.append("%s · %s" % [debuff, CampaignDebuffs.TITLES[debuff]])
	result.fixed_debuff = "\n".join(titles)
	result.opening_rules = CampaignDebuffs.opening(BASE_RULES, id, result.fixed_debuff_ids)
	if result.opening_tokens != (LogisticsRules.FIXED_STOCKPILE if result.opening_rules.fixed_stockpile else 0):
		return _fail("Opening budget does not match the fixed effects.")
	for unlock in meta.clear_unlock_ids:
		var unlock_id := StringName(unlock)
		if DeployableLevels.definition(unlock_id) == null:
			return _fail("Unknown recruit or Facility unlock.")
		result.clear_unlock_ids.append(unlock_id)
	for supply in meta.mission_supply:
		var supply_id := StringName(supply.id)
		if not _units.has(supply_id):
			return _fail("Unknown mission supply.")
		result.supply_ids.append(supply_id)
	result.rewards = data.rewards
	result.hints.assign(data.tutorial_hints)
	result.dialogue.assign(data.dialogue_sequences)
	if not _valid_dialogue(result.dialogue, noncombat):
		return _fail("Dialogue references an unknown event, speaker or pose.")
	var stage := template.duplicate() as BattleStage
	stage.stage_id = id
	stage.first_clear_funds = 0
	stage.first_perfect_funds = 0
	stage.opening_delay_seconds = float(data.balance_trial.opening_delay_seconds)
	var heat: Variant = data.balance_trial.heat
	stage.heat_capacity = float(heat.capacity) if heat is Dictionary else 0.0
	stage.heat_integrity_loss = int(heat.integrity_loss_per_reset) if heat is Dictionary else 0
	stage.heat_gain_scale = 1.30 if &"D14" in result.fixed_debuff_ids else 1.0
	result.has_heat = stage.heat_capacity > 0.0
	stage.capture_boss_id = _optional_id(data.outcome.get("early_capture_boss_id"))
	var waves := _waves(data.waves, meta.published_first_pass_wave_counts, result.fixed_debuff_ids)
	if waves.is_empty():
		return _fail("Wave totals or enemy references are invalid.")
	stage.waves = waves
	if not _bind_escape_rules(stage, data.outcome.instant_loss_on_escape_enemy_ids):
		return _fail("A fatal escape target is missing from the waves.")
	var stage_error := stage.validation_error()
	if not stage_error.is_empty():
		return _fail(stage_error)
	result.stage = stage
	return result

func _bind_escape_rules(stage: BattleStage, fatal_ids: Array) -> bool:
	var found := {}
	for wave in stage.waves:
		for group in wave.groups:
			var id := String(group.enemy.enemy_id)
			group.enemy.escape_causes_defeat = id in fatal_ids
			if group.enemy.escape_causes_defeat:
				found[id] = true
	return found.size() == fatal_ids.size()

func _waves(rows: Array, published: Array, ids: Array[StringName]) -> Array[BattleWave]:
	var waves: Array[BattleWave] = []
	if rows.size() != published.size():
		return waves
	var resolved: Dictionary[StringName, BattleEnemyDefinition] = {}
	for i in rows.size():
		var row: Dictionary = rows[i]
		var wave := BattleWave.new()
		wave.rest_after_seconds = CampaignDebuffs.rest(float(row.base_rest_after_seconds), ids)
		var count := 0
		for item in row.groups:
			var id := StringName(item.enemy_id)
			if not _enemies.has(id) or int(item.count) <= 0:
				return []
			if not resolved.has(id):
				resolved[id] = CampaignDebuffs.enemy(_enemies[id], ids)
			var group := BattleSpawnGroup.new()
			group.enemy = resolved[id]
			group.count = int(item.count)
			group.route_index = int(item.route_index)
			group.interval_seconds = CampaignDebuffs.spacing(float(item.base_interval_seconds), ids)
			count += group.count
			wave.groups.append(group)
		var boss_wave := str(published[i]) == "boss"
		var expected := 1 if boss_wave else int(published[i])
		if expected != count or int(row.queued_count) != count:
			return []
		if boss_wave and (wave.groups.size() != 1 or not wave.groups[0].enemy is BossSpec):
			return []
		waves.append(wave)
	return waves

func _valid_dialogue(rows: Array[Dictionary], noncombat: Dictionary) -> bool:
	var seen := {}
	for scene in rows:
		if seen.has(scene.id) or scene.lines.is_empty():
			return false
		seen[scene.id] = true
		var trigger: Dictionary = scene.trigger
		if not trigger.event in EVENTS:
			return false
		if trigger.has("presentation_event_id") and not noncombat.has(trigger.presentation_event_id):
			return false
		for line in scene.lines:
			var speaker: Dictionary = speakers.get(line.speaker_id, {})
			if not line.pose_key in speaker.get("pose_keys", []) or line.text.strip_edges().is_empty():
				return false
	return true

func _fail(reason: String) -> StoryOperation:
	error = reason
	return null

static func _optional_id(value: Variant) -> StringName:
	return StringName(value) if value is String else &""

static func _read_json(path: String) -> Dictionary:
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return decoded if decoded is Dictionary else {}
