extends SceneTree
## Fully progressed comparison. Every Chaos clear uses real combat. Outreach
## sensitivities change only the study instance's table, then restore it.

const CHAOS := preload("res://tests/balance/chaos_payout_case.gd")
const PROPOSAL := "res://docs/production/c32/rewards_proposal.json"
const TIME := 1700000000

var _path := "user://c32-d-recurring-%d.json" % OS.get_process_id()
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var proposal := ProfileFile.read(PROPOSAL)
	var content := CampaignContent.new()
	var catalog := EducationCatalog.load_installed()
	var room := CampaignSave.HEADQUARTERS.room(HeadquartersCatalog.OUTREACH)
	var original := room.best_response.duplicate()
	for level in range(3, 6):
		var live := _outreach(catalog, level)
		room.best_response = PackedInt32Array(proposal.sensitivity_only.outreach_best_by_level)
		var guardrail := _outreach(catalog, level)
		room.best_response = original
		var result := {"level": level, "questions": 5, "refresh_hours": 20, "live": live, "guardrail": guardrail}
		_check(live == 5 * original[level - 1] and guardrail == 5 * int(proposal.sensitivity_only.outreach_best_by_level[level - 1]), "Five graded Best responses reconcile")
		print("OUTREACH ", JSON.stringify(result))
	for schedule: Array in [[2, 1], [50, 50, 50, 50, 50]]:
		var live := CHAOS.play(_profile(), content, schedule, false)
		var guardrail := CHAOS.play(_profile(), content, schedule)
		_check(live.get("qualifies", false) and guardrail.get("qualifies", false) and live.get("ticks") == guardrail.get("ticks")
			and live.get("defeated") == guardrail.get("defeated") and live.get("escapes") == 0,
			"Max-level Rangers defeat every configured enemy in both score calculations")
		print("CHAOS ", JSON.stringify({"waves": schedule, "levels": 100, "live": live, "guardrail": guardrail}))
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C32-D recurring income: %d failures" % _failures)
	quit(0 if _failures == 0 else 1)

func _profile(outreach_level := 5) -> CampaignProgress:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Income QA"
	profile.rooms["room.human_resources"] = 5
	profile.rooms["room.mechanical"] = 5
	profile.rooms["room.outreach"] = outreach_level
	profile.rooms["room.records"] = 5
	profile.encyclopaedia.perfect_chapters = EducationCatalog.CHAPTERS.keys()
	profile.chaos.personal_best = 3500
	profile.chaos.earned_thresholds = ["chaos_tier.1000", "chaos_tier.2000", "chaos_tier.3000"]
	for spec: DeploymentSpec in DeployableLevels.catalog(true) + DeployableLevels.catalog(false):
		var id := String(spec.id)
		if id not in profile.owned:
			profile.owned.append(id)
		profile.deployable_levels[id] = 100
	_check(ProfileFile.replace(_path, profile, false), "Write max-level comparison save")
	var ready := CampaignProgress.new(_path)
	_check(ready.load_status == CampaignProgress.LoadStatus.READY and ready.snapshot().deployable_levels.size() == 25,
		"All Rangers and Facilities load at Lv.100")
	return ready

func _outreach(catalog: EducationCatalog, level: int) -> int:
	var profile := _profile(level)
	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var session := OutreachSession.new(profile, catalog, rng)
	_check(session.refresh(TIME), "Refresh a genuine five-question Outreach batch")
	var batch := session.batch()
	for question: String in batch.batch:
		var best: int = catalog.outreach[question].choices.find_custom(func(choice: Dictionary) -> bool: return choice.grade == "best")
		var receipt := session.submit(question, batch.choice_order[question].find(best), TIME)
		_check(receipt.get("grade") == "best", "The installed question settles its actual Best grade")
	return profile.funds() - CampaignSave.STARTING_FUNDS

func _check(ok: bool, description: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL ", description)
