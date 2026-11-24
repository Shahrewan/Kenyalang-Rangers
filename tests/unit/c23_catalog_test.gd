extends SceneTree

var failures := 0

func _initialize() -> void:
	var content := CampaignContent.new()
	var recruits := {}
	for id: StringName in CampaignContent.STARTERS:
		recruits[id] = true
	for facility in ChaosScore.tier_facilities():
		recruits[facility.id] = true
	var supply := {}
	for op in content.operations:
		for id in op.clear_unlock_ids:
			recruits[id] = true
		for id in op.supply_ids:
			supply[id] = true
		_check(op.stage.enemy_count() > 0 and op.stage.validation_error().is_empty(), "Playable stage resource %s" % op.stage.stage_id)
	_check(content.operations.size() == 15 and content.error.is_empty(), "All 15 Story operations imported")
	for rangers in [true, false]:
		var catalog := DeployableLevels.catalog(rangers)
		_check(catalog.size() == (12 if rangers else 13), "Permanent catalog size, Rangers=%s" % rangers)
		for spec in catalog:
			var reachable := recruits.has(spec.id)
			_check(reachable or supply.has(spec.id), "%s has a permanent or mission supply source" % spec.id)
			if not reachable:
				print("SUPPLY ONLY ", spec.id)
			_check(content.has_combat_kit(spec.id), "%s field kit is in the live roster" % spec.id)
			var total := 0
			var consistent := true
			for level in range(1, 100):
				var cost := DeployableLevels.cost(level, level + 1)
				total += cost
				var next := DeployableLevels.effective(spec, level + 1)
				consistent = consistent and cost > 0 and next.level == level + 1 and next.kind == spec.kind and next.build_seconds == spec.build_seconds
			_check(consistent and total == 1000000, "%s preserves construction and footprint through 99 paid steps" % spec.id)
	quit(1 if failures else 0)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		failures += 1
		push_error(label)
