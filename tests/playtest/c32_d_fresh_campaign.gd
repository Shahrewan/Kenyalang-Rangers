extends "res://tests/playtest/c30_campaign_playtest.gd"
## One real Campaign save. Only successful battles and earned Funds carry forward.

const CONTROL := HeadquartersCatalog.CONTROL
const HR := HeadquartersCatalog.HR
const MECHANICAL := HeadquartersCatalog.MECHANICAL
const CRISIS := &"room.r_d_crisis"
const ECO := &"room.r_d_eco"
const COMBAT := &"room.r_d_combat"
const OPENINGS := {
	&"C1-01": [[POST, Vector2i(1, 0), 0], [SCOUT, Vector2i(5, 2), 1200], [PATROL, Vector2i(6, 3), 1800]],
	&"C1-02": [[POST, Vector2i(1, 0), 0], [SCOUT, Vector2i(5, 2), 1], [PATROL, Vector2i(6, 3), 1], [SCOUT, Vector2i(6, 2), 1],
		[PATROL, Vector2i(9, 3), 1], [SCOUT, Vector2i(8, 2), 1]],
	&"C1-03": [[POST, Vector2i(1, 0), 0], [SCOUT, Vector2i(5, 2), 1], [PATROL, Vector2i(6, 3), 1], [MEDIC, Vector2i(6, 2), 1],
		[SONIC, Vector2i(5, 0), 1], [SCOUT, Vector2i(1, 2), 1], [PATROL, Vector2i(9, 3), 1], [SCOUT, Vector2i(8, 2), 1]],
}

var _shop_log: Array[Dictionary] = []
var _campaign_funds := 0
var _purchased := 0

func _run() -> void:
	var progress := CampaignProgress.new(_path)
	var success := _content.error.is_empty() and progress.set_leader_name("Fresh Campaign QA")
	var completed := 0
	var returning := {}
	for operation: StoryOperation in _content.operations:
		if not success:
			break
		var id := operation.stage.stage_id
		success = _prepare(operation, progress)
		if not success:
			printerr("FAIL required HQ gate before %s with %d Funds" % [id, progress.funds()])
			break
		_tactical = true
		_expanded = id not in [&"C2-05", &"C2-10"]
		_late_policy = "heat" if id == &"C2-08" else ("convoy" if id == &"C2-09" else "")
		_trial_buffs.assign([&"B02", &"B07"] if id == &"C2-08" else ([&"B05", &"B07"] if id == &"C2-09" else []))
		var plan := _select_plan(operation, progress, not OPENINGS.has(id))
		var previous_owned: Array = progress.snapshot().owned
		var before := progress.funds()
		var result := _fight(operation, plan, progress, not OPENINGS.has(id), OPENINGS.get(id, []).duplicate(true))
		result["starting_wallet"] = before
		result["wallet"] = progress.funds()
		result["purchases"] = _shop_log.duplicate()
		result["owned_levels"] = progress.snapshot().deployable_levels
		result["new_recruits"] = progress.snapshot().owned.filter(func(key: String) -> bool: return key not in previous_owned)
		_shop_log.clear()
		print("FRESH ", JSON.stringify(result))
		success = result.legal_plan and result.settled and result.outcome == BattleSimulation.Outcome.WON
		if success:
			_campaign_funds += result.funds_credited
			completed += 1
			progress = CampaignProgress.new(_path)
			if id == &"C2-07":
				returning = progress.snapshot()
				returning.owned.erase(String(FIREBREAK))
			success = (progress.load_status == CampaignProgress.LoadStatus.READY and progress.record_for(id).get("cleared", false)
				and progress.funds() == result.wallet and progress.snapshot().pending_attempt.is_empty())
		else:
			printerr("FAIL genuine clear stalled at " + String(id))
	success = (success and completed == 15 and progress.owns(FIREBREAK) and progress.deployable_level(FIREBREAK) == 20
		and progress.deployable_level(POST) == 30 and progress.deployable_level(SCOUT) == 80
		and progress.deployable_level(GUARD) == 80 and progress.deployable_level(PATROL) == 40
		and progress.owns(STRIKE) and progress.funds() == 10000 + _campaign_funds - _purchased)
	print("FINISH ", JSON.stringify({"clears": completed, "campaign_funds": _campaign_funds,
		"spent": _purchased, "balance": progress.funds(), "verified": success}))
	if success:
		success = _returning_replay(returning)
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	quit(0 if success else 1)

func _returning_replay(snapshot: Dictionary) -> bool:
	# Clone actual progress with the ownership gap from a pre-activation save.
	if not ProfileFile.replace(_path, snapshot, false):
		return false
	var progress := CampaignProgress.new(_path)
	var operation := _content.operation(&"C2-07")
	_expanded = true
	_late_policy = ""
	_trial_buffs.clear()
	var plan := _select_plan(operation, progress, true)
	var balance := progress.funds()
	var result := _fight(operation, plan, progress, true)
	var verified: bool = (result.settled and result.funds_credited == 6500 and progress.owns(FIREBREAK)
		and progress.record_for(&"C2-07").perfect and progress.funds() == balance + 6500)
	result["verified"] = verified
	print("RETURNING ", JSON.stringify(result))
	return verified

func _prepare(operation: StoryOperation, progress: CampaignProgress) -> bool:
	var id := operation.stage.stage_id
	if not _room(progress, CONTROL, operation.min_control_level):
		return false
	match id:
		&"C1-02":
			return _room(progress, MECHANICAL, 1)
		&"C1-04":
			return _room(progress, HR, 2)
		&"C2-01":
			_room(progress, CRISIS, 3)
			_room(progress, COMBAT, 2)
			_room(progress, HR, 3)
		&"C2-02":
			_room(progress, HR, 3)
			_room(progress, MECHANICAL, 3)
			_level(progress, POST, 30)
		&"C2-04":
			_room(progress, HR, 4)
			_level(progress, SCOUT, 20)
		&"C2-07":
			_room(progress, ECO, 3)
			_room(progress, COMBAT, 4)
		&"C2-08":
			_level(progress, FIREBREAK, 20)
		&"C2-10":
			_level(progress, SCOUT, 80)
			_level(progress, GUARD, 80)
			_level(progress, PATROL, 40)
	return true

func _room(progress: CampaignProgress, id: StringName, target: int) -> bool:
	while progress.room_level(id) < target:
		var quote := progress.room_quote(id)
		if not progress.purchase_room(id).is_empty():
			return false
		_track_purchase(id, quote)
	return true

func _level(progress: CampaignProgress, id: StringName, target: int) -> void:
	var quote := progress.level_quote(id, target)
	if progress.purchase_levels(id, target).is_empty():
		_track_purchase(id, quote)

func _track_purchase(id: StringName, quote: Dictionary) -> void:
	_purchased += quote.cost
	_shop_log.append({"id": id, "target": quote.target, "paid": quote.cost, "remaining": quote.balance})
