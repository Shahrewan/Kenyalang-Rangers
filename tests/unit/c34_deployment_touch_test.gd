extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const SAMPLE := preload("res://scenes/battle/sample_battle.tscn")
const POST := &"facility.logistics_post"
const SCOUT := &"ranger.scout_sniper"
const PATROL := &"ranger.patrolman"
const STRIKE := &"ranger.strike_team"

var _save := "user://c34-touch-%d.json" % OS.get_process_id()
var _output := ""
var _checks := 0
var _failures := 0
var _app: Control

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(960, 540)
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		_output = args[0]
		var dims := args[1].split("x")
		root.size = Vector2i(int(dims[0]), int(dims[1]))
		DirAccess.make_dir_recursive_absolute(_output)
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _save
	root.add_child(_app)
	_app.set_process(false)
	if not _output.is_empty():
		_app.presentation.values.text = int(args[2])
		_app._restyle()
	await _layout()
	await _first_contact()
	_app.free()
	await _all_deployables()
	var cold := CampaignProgress.new(_save)
	_check(cold.record_for(&"C1-01").get("perfect", false) and cold.funds() == 25000,
		"The 15,000 Funds perfect-clear receipt survives a cold load on a fresh 10,000 Funds profile")
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C34 deployment touch: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _first_contact() -> void:
	var receipts: Array[String] = []
	_app.presentation.cue_dispatched.connect(func(group: String, _path: String) -> void: receipts.append(group))
	var naming: Control = _app._screen
	var edit := naming.find_children("*", "LineEdit", true, false).front() as LineEdit
	edit.text = "Rimba"
	edit.text_changed.emit(edit.text)
	edit.text_submitted.emit(edit.text)
	if _app._route == &"name":
		var accepted := naming.find_children("*", "Button", true, false).front() as Button
		await _tap(accepted)
	_check(_app._route == &"menu" and _app._campaign_progress.snapshot().leader_name == "Rimba",
		"Production naming leads to a fresh Main Menu")
	await _tap(_app._screen.get_node("%OpenCampaign"))
	await _tap(_button(_app._screen, "Operation_C1_01"))
	await _tap(_button(_app._screen, "StartOperation"))
	var field := _app._screen as CampaignBattle
	field.set_physics_process(false)
	await _capture("briefing")
	await _tap(field.get_node("%Skip"))
	var controller := field.get_node("%DeploymentController")
	var sim := field.battle
	var state := sim.deployment
	var audio: Array[String] = []
	field.sound_requested.connect(audio.append)
	_check(field._board.cell_at(Vector2(INF, 30)) == DeploymentState.NO_CELL
		and field._board.cell_at(Vector2(-1.0e24, 30)) == DeploymentState.NO_CELL,
		"Invalid and extreme pointer coordinates stay outside the integer grid")
	await _drop(field, POST, Vector2i(4, 3))
	_check(state.tokens == 0 and state.occupancy.is_empty() and controller._local_notice.visible, "Invalid ground Post drop leaves the budget and cells empty")
	var post_card := _card(controller, POST)
	var from := post_card.get_global_rect().get_center()
	var tile := _at(field, Vector2i(1, 0))
	_touch(from, 0, true)
	_check(controller._pointer == 0 and controller._swallow_emulated_mouse, "Engine-emulated mouse is claimed before native tray contact")
	var lift := from + Vector2(2, -5)
	_motion(from, lift, 0)
	_check(field._board.preview_spec != null and field._board.preview_spec.id == POST and not controller._gesture.moved,
		"A five-pixel upward lift starts the Facility preview before the fourteen-pixel swipe threshold")
	_motion(lift, tile, 0)
	await _capture("starter-post-preview")
	_check(field._board.preview_spec != null and state.placed.is_empty(), "A real rendered Facility preview precedes release")
	_touch(tile, 1, true)
	_motion(tile, Vector2.ZERO, 1)
	_touch(Vector2.ZERO, 1, false)
	_check(controller._pointer == 0 and field._board.preview_cell == Vector2i(1, 0), "Secondary finger leaves the owned gesture and preview intact")
	_touch(tile, 0, false, true)
	_check(controller._pointer == -2 and not controller._swallow_emulated_mouse and state.placed.is_empty()
		and field._board.preview_spec == null, "Canceled native touch clears its emulated sequence and preview")
	_touch(from, 0, true)
	var diagonal := from + Vector2(-17, -15)
	_motion(from, diagonal, 0)
	_check(not controller._pan_tray, "A shallow diagonal off a card is still available for deployment")
	_motion(diagonal, tile, 0)
	_check(field._board.preview_cell == Vector2i(1, 0), "The fast diagonal drag previews its intended tile")
	_touch(tile, 0, false, true)
	await _tap(post_card)
	_check(controller.selected_card().id == POST and field._board.preview_spec == controller.selected_card()
		and state.placed.is_empty(), "Tapping a card shows legal tiles immediately and spends nothing")
	await _capture("tap-to-place")
	var wrong_tile := _at(field, Vector2i(4, 3))
	_touch(wrong_tile, 0, true)
	_touch(wrong_tile, 0, false)
	_check(state.tokens == 0 and state.occupancy.is_empty() and controller.selected_card() != null
		and controller._local_notice.visible, "An invalid tile tap preserves the selected card, Tokens and occupancy")
	_touch(tile, 0, true)
	field.request_back()
	_touch(tile, 0, false)
	_check(controller.selected_card() == null and field._board.preview_spec == null and state.occupancy.is_empty()
		and state.clock.is_running(), "Android Back cancels a card and its in-flight tile tap before the release")
	await _tap(post_card)
	_touch(tile, 0, true)
	_motion(tile, wrong_tile, 0)
	_touch(wrong_tile, 0, false)
	_check(controller.selected_card() != null and state.occupancy.is_empty(), "A drag starting on a tile cannot commit the tap shortcut")
	_touch(tile, 0, true)
	_touch(tile, 0, false)
	await _layout()
	_check(state.posts_deployed == 1 and state.tokens == 0 and state.occupancy.size() == 2,
		"A two-tap Starter Post commits its two cells exactly once")
	_advance(field, 1200)
	var scout_at := _card(controller, SCOUT).get_global_rect().get_center()
	_touch(scout_at, 0, true)
	_touch(_at(field, Vector2i(5, 2)), 0, false)
	await _layout()
	_check(state.placed.has(SCOUT) and not controller._facing_picker.visible, "A fast Scout drop commits even without a delivered motion event")
	_advance(field, 1800)
	var before := state.tokens
	var anchor := Vector2i(6, 3)
	audio.clear()
	await _tap(_card(controller, PATROL))
	var ground := _at(field, anchor)
	_touch(ground, 0, true)
	_touch(ground, 0, false)
	await _layout()
	_check(controller.is_choosing_facing() and controller._pending_facing == 0 and state.tokens == before,
		"The melee tap shortcut still waits for a direction and confirmation without spending")
	await _tap(controller._dismiss_facing)
	audio.clear()
	await _drop(field, PATROL, anchor, 0.29)
	_check(not audio.has("combat_deploy"), "Pending melee touch never cues deployment")
	_check(controller._facing_picker.visible and controller._deploy_button.disabled and controller._pending_facing == 0
		and field._board.preview_coverage().is_empty(), "Right-half drop asks for an explicit choice with no ghost direction selected")
	_check(state.tokens == before and state.cooldown_ticks(PATROL) == 0 and not state.occupancy.has(anchor),
		"Pending melee placement consumes no Tokens, cooldown or occupied cell")
	var advancing := field.battle.clock.tick
	_advance(field, advancing + 2)
	_check(field.battle.clock.tick == advancing + 2, "Facing selection continues normal combat time")
	await _tap(controller._face_right)
	_check(field._board.preview_coverage() == [anchor + Vector2i.RIGHT] and field._board.preview_facing == 1
		and controller._face_right.button_pressed, "Right option mirrors the ghost and highlights the right attack tile")
	await _capture("face-right")
	await _tap(controller._face_left)
	_check(audio.count("combat_facing_select") == 2 and not audio.has("combat_deploy"), "Each changed direction cues a detent only")
	_check(field._board.preview_coverage() == [anchor + Vector2i.LEFT] and field._board.preview_facing == -1
		and controller._face_left.button_pressed and not controller._face_right.button_pressed,
		"Left option changes preview and selected button before confirmation")
	await _capture("face-left")
	await _tap(controller._dismiss_facing)
	_check(audio.has("ui_cancel") and not audio.has("combat_deploy"), "Cancel gives feedback without a committed cue")
	_check(not controller._facing_picker.visible and state.tokens == before and not state.occupancy.has(anchor),
		"Cancel clears the ghost without a charge")
	await _drop(field, PATROL, anchor)
	field.request_back()
	_check(not controller._facing_picker.visible and not state.clock.paused, "Android Back closes pending choices before pausing")
	await _drop(field, PATROL, anchor)
	await _tap(controller._face_left)
	field.suspend_interaction()
	_check(not controller._facing_picker.visible and state.clock.paused and field._board.preview_spec == null
		and state.tokens == before, "Suspending clears pending placement and opens safe pause")
	await _capture("pause")
	await _tap(_button(field, "ResumeOperation"))
	await _drop(field, PATROL, anchor)
	await _tap(controller._face_left)
	await _tap(controller._deploy_button)
	_check(audio.count("combat_deploy") == 1, "Real facing confirmation emits exactly one committed cue")
	_check(state.placed.has(PATROL) and state.placed[PATROL].facing == -1
		and state.tokens == before - state.placed[PATROL].paid_cost and state.cooldown_ticks(PATROL) > 0,
		"Confirm spends exactly once and locks the explicitly selected facing")
	await _capture("deployed")
	for frame in 24000:
		if state.clock.dialogue_open:
			field.get_node("%Skip").pressed.emit()
		if field.battle.outcome != BattleSimulation.Outcome.RUNNING:
			break
		state.clock.advance_frame()
	field._refresh()
	if state.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()
	await _layout()
	_check(_app._route == &"results" and sim.defeated == 14 and sim.escaped == 0
		and sim.integrity == 100 and _app._campaign_progress.funds() == 25000,
		"Real First Contact play reaches the perfect-clear result and credits 15,000 Funds")
	_app.presentation._process(0.0)
	_check(receipts.count("result_perfect_clear") == 1 and not receipts.has("result_victory"),
		"Story perfect clear dispatches its own receipt once")
	await _capture("first-contact-result")

