class_name ChapterOneCoach
extends RefCounted

const POST := &"facility.logistics_post"
const SCOUT := &"ranger.scout_sniper"
const PATROL := &"ranger.patrolman"
const MEDIC := &"ranger.combat_medic"

var cells: Array[Vector2i] = []
var _battle: BattleSimulation
var _stage: BattleStage
var _offered: Dictionary[StringName, DeploymentSpec] = {}
var _rest_end := 0

func _init(battle: BattleSimulation, stage: BattleStage, entries: Array[DeploymentSpec]) -> void:
	_battle = battle
	_stage = stage
	for spec in entries:
		_offered[spec.id] = spec

func rest_started(completed: int) -> void:
	if completed < _battle.wave_count:
		_rest_end = _battle.clock.tick + CombatClock.ticks_for(_stage.waves[completed - 1].rest_after_seconds)

func prompt(dragging: DeploymentSpec, choosing_facing: bool) -> String:
	cells.clear()
	if choosing_facing:
		return "Choose the side the enemy is coming from. Check the arrow and tap Deploy."
	if dragging != null and _stage.stage_id != &"C1-01":
		if dragging.logistics_post:
			if _battle.deployment.posts_deployed == 0:
				return "Place on two raised tiles side by side. The first Post is free and instant."
			return "Place on two raised tiles side by side. A repeat Post costs Tokens and takes time to build."
		if dragging.kind == DeploymentSpec.Kind.GROUND_PAIR:
			return "Cover two ground tiles side by side, then choose which way to face."
		if dragging.is_melee():
			return "Place on the path, then choose which way to face."
		if dragging.kind == DeploymentSpec.Kind.ELEVATED:
			return "Use a raised tile. Check that the tinted range covers your target area."
		if dragging.kind == DeploymentSpec.Kind.FACILITY_PAIR:
			return "Cover two raised tiles side by side. A Facility starts working when construction finishes."
	if _stage.stage_id == &"C1-01":
		if _battle.deployment.posts_deployed == 0:
			return _placement(POST, Vector2i(1, 0), "1 · Tap the Logistics Post marked Free, then the left gold tile. You can also drag it there.")
		if not _on_field(SCOUT):
			return _placement(SCOUT, Vector2i(5, 2), "2 · Tap Scout Sniper, then the marked raised tile by the bend.")
		if not _on_field(PATROL):
			return _placement(PATROL, Vector2i(6, 3), "3 · Tap Patrolman, then the marked path tile. Choose Face left, then Deploy.")
	elif _battle.deployment.posts_deployed == 0 and _offered.has(POST) and not _battle.deployment.rules.fixed_stockpile:
		return _placement(POST, Vector2i(1, 0), "Place your free first Logistics Post across two raised tiles to earn Tokens.")
	if _stage.stage_id == &"C1-03":
		if not _battle.deployment.armed.is_empty():
			return "Choose an eligible highlighted tile and tap Confirm skill. Cancel keeps the charge."
		for unit: DeploymentState.Placement in _battle.deployment.placed.values():
			if unit.skill_charges <= 0 or unit.spec.skill == DeploymentSpec.Skill.NONE:
				continue
			var skill := BattleSkillStatus.read(unit, _battle.deployment)
			if skill != null and skill.mode == BattleSkillStatus.Mode.READY:
				return "%s is ready. Use a quick tap and Confirm the target if asked." % unit.spec.label
		if _on_field(SCOUT) or _on_field(PATROL):
			if _can_guide_to(MEDIC, Vector2i(6, 2)):
				cells.assign([Vector2i(6, 2)])
				return "Place Combat Medic on the marked raised tile. Hold a Ranger to show Retreat."
			return "Hold a Ranger for Retreat. Check the tray cooldown before placing a replacement."
	if _stage.stage_id == &"C1-05" and not _battle.active.is_empty():
		for enemy: BattleEnemy in _battle.active.values():
			if enemy.boss != null:
				return "Stop the Captain before the tunnel. Keep coverage at the entry for reinforcements."
	if _stage.stage_id in [&"C1-02", &"C1-04", &"C1-05"]:
		var formation := _formation()
		if not formation.is_empty():
			return formation
	if _rest_end > _battle.clock.tick:
		var seconds := ceili(float(_rest_end - _battle.clock.tick) / CombatClock.TICKS_PER_SECOND)
		return "Next wave in %ds · Check HP, placement cooldowns and the next wave in Pause." % seconds
	match _stage.stage_id:
		&"C1-01":
			return "Rangers attack automatically. Check their HP and keep enemies away from the wooded exit."
		&"C1-02":
			if _battle.escaped > 0:
				return "An escape cost Integrity. Cover the path again. Positive Integrity can still earn a clear."
			return "Hold the route with Patrolman and cover his position with Scout. Tap Pause for Enemy Intel."
		&"C1-03":
			return "Deploy a blocker and put Combat Medic on a raised tile covering the blocker."
		&"C1-04":
			return "Cover the path with overlapping damage and healing. Pause to inspect Rifle Spotters and Shield Carriers."
		&"C1-05":
			return "Fixed Stockpile · Place a blocker and cover it with ranged damage. Save Tokens for the Captain."
	return ""

func _formation() -> String:
	if _can_guide_to(PATROL, Vector2i(6, 3)):
		cells.assign([Vector2i(6, 3)])
		return "Place Patrolman on the marked path tile. Choose Face left and tap Deploy."
	if _can_guide_to(SCOUT, Vector2i(5, 2)):
		cells.assign([Vector2i(5, 2)])
		return "Place Scout on the marked raised tile so its range covers this bend."
	if _stage.stage_id == &"C1-04" and _can_guide_to(MEDIC, Vector2i(6, 2)):
		cells.assign([Vector2i(6, 2)])
		return "Place Combat Medic on the marked raised tile to heal nearby Rangers."
	return ""

func _can_guide_to(id: StringName, anchor: Vector2i) -> bool:
	var spec := _offered.get(id) as DeploymentSpec
	return spec != null and not _on_field(id) and _battle.deployment.placement_error(spec, anchor).is_empty()

func _on_field(id: StringName) -> bool:
	for unit: DeploymentState.Placement in _battle.deployment.placed.values():
		if unit.spec.id == id:
			return true
	return false

func _placement(id: StringName, anchor: Vector2i, instruction: String) -> String:
	var deployment := _battle.deployment
	var spec := _offered.get(id) as DeploymentSpec
	if spec == null:
		return instruction
	var cost := deployment.cost_for(spec)
	if cost > deployment.tokens:
		return "Save %d Tokens for %s. The Post pays automatically. You have %d." % [cost, spec.label, deployment.tokens]
	if deployment.cooldown_ticks(id) > 0:
		return "Wait for the %s card’s cooldown before placing a replacement." % spec.label
	if deployment.placement_error(spec, anchor).is_empty():
		cells.assign(spec.footprint(anchor))
		return instruction
	if spec.kind == DeploymentSpec.Kind.FACILITY_PAIR:
		return "Place %s on two free raised tiles side by side." % spec.label
	return "Place %s on a free %s." % [spec.label, "ground tile" if spec.uses_ground() else "raised tile"]
