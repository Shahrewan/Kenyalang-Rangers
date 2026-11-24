extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const K9 := &"ranger.k9_ranger"
const SEER := &"ranger.kenyalang_seer"
const TRACKER := &"ranger.woods_tracker"
const SABOTEUR := &"ranger.saboteurist"
const STRIKE := &"ranger.strike_team"
const POST := &"facility.logistics_post"
const LOADOUT := [K9, SEER, TRACKER, SABOTEUR, STRIKE, POST]

var _save := "user://c31b-capture-%d.json" % OS.get_process_id()
var _destination: String
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3 or DisplayServer.get_name() == "headless":
		quit(1)
		return
	_destination = args[0]
	var frame := args[1].split("x")
	root.size = Vector2i(frame[0].to_int(), frame[1].to_int())
	DirAccess.make_dir_recursive_absolute(_destination)
	_seed_profile()
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _save
	root.add_child(app)
	app.set_process(false)
	app.presentation.values.text = args[2].to_int()
	app._restyle()
	await _story(app)
	await _chaos(app)
	app.free()
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C31-B native captures: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _seed_profile() -> void:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.rooms["room.control_room"] = 5
	profile.rooms["room.human_resources"] = 5
	profile.rooms["room.mechanical"] = 3
	profile.rooms["room.r_d_crisis"] = 3
	profile.deployable_levels[String(POST)] = 30
	for operation: StoryOperation in CampaignContent.new().operations:
		if operation.stage.stage_id == &"C2-08":
			break
		profile.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in operation.clear_unlock_ids:
			profile.owned.append(String(id))
	ProfileFile.replace(_save, profile, false)

func _story(app) -> void:
	app._screen.get_node("%OpenCampaign").pressed.emit()
	app._screen.find_child("Operation_C2_08", true, false).pressed.emit()
	app._draft.configure_campaign(app._campaign_progress, LOADOUT)
	app._draft.set_modifier(BattleModifiers.CATALOG.definition(&"B13"), true)
	app._start_campaign()
	var field := app._screen as CampaignBattle
	_check(field != null and field.stage.stage_id == &"C2-08", "Actual Story route loads C2-08")
	if field == null:
		return
	field.set_physics_process(false)
	_advance(field, 0)
	_check(field.operation_plan.selected_count(true) == 5, "Story uses the real five unlocked Ranger selections")
	_first_legal(field, POST)
	_first_legal(field, K9)
	_first_legal(field, SEER)
	_advance(field, 1210)
	_first_legal(field, TRACKER)
	_advance(field, 1220)
	await _capture("story-tracker")

func _chaos(app) -> void:
	app._campaign_progress.abandon_attempt()
	app.show_menu()
	app._screen.get_node("%OpenChaos").pressed.emit()
	app._screen.find_child("Route_T01", true, false).pressed.emit()
	app._screen.find_child("ConfigureChaos", true, false).pressed.emit()
	var configuration: ChaosConfiguration = app._chaos_configuration
	configuration.set_quantity(0, &"E01", 4)
	configuration.set_quantity(0, &"E06", 4)
	configuration.set_quantity(0, &"E09", 8)
	configuration.set_quantity(1, &"E08", 4)
	app._chaos_plan = app._new_chaos_plan(configuration.build_stage(), "Rainforest Chaos", LOADOUT)
	app._chaos_plan.set_modifier(BattleModifiers.CATALOG.definition(&"B13"), true)
	app._start_chaos(Callable())
	var field := app._screen as ChaosBattle
	_check(field != null and field._board.first_contact_field != null, "Chaos uses live W29 battlefield bindings")
	if field == null:
		return
	field.set_physics_process(false)
	var sim := field.battle
	var art := field._board.first_contact_field
	_deploy(field, POST, Vector2i(1, 0))
	_deploy(field, K9, Vector2i(4, 3))
	_deploy(field, SEER, Vector2i(6, 2))
	_advance(field, 1090)
	_deploy(field, TRACKER, Vector2i(7, 3))
	_advance(field, 1800)
	_deploy(field, SABOTEUR, Vector2i(4, 1))
	_advance(field, 2400)
	_deploy(field, STRIKE, Vector2i(8, 3))
	field._refresh()
	await _capture("chaos-strike-incoming")
	var howl_tick := -1
	while sim.clock.tick < 3000 and sim.clock.is_running():
		if sim.tap_unit(K9):
			howl_tick = sim.clock.tick
			break
		_advance(field, sim.clock.tick + 1)
	_check(howl_tick >= 0 and art.rangers[K9].companion.player.assigned_animation == &"Howl", "Dog plays Howl from real enemy detection")
	_advance(field, maxi(sim.clock.tick + 5, 2520))
	var fired := sim.tap_unit(SEER)
	_check(fired and BattleSkillStatus.read(sim.deployment.placed[SEER], sim.deployment).charges == 0,
		"Seer fires Scan and depletes the real field orb")
	field._refresh()
	await _capture("chaos-k9-seer")
	_check(art.rangers.size() == 5 and not sim.active.is_empty(), "All five articulated Rangers render beside battle enemies")
	var cue := -1
	var scan_frame := sim.clock.tick
	while sim.clock.tick < 4100 and sim.clock.is_running():
		if sim.clock.tick >= scan_frame + 120 and art.rangers[SABOTEUR].clip == &"Skill" and sim.active.values().any(func(enemy: BattleEnemy) -> bool:
			return enemy.definition.technological and enemy.tech_interference_until > sim.clock.tick):
			cue = sim.clock.tick
			break
		_advance(field, sim.clock.tick + 1)
	_check(cue >= 0 and art.rangers[SABOTEUR].unit.interference_radius > 1, "Saboteurist renders a later expanded pulse on an actual Tracking Bot")
	var controller := field.get_node("%DeploymentController")
	controller._show_retreat(SABOTEUR)
	field._refresh()
	await _capture("chaos-saboteur")

func _first_legal(field: BattleScene, id: StringName) -> void:
	var spec := _entry(field, id)
	if spec == null:
		_check(false, String(id) + " is in the accepted loadout")
		return
	var cells := field.stage.map.ground if spec.uses_ground() else field.stage.map.elevated
	for cell in cells:
		if field.battle.deployment.placement_error(spec, cell).is_empty():
			_deploy(field, id, cell)
			return
	_check(false, String(id) + " has an affordable legal placement")

func _entry(field: BattleScene, id: StringName) -> DeploymentSpec:
	for spec: DeploymentSpec in field.operation_plan.deployment_entries():
		if spec.id == id:
			return spec
	return null

func _deploy(field: BattleScene, id: StringName, cell: Vector2i) -> void:
	var error := field.battle.deployment.deploy(_entry(field, id), cell, -1)
	_check(error.is_empty(), "%s deploys at %s · %s" % [id, cell, error])

func _advance(field: BattleScene, tick: int) -> void:
	while field.battle.clock.tick <= tick and not field.battle.clock.stopped:
		while field.battle.clock.dialogue_open:
			field.get_node("%Skip").pressed.emit()
		if field.battle.clock.tick == tick:
			break
		field.battle.clock.advance_frame()
	field._refresh()

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	_check(screenshot.get_size() == root.size and screenshot.save_png(_destination.path_join(name + ".png")) == OK, name + " saved at native resolution")

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", label)