func _all_deployables() -> void:
	var field := SAMPLE.instantiate() as BattleScene
	var controller := field.get_node("%DeploymentController")
	var roster := DeploymentRoster.new()
	roster.entries.assign(CampaignContent.RANGERS.entries + CampaignContent.FACILITIES.entries)
	controller.roster = roster
	controller.preview_budget = 300
	field.sandbox = true
	var configuration := ChaosConfiguration.new()
	configuration.select_route(&"T05")
	configuration.set_quantity(0, &"E01", 1)
	field.stage = configuration.build_stage()
	root.add_child(field)
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.set_physics_process(false)
	var skin := FirstContactSkin.new()
	controller.illustrate(skin)
	await _layout()
	var directional: Array[StringName] = [
		&"ranger.patrolman", &"ranger.guard_veteran", &"ranger.barricade_ops",
		&"ranger.woods_tracker", &"ranger.saboteurist", STRIKE,
	]
	for spec: DeploymentSpec in roster.entries:
		field._restart()
		field._board.illustrate_first_contact(skin, field.stage.stage_id)
		await _layout()
		var state := controller.state as DeploymentState
		var tile := _legal_anchor(state, spec)
		var tokens := state.tokens
		_check(tile != DeploymentState.NO_CELL and field._board.cell_at(_at(field, tile)) == tile, "%s maps a legal native viewport coordinate" % spec.label)
		if tile == DeploymentState.NO_CELL:
			continue
		await _drop(field, spec.id, tile)
		var needs_facing := spec.id in directional
		_check(controller._facing_picker.visible == needs_facing, "%s follows its exact directional or direct role" % spec.label)
		if needs_facing:
			_check(state.tokens == tokens and not state.occupancy.has(tile) and state.cooldown_ticks(spec.id) == 0,
				"%s pending placement is transactional" % spec.label)
			await _tap(controller._face_right)
			if spec.id == STRIKE:
				_check(field._board.preview_coverage() == [tile + Vector2i(2, 0)], "Strike Team coverage starts beyond its second ground cell")
				state.tokens = 0
				await _tap(controller._deploy_button)
				_check(state.occupancy.is_empty() and state.tokens == 0 and "Need" in controller._hint.text,
					"Confirm revalidates affordability after the pending placement")
				state.tokens = tokens
				await _drop(field, spec.id, tile)
				await _tap(controller._face_right)
				var other := DeployableLevels.definition(PATROL)
				_check(state.deploy(other, tile + Vector2i.RIGHT, -1).is_empty(), "Fixture uses a legal Patrolman to invalidate Strike Team's second cell")
				var after_other := state.tokens
				await _tap(controller._deploy_button)
				_check(state.occupancy.size() == 1 and state.tokens == after_other and not state.placed.has(STRIKE),
					"Confirm revalidates the entire footprint and preserves its existing occupant")
				state.retreat(PATROL)
				state.tokens = tokens
				await _drop(field, spec.id, tile)
				await _tap(controller._face_right)
			await _tap(controller._deploy_button)
		var placement: DeploymentState.Placement = state.placed.get(state.interaction_id(tile))
		_check(placement != null and placement.spec.id == spec.id and
			state.occupancy.size() == spec.footprint(tile).size() + spec.reserved(tile).size()
			and state.tokens == tokens - placement.paid_cost and placement.facing == 1,
			"%s commits one exact cost, facing and footprint" % spec.label)
		if spec.id == POST and placement != null:
			_check(state.posts_deployed == 1 and placement.paid_cost == 0 and state.build_ticks_left(placement.id) == 0,
				"First Logistics Post remains free and instant")
		elif spec.id == STRIKE and placement != null:
			var remaining := state.tokens
			await _drop(field, spec.id, tile)
			_check(not controller._facing_picker.visible and state.tokens == remaining and "Ready to deploy" in controller._hint.text,
				"Repeated drop during the type cooldown provides feedback and spends nothing")
	field.free()
	await process_frame

