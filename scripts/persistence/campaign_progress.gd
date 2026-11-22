class_name CampaignProgress
extends RefCounted

const DEFAULT_PATH := "user://campaign_progress.json"
const SCHEMA_VERSION := 1
const STARTING_FUNDS := 10000
const FUNDS_CAP := 9999999
const MECHANICAL_COST := 20000
const CONTROL_UPGRADES := [20000, 80000, 300000, 900000]
const FINANCE_RATE := 2.0
const FINANCE_CAP := 12000
const RANGER_SLOTS := 3
const FACILITY_SLOTS := 2

var _path: String
var _data: Dictionary
var _finance_dirty := false

func _init(path := DEFAULT_PATH) -> void:
	_path = path
	_data = _read(path)
	if _data.is_empty():
		_data = _read(path + ".bak")
	if _data.is_empty():
		_data = {
			"version": SCHEMA_VERSION,
			"leader_name": "",
			"funds": STARTING_FUNDS,
			"control": 1,
			"mechanical": false,
			"finance": 0.0,
			"records": {},
			"owned": CampaignContent.STARTERS.map(func(id: StringName) -> String: return String(id)),
			"pending_attempt": "",
		}

func snapshot() -> Dictionary:
	return _data.duplicate(true)

func set_leader_name(value: String) -> bool:
	var cleaned := value.strip_edges().substr(0, 24)
	if cleaned.is_empty():
		return false
	var next := snapshot()
	next.leader_name = cleaned
	return _commit(next)

func is_visible(operation: StoryOperation) -> bool:
	return _data.control >= operation.min_control_level

func record_for(id: StringName) -> Dictionary:
	var record: Dictionary = _data.records.get(String(id), {})
	return record.duplicate()

func access_error(operation: StoryOperation) -> String:
	if not is_visible(operation):
		return "Requires Control Lv.%d" % operation.min_control_level
	if not operation.prerequisite.is_empty() and not record_for(operation.prerequisite).get("cleared", false):
		return "Clear %s first" % operation.prerequisite
	return ""

func begin_attempt(operation: StoryOperation) -> bool:
	if not access_error(operation).is_empty():
		return false
	var id := String(operation.stage.stage_id)
	if not _data.pending_attempt.is_empty() and _data.pending_attempt != id:
		return false
	var next := snapshot()
	next.pending_attempt = id
	return _commit(next)

func abandon_attempt() -> bool:
	if _data.pending_attempt.is_empty():
		return true
	var next := snapshot()
	next.pending_attempt = ""
	return _commit(next)

func complete(operation: StoryOperation, perfect: bool) -> Dictionary:
	var id := String(operation.stage.stage_id)
	if _data.pending_attempt != id or not access_error(operation).is_empty():
		return {}
	var next := snapshot()
	var previous := record_for(operation.stage.stage_id)
	var first_clear: bool = not previous.get("cleared", false)
	var first_perfect: bool = perfect and not previous.get("perfect", false)
	var awards := {}
	var pending: Array[String] = []
	if first_clear:
		_add_award(operation.rewards, "first_clear_funds", awards, pending)
		if operation.rewards.get("story_completion_reward_present", false):
			_add_award(operation.rewards, "story_completion_funds", awards, pending)
	else:
		_add_award(operation.rewards, "replay_funds", awards, pending)
	if first_perfect:
		_add_award(operation.rewards, "first_perfect_funds", awards, pending)
	var total := 0
	for value: int in awards.values():
		total += value
	var credit := _credit(total)
	next.funds = int(next.funds) + credit.credited
	next.records[id] = {"cleared": true, "perfect": perfect or previous.get("perfect", false)}
	var unlocked: Array[StringName] = []
	for entry in operation.clear_unlock_ids:
		if String(entry) not in next.owned:
			next.owned.append(String(entry))
			unlocked.append(entry)
	next.pending_attempt = ""
	if not _commit(next):
		return {}
	return {
		"first_clear": first_clear, "first_perfect": first_perfect, "awards": awards,
		"pending_awards": pending, "unlocked": unlocked, "credited": credit.credited,
		"discarded": credit.discarded,
	}

func advance_finance(active_seconds: float) -> void:
	if not is_finite(active_seconds) or active_seconds <= 0.0 or _data.finance >= FINANCE_CAP:
		return
	_data.finance = minf(FINANCE_CAP, float(_data.finance) + FINANCE_RATE * active_seconds)
	_finance_dirty = true

func flush_finance() -> bool:
	return not _finance_dirty or _commit(snapshot())

func finance_preview(amount := -1) -> Dictionary:
	var stored := floori(_data.finance)
	return _credit(stored if amount < 0 else mini(amount, stored))

func claim_finance(amount := -1) -> bool:
	var stored := floori(_data.finance)
	var available := stored if amount < 0 else mini(amount, stored)
	if available <= 0:
		return false
	var next := snapshot()
	next.funds = int(next.funds) + _credit(available).credited
	next.finance = float(next.finance) - available
	return _commit(next)

func build_mechanical() -> bool:
	if _data.mechanical or _data.funds < MECHANICAL_COST:
		return false
	var next := snapshot()
	next.funds = int(next.funds) - MECHANICAL_COST
	next.mechanical = true
	return _commit(next)

func control_upgrade_cost() -> int:
	var level := int(_data.control)
	return CONTROL_UPGRADES[level - 1] if level <= CONTROL_UPGRADES.size() else 0

func upgrade_control() -> bool:
	var cost := control_upgrade_cost()
	if cost <= 0 or _data.funds < cost:
		return false
	var next := snapshot()
	next.funds = int(next.funds) - cost
	next.control = int(next.control) + 1
	return _commit(next)

func _credit(amount: int) -> Dictionary:
	var credited := mini(amount, FUNDS_CAP - int(_data.funds))
	return {"credited": credited, "discarded": amount - credited}

func _commit(next: Dictionary) -> bool:
	if not ProfileFile.replace(_path, next, not _read(_path).is_empty()):
		return false
	_data = next
	_finance_dirty = false
	return true

static func _add_award(rewards: Dictionary, key: String, awards: Dictionary, pending: Array[String]) -> void:
	var amount: Variant = rewards.get(key)
	if _whole_in_range(amount, 0, FUNDS_CAP):
		awards[key] = int(amount)
	else:
		pending.append(key)

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary or data.get("version") != SCHEMA_VERSION:
		return {}
	if not _whole_in_range(data.get("funds"), 0, FUNDS_CAP) or not _whole_in_range(data.get("control"), 1, 5):
		return {}
	if not data.get("mechanical") is bool or not data.get("leader_name") is String or not data.get("pending_attempt") is String:
		return {}
	var stored: Variant = data.get("finance")
	if (not stored is float and not stored is int) or not is_finite(float(stored)) or stored < 0 or stored > FINANCE_CAP:
		return {}
	if not data.get("records") is Dictionary or not data.get("owned") is Array:
		return {}
	for id: Variant in data.owned:
		if not id is String or id.is_empty():
			return {}
	for id: String in data.records:
		var record: Variant = data.records[id]
		if not record is Dictionary or record.get("cleared") != true or not record.get("perfect") is bool:
			return {}
	data.leader_name = data.leader_name.strip_edges().substr(0, 24)
	data.funds = int(data.funds)
	data.control = int(data.control)
	return data

static func _whole_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= minimum and value <= maximum and value == floorf(value)
