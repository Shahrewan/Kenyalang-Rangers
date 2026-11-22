class_name CampaignSave
extends RefCounted

const VERSION := 2
const STARTING_FUNDS := 10000
const MAX_EXACT_INTEGER := 9007199254740991
const HEADQUARTERS := preload("res://data/headquarters/rooms.tres")

static func fresh() -> Dictionary:
	return {
		"version": VERSION, "leader_name": "", "funds": STARTING_FUNDS,
		"rooms": HEADQUARTERS.starting_levels(), "finance": 0.0, "deployable_levels": {},
		"records": {}, "owned": CampaignContent.STARTERS.map(func(id: StringName) -> String: return String(id)),
		"pending_attempt": "",
		"outreach": CampaignActivities.new_outreach(),
		"encyclopaedia": CampaignActivities.new_encyclopaedia(),
		"garden": CampaignActivities.new_garden(),
		"chaos": {"personal_best": 0, "earned_thresholds": []},
	}

static func load_data(raw: Dictionary) -> Dictionary:
	var version: Variant = raw.get("version")
	if version != 1 and version != VERSION:
		return {}
	if not _valid_common(raw):
		return {}
	var data := raw.duplicate(true)
	if version == 1:
		data = _migrate_v1(raw)
	if data.is_empty() or not _valid_v2(data):
		return {}
	data.version = VERSION
	data.funds = int(data.funds)
	data.leader_name = data.leader_name.strip_edges().substr(0, 24)
	return data

static func _migrate_v1(raw: Dictionary) -> Dictionary:
	if not ProfileFile.whole_between(raw.get("control"), 1, HeadquartersCatalog.MAX_LEVEL) or not raw.get("mechanical") is bool:
		return {}
	var data := fresh()
	for key in ["leader_name", "funds", "finance", "records", "owned", "pending_attempt"]:
		data[key] = raw[key].duplicate(true) if raw[key] is Array or raw[key] is Dictionary else raw[key]
	data.rooms[String(HeadquartersCatalog.CONTROL)] = int(raw.control)
	data.rooms[String(HeadquartersCatalog.MECHANICAL)] = 1 if raw.mechanical else 0
	return data

static func _valid_common(data: Dictionary) -> bool:
	if not ProfileFile.whole_between(data.get("funds"), 0, FundsWallet.CAP) or not data.get("leader_name") is String or not data.get("pending_attempt") is String:
		return false
	if not data.get("records") is Dictionary or not ProfileFile.unique_ids(data.get("owned")):
		return false
	if not data.has("finance"):
		return false
	for id: String in data.records:
		var record: Variant = data.records[id]
		if id.is_empty() or not record is Dictionary or not record.get("cleared") is bool or not record.cleared or not record.get("perfect") is bool:
			return false
	return true

static func _valid_v2(data: Dictionary) -> bool:
	if not data.get("rooms") is Dictionary or data.rooms.size() != HEADQUARTERS.rooms.size():
		return false
	for room: HeadquartersRoom in HEADQUARTERS.rooms:
		var minimum := 1 if room.starts_built() else 0
		if not ProfileFile.whole_between(data.rooms.get(String(room.id)), minimum, HeadquartersCatalog.MAX_LEVEL):
			return false
	var finance: Variant = data.get("finance")
	var finance_room: HeadquartersRoom = HEADQUARTERS.room(HeadquartersCatalog.FINANCE)
	if (not finance is float and not finance is int) or not is_finite(float(finance)) or finance < 0 or finance > finance_room.storage(data.rooms[String(finance_room.id)]):
		return false
	if not data.get("deployable_levels") is Dictionary:
		return false
	for id: String in data.deployable_levels:
		if id not in data.owned or DeployableLevels.definition(StringName(id)) == null or not ProfileFile.whole_between(data.deployable_levels[id], 1, DeployableLevels.MAX_LEVEL):
			return false
	var records: HeadquartersRoom = HEADQUARTERS.room(HeadquartersCatalog.RECORDS)
	var ecology: HeadquartersRoom = HEADQUARTERS.room(HeadquartersCatalog.ECOLOGY)
	var chaos: Variant = data.get("chaos")
	return CampaignActivities.valid_outreach(data.get("outreach")) \
		and CampaignActivities.valid_encyclopaedia(data.get("encyclopaedia"), records.unlocks(data.rooms[String(records.id)])) \
		and CampaignActivities.valid_garden(data.get("garden"), ecology.capacity(data.rooms[String(ecology.id)])) \
		and chaos is Dictionary and ProfileFile.whole_between(chaos.get("personal_best"), 0, MAX_EXACT_INTEGER) and ProfileFile.unique_ids(chaos.get("earned_thresholds"))