func _legal_anchor(state: DeploymentState, spec: DeploymentSpec) -> Vector2i:
	var cells := state.map.ground if spec.uses_ground() else state.map.elevated
	for at in cells:
		if at in state.map.spawns or at == state.map.tunnel:
			continue
		if spec.id == STRIKE and at.x + 2 >= state.map.size.x:
			continue
		if state.placement_error(spec, at).is_empty():
			return at
	return DeploymentState.NO_CELL

func _advance(field: BattleScene, until_tick: int) -> void:
	while field.battle.clock.tick < until_tick and field.battle.clock.is_running():
		field.battle.clock.advance_frame()
	field._refresh()

func _drop(field: BattleScene, id: StringName, cell: Vector2i, offset := 0.0) -> void:
	var controller := field.get_node("%DeploymentController")
	var card := _card(controller, id)
	(field.get_node("%TrayScroll") as ScrollContainer).ensure_control_visible(card)
	await _layout()
	var from := card.get_global_rect().intersection(controller._tray_clip()).get_center()
	var aim := _at(field, cell) + Vector2(offset * field._board.tile_size(), 0)
	_touch(from, 0, true)
	_motion(from, aim, 0)
	if not _output.is_empty():
		await RenderingServer.frame_post_draw
	_touch(aim, 0, false)
	await _layout()

