extends SceneTree

const CAMPAIGN_MAP := &"C2-07"
const ACTIVE := &"Active"
var _content := CampaignContent.new()
var _catalog := CampaignVisualAssets.new()
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_check(not _content.operations.is_empty(), "Campaign loads")
	_check_registrations()
	for spec: DeploymentSpec in _content.roster.entries:
		if spec is FacilitySpec:
			_facility(spec)
		else:
			_ranger(spec)
	print("Campaign visual bindings: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check_registrations() -> void:
	for id: String in _catalog.registration.maps:
		var map := _catalog.region(id)
		var paths: Array = [map.backdrop.texture, map.planning_thumbnail.texture, map.atlas.junction_override.texture]
		for row: Dictionary in map.entries + map.exit.layers:
			paths.append(row.texture)
		_check(paths.all(func(path: String) -> bool: return _catalog.texture(path) != null),
			id + " loads its full backdrop, thumbnail, entry, junction and occlusion stack")
	for effect: String in _catalog.registration.effects:
		_check(_catalog.effect(effect) != null, "Loads W29 effect " + effect)
	_check(_catalog.rig(_catalog.actor(&"companion.k9_ranger.dog")) != null,
		"The approved K9 companion resource is packaged")
	_check(_catalog.load_art(_catalog.catalog.heat_meter, "PackedScene") != null, "Loads the Heat HUD scene")
	for id: String in _catalog.registration.facilities:
		var facility := _catalog.facility_layout(id)
		_check(facility.ghost.parts.all(func(part: Array) -> bool: return _catalog.texture(part[0]) != null),
			id + " loads every uniformly registered preview part")

func _make_board() -> BattleBoard:
	var stage := _content.operation(CAMPAIGN_MAP).stage
	var board := BattleBoard.new()
	board.battle_map = stage.map
	board.battle = BattleSimulation.new(stage)
	board.deployments = DeploymentState.new(stage.map, board.battle.clock, 1000)
	board.battle.deployment = board.deployments
	board.size = Vector2(960, 400)
	root.add_child(board)
	board.illustrate_first_contact(FirstContactSkin.new(), stage.stage_id)
	return board

func _placement(board: BattleBoard, spec: DeploymentSpec) -> Vector2i:
	var options := board.battle_map.ground if spec.uses_ground() else board.battle_map.elevated
	for cell: Vector2i in options:
		if board.deployments.placement_error(spec, cell).is_empty():
			return cell
	return DeploymentState.NO_CELL

func _facility(spec: FacilitySpec) -> void:
	var board := _make_board()
	var sim := board.battle
	var art := board.first_contact_field
	var at := _placement(board, spec)
	var asset := _catalog.facility(spec.id)
	var label := spec.label
	_check(at != DeploymentState.NO_CELL and board.deployments.deploy(spec, at, -1).is_empty(),
		label + " uses its actual footprint and placement rules")
	var id := board.deployments.interaction_id(at)
	var turret: FirstContactField.Turret = art.turrets.get(id)
	_check(turret != null and turret.rig.scene_file_path == asset.rig and _catalog.badge(spec.id) != null,
		label + " binds its unique W29 scene and badge")
	if turret == null:
		board.free()
		return
	_check(asset.footprint.size() == spec.footprint(at).size() and asset.reserved.size() == spec.reserved(at).size(),
		label + " keeps registered occupancy")
	var states: Array = asset.states
	_check(states.all(func(state: String) -> bool: return turret.player.has_animation(state)), label + " has every approved state")
	var building := board.deployments.build_ticks_left(id)
	_check(turret.clip == (&"Construction" if building > 0 else &"Ready"), label + " starts with the real build state")
	if building > 0:
		board.deployments.receive_hit(id, 1, EnemyAttackProfile.Kind.SIEGE)
		_check(turret.clip == &"ConstructionUnderSiege", label + " shows construction damage")
	for tick in building:
		sim.clock.advance_frame()
	# A late Siege hit at the deadline must finish its feedback before returning to Ready.
	for tick in 50:
		sim.clock.advance_frame()
	_check(turret.clip == &"Ready", label + " shows live Ready after its build deadline")
	sim.facility_combat.action_presented.emit(turret.unit, Vector2(at), "repair")
	_check(turret.clip == ACTIVE, label + " samples the approved Active pose")
	var phase := turret.phase
	sim.clock.paused = true
	sim.clock.set_speed(2)
	sim.clock.advance_frame()
	_check(turret.phase == phase, label + " art freezes with the shared clock")
	sim.clock.paused = false
	sim.clock.advance_frame()
	_check(is_equal_approx(turret.phase, phase + CombatClock.STEP_SECONDS * 2), label + " art samples two fixed steps at 2×")
	if spec.role == FacilitySpec.Role.SENTRY_TOWER:
		var scout := DeployableLevels.definition(&"ranger.scout_sniper")
		_check(board.deployments.deploy(scout, at, 1).is_empty() and art.rangers[scout.id].unit.mount_tower == id
			and turret.rig.has_node("MountSocket"), "Tower preserves the actual roof mount and upper reservation")
	board.deployments.receive_hit(id, 1, EnemyAttackProfile.Kind.SIEGE)
	_check(turret.clip == &"UnderSiege", label + " shows ready-state Siege damage")
	board.deployments.receive_hit(id, spec.max_hp, EnemyAttackProfile.Kind.SIEGE)
	_check(turret.clip == &"Destroyed" and not board.deployments.placed.has(id), label + " plays destruction after releasing cells")
	board.free()

func _ranger(spec: DeploymentSpec) -> void:
	var board := _make_board()
	var art := board.first_contact_field
	var at := _placement(board, spec)
	_check(board.deployments.deploy(spec, at, -1).is_empty(), spec.label + " deploys through the existing grid")
	var actor: FirstContactField.Actor = art.rangers.get(spec.id)
	_check(actor != null and actor.rig.scene_file_path == _catalog.actor(spec.id).rig and actor.clip == &"Deploy"
		and _catalog.badge(spec.id) != null, spec.label + " uses its unique rig, badge and Deploy animation")
	if actor != null:
		_check(actor.unit.facing == -1 and actor.rig.facing_locked == spec.is_melee(),
			spec.label + " art follows selected facing and the existing melee lock")
		var phase := actor.phase
		board.battle.clock.dialogue_open = true
		board.battle.clock.advance_frame()
		_check(actor.phase == phase, spec.label + " Deploy pose holds during dialogue")
		board.battle.clock.dialogue_open = false
		if actor.unit.arrival_tick > 0:
			for tick in actor.unit.arrival_tick - board.battle.clock.tick:
				board.battle.clock.advance_frame()
			_check(actor.clip == &"Deploy" and actor.unit.arrival_tick == 0, spec.label + " plays the approved arrival pose after the combat delay")
		if spec.id == &"ranger.k9_ranger":
			_check(actor.companion != null and actor.companion.get_parent() == actor.facing
				and actor.companion.position == Vector2(26, 0) and actor.howl_socket != null,
				"K9 companion attaches to the mirrored parent at its registered offset")
		board.deployments.receive_hit(spec.id, 1, EnemyAttackProfile.Kind.RANGED)
		_check(actor.clip == &"Hit", spec.label + " animates accepted damage")
		board.deployments.retreat(spec.id)
		_check(actor.clip == &"Retreat" and actor.terminal, spec.label + " animates retreat after removal")
		if actor.companion != null:
			_check(actor.companion.player.assigned_animation == &"Move", "K9 companion plays its approved withdrawal clip")
	board.free()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
