class_name OutreachSession
extends RefCounted

var _profile: CampaignProgress
var _catalog: EducationCatalog
var _rng: RandomNumberGenerator

func _init(profile: CampaignProgress, catalog: EducationCatalog, rng: RandomNumberGenerator = null) -> void:
	_profile = profile
	_catalog = catalog
	_rng = rng
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()

func batch() -> Dictionary:
	return _profile.outreach_state()

func matches_bank(state: Dictionary) -> bool:
	return (
		int(state.get("bank_revision", 0)) == _catalog.outreach_revision and _catalog.outreach_revision > 0
		and state.rotation.size() == _catalog.outreach.size() and state.rotation.all(func(id: String) -> bool: return _catalog.outreach.has(id))
	)

func seconds_until_refresh(now: int) -> int:
	var last := int(batch().refreshed_at)
	return 0 if last == 0 else maxi(0, last + CampaignActivities.OUTREACH_INTERVAL - now)

func refresh(now: int) -> bool:
	if _catalog.outreach.is_empty() or _profile.room_level(HeadquartersCatalog.OUTREACH) == 0 or now <= 0:
		return false
	var current := batch()
	if current.refreshed_at > 0 and now - int(current.refreshed_at) < CampaignActivities.OUTREACH_INTERVAL:
		return true
	var rotation: Array = current.rotation
	var cursor := 0
	if matches_bank(current) and not current.batch.is_empty():
		cursor = rotation.find(current.batch.back()) + 1
	if cursor == 0 or cursor >= rotation.size():
		rotation = _catalog.outreach.keys()
		_shuffle(rotation)
		cursor = 0
	var prompts := rotation.slice(cursor, cursor + 5)
	var orders := {}
	for id: String in prompts:
		var order := [0, 1, 2, 3]
		_shuffle(order)
		orders[id] = order
	return _profile.open_outreach_batch(rotation, prompts, orders, now, _catalog.outreach_revision)

func submit(question_id: String, display_index: int, now: int) -> Dictionary:
	var state := batch()
	if not matches_bank(state) or not question_id in state.batch or display_index < 0 or display_index > 3:
		return {}
	if now >= int(state.refreshed_at) + CampaignActivities.OUTREACH_INTERVAL:
		return {}
	var authored_index: int = int(state.choice_order[question_id][display_index])
	var choice: Dictionary = _catalog.outreach[question_id].choices[authored_index]
	return _profile.record_outreach_response(question_id, display_index, StringName(choice.grade))

func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var item: Variant = items[i]
		items[i] = items[j]
		items[j] = item