func _card(controller: Node, id: StringName) -> Control:
	var index: int = controller._entries.find_custom(func(spec: DeploymentSpec) -> bool: return spec.id == id)
	return controller._cards[index]

func _at(field: BattleScene, cell: Vector2i) -> Vector2:
	return field._board.get_global_transform_with_canvas() * field._board.cell_center(cell)

func _tap(button: Control) -> void:
	await _layout()
	_check(is_instance_valid(button) and button.is_visible_in_tree() and (not button is BaseButton or not (button as BaseButton).disabled), "Reachable action " + String(button.name))
	var at := button.get_global_rect().get_center()
	_touch(at, 0, true)
	_touch(at, 0, false)
	await _layout()

func _touch(at: Vector2, id: int, down: bool, cancelled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * at
	event.index = id
	event.pressed = down
	event.canceled = cancelled
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _motion(from: Vector2, to: Vector2, id: int) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = root.get_final_transform() * to
	event.relative = event.position - root.get_final_transform() * from
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _button(parent: Node, id: String) -> Button:
	return parent.find_child(id, true, false) as Button

func _layout() -> void:
	await process_frame
	await process_frame

func _capture(id: String) -> void:
	if _output.is_empty():
		return
	await _layout()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size and image.save_png(_output.path_join(id + ".png")) == OK, "Native capture " + id)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
