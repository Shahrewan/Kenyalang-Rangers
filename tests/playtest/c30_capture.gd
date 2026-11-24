extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const GUARD := &"ranger.guard_veteran"
const SCOUT := &"ranger.scout_sniper"
const POST := &"facility.logistics_post"

var _dir: String
var _checks := 0
var _failures := 0
var _save := "user://c30-capture-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3 or DisplayServer.get_name() == "headless":
		printerr("Use the native renderer and pass a destination, width×height and text percent.")
		quit(1)
		return
	_dir = args[0]
	var frame := args[1].split("x")
	root.size = Vector2i(frame[0].to_int(), frame[1].to_int())
	DirAccess.make_dir_recursive_absolute(_dir)
	_seed_profile()
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _save
	root.add_child(app)
	app.set_process(false)
	app.presentation.values.text = args[2].to_int()
	app._restyle()
	_check(app._screen.get_node_or_null("%OpenSample") == null and app._screen.get_node("%OpenChaos").visible,
		"Live home shows Rainforest Chaos and omits the tester entry")
	await _capture("home")
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	var rooms := CampaignProgress.HEADQUARTERS
	app._show_roster(rooms.room(HeadquartersCatalog.HR))
	app._screen.find_child("Unit_guard_veteran", true, false).pressed.emit()
	await _capture("ranger-upgrade")
	app._show_roster(rooms.room(HeadquartersCatalog.MECHANICAL))
	app._screen.find_child("Unit_logistics_post", true, false).pressed.emit()
	await _capture("facility-upgrade")
	app.show_menu()
	app._screen.get_node("%OpenCampaign").pressed.emit()
	app._screen.find_child("Operation_C2_01", true, false).pressed.emit()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	_skip(field)
	var sim := field.battle
	var state := sim.deployment
	var post := _entry(field, POST)
	var guard := _entry(field, GUARD)
	var scout := _entry(field, SCOUT)
	_check(state.deploy(post, Vector2i(1, 0), -1).is_empty(), "First post deploys legally and starts normal income")
	_advance(field, 1200)
	_check(sim.active.is_empty() and state.tokens == 20 and state.deploy(guard, Vector2i(3, 1), -1).is_empty(),
		"Balanced preparation provides two actual Post payouts before the first enemy")
	var controller = field.get_node("%DeploymentController")
	controller._show_retreat(GUARD)
	controller._refresh()
	_check(BattleSkillStatus.read(state.placed[GUARD], state).charges == 4, "Live Guard shows 4/4 Ready")
	await _capture("skill-ready")
	controller._hide_retreat()
	var basic_hit := {"seen": false}
	sim.melee_hit_presented.connect(func(_id: int, _at: Vector2, _lost: int) -> void: basic_hit.seen = true)
	while not basic_hit.seen and sim.clock.tick < 1750:
		_advance(field, sim.clock.tick + 1)
	_check(basic_hit.seen and not field._board._melee_hits.is_empty(), "Actual attack paints measured HP loss")
	await _capture("melee-hit")
	_check(sim.tap_unit(GUARD), "Real Guard skill consumes a charge")
	_advance(field, maxi(sim.clock.tick + 330, 1810))
	_check(state.deploy(scout, Vector2i(3, 2), -1).is_empty(), "Scout uses ordinary later Token income")
	var status := BattleSkillStatus.read(state.placed[GUARD], state)
	_check(status.charges == 3 and status.mode == BattleSkillStatus.Mode.READY and status.progress > 0.0 and status.progress < 1.0,
		"Live Guard shows 3/4 Ready while another charge recovers")
	_check(BattleSkillStatus.read(state.placed[SCOUT], state).mode == BattleSkillStatus.Mode.LOCKED,
		"Live Scout displays its Records-locked skill")
	controller._show_retreat(GUARD)
	controller._refresh()
	await _capture("opening-recharge-and-lock")
	app.free()
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C30 native capture: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _seed_profile() -> void:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.rooms["room.control_room"] = 3
	profile.rooms["room.mechanical"] = 2
	profile.rooms["room.human_resources"] = 3
	for operation: StoryOperation in CampaignContent.new().operations:
		if operation.stage.stage_id == &"C2-01":
			break
		profile.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in operation.clear_unlock_ids:
			profile.owned.append(String(id))
	ProfileFile.replace(_save, profile, false)

func _entry(field: CampaignBattle, id: StringName) -> DeploymentSpec:
	for spec: DeploymentSpec in field.operation_plan.deployment_entries():
		if spec.id == id:
			return spec
	return null

func _advance(field: CampaignBattle, until: int) -> void:
	while field.battle.clock.tick < until and not field.battle.clock.stopped:
		_skip(field)
		field.battle.clock.advance_frame()
	field._refresh()

func _skip(field: CampaignBattle) -> void:
	while field.battle.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	_check(frame.get_size() == root.size and frame.save_png(_dir.path_join(name + ".png")) == OK, name + " native PNG")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
