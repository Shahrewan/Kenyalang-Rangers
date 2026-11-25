extends SceneTree
## Run identical genuine battles through the legacy study score and the live score.

const CASE := preload("res://tests/balance/chaos_payout_case.gd")
const CROWD := &"ranger.crowd_controller"
const SONIC := &"facility.sonic_turret"
const BEACON := &"facility.firebreak_beacon"

var _path := "user://c32-e-challenges-%d.json" % OS.get_process_id()
var _content := CampaignContent.new()
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for schedule: Array in [[2, 1], [50, 50, 50, 50, 50]]:
		_compare({"route": "T01", "waves": schedule}, CASE.play(_profile(), _content, schedule, false),
			CASE.play(_profile(), _content, schedule))
	_mulu()
	_imbak()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C32-E Chaos challenges: %d failures" % _failures)
	quit(0 if _failures == 0 else 1)

func _mulu() -> void:
	var waves := [{"E02": 8, "E08": 6}, {"E01": 9, "E03": 6}]
	var roster: Array[StringName] = [CASE.GUARD, CASE.SCOUT, CROWD, CASE.MEDIC, CASE.POST]
	var modifiers: Array[StringName] = [&"B05", &"D05", &"D07", &"D11", &"D12", &"D13", &"D15"]
	var orders := [
		[CASE.GUARD, Vector2i(5, 1)], [CASE.SCOUT, Vector2i(4, 2)], [CROWD, Vector2i(3, 2)],
		[CASE.MEDIC, Vector2i(7, 3)], [CASE.GUARD, Vector2i(7, 2)], [CASE.SCOUT, Vector2i(8, 1)],
		[CROWD, Vector2i(8, 3)],
	]
	_run_configuration(&"T02", waves, roster, modifiers, orders)

func _imbak() -> void:
	var waves := [{"E01": 12, "E02": 6}, {"E02": 8, "E14": 5}]
	var roster: Array[StringName] = [CASE.GUARD, CASE.SCOUT, CASE.POST, SONIC, BEACON]
	var modifiers: Array[StringName] = [&"B02", &"B13", &"D01", &"D02", &"D03", &"D14"]
	var orders := [
		[CASE.POST, Vector2i(1, 0)], [CASE.GUARD, Vector2i(3, 1)], [CASE.SCOUT, Vector2i(1, 2)],
		[CASE.SCOUT, Vector2i(2, 2)], [CASE.GUARD, Vector2i(6, 1)], [BEACON, Vector2i(5, 0)],
		[CASE.POST, Vector2i(10, 4)], [SONIC, Vector2i(5, 2)], [CASE.SCOUT, Vector2i(8, 0)],
	]
	_run_configuration(&"T05", waves, roster, modifiers, orders)

func _run_configuration(route: StringName, waves: Array, roster: Array[StringName], modifiers: Array[StringName], orders: Array) -> void:
	var config := ChaosConfiguration.new()
	config.select_route(route)
	for i in waves.size():
		for id: String in waves[i]:
			config.set_quantity(i, StringName(id), waves[i][id])
	var before := CASE.play_configuration(_profile(), _content, config, roster, modifiers, orders.duplicate(true), false)
	var after := CASE.play_configuration(_profile(), _content, config, roster, modifiers, orders.duplicate(true))
	_compare({"route": route, "waves": waves, "modifiers": modifiers, "roster": roster}, before, after)

func _compare(recipe: Dictionary, before: Dictionary, after: Dictionary) -> void:
	_check(before.get("qualifies", false) and after.get("qualifies", false)
		and before.get("ticks") == after.get("ticks") and before.get("defeated") == after.get("defeated")
		and after.get("escapes") == 0 and after.get("credited", 0) > 0, "Genuine qualifying runs for " + recipe.route)
	_check(after.get("score", 0) <= before.get("score", -1) and after.get("credited", 0) <= before.get("credited", -1),
		"Effective score and Funds reconcile with the legacy recipe")
	print("CHALLENGE ", JSON.stringify({"recipe": recipe, "legacy_score": before, "live_score": after}))

func _profile() -> CampaignProgress:
	var data := CampaignSave.fresh()
	data.leader_name = "Chaos QA"
	data.rooms["room.human_resources"] = 5
	data.rooms["room.mechanical"] = 5
	data.rooms["room.r_d_combat"] = 2
	data.rooms["room.r_d_crisis"] = 3
	data.rooms["room.r_d_eco"] = 3
	for spec: DeploymentSpec in DeployableLevels.catalog(true) + DeployableLevels.catalog(false):
		var id := String(spec.id)
		if id not in data.owned and (spec is RangerSpec or spec.chaos_threshold == 0):
			data.owned.append(id)
		if id in data.owned:
			data.deployable_levels[id] = 100
	_check(ProfileFile.replace(_path, data, false), "Write an independent progressed loadout")
	return CampaignProgress.new(_path)

func _check(ok: bool, detail: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL ", detail)
