extends SceneTree

const STAGE := preload("res://data/stages/c02_first_contact.tres")
const ROSTER := preload("res://data/rangers/c03_preview.tres")
const SCENE := preload("res://scenes/battle/sample_battle.tscn")
const PATROL := 0
const PAIR := 1
const SCOUT := 2
const FACILITY := 3
const SENTRY := 4

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_placements()
	_attacks_and_skills()
	_gestures()
	await _touch_scene()
	print("Deployment checks complete. Failures: ", _failures)
	quit(0 if _failures == 0 else 1)

func _placements() -> void:
	var clock := CombatClock.new()
	var state := DeploymentState.new(STAGE.map, clock, 60)
	_reject(state, PAIR, Vector2i(11, 3), "A pair cannot extend off the board")
	_reject(state, PATROL, Vector2i(8, 2), "A ground Ranger cannot occupy elevation")
	_reject(state, SCOUT, Vector2i(4, 3), "An elevated Ranger cannot occupy ground")
	_reject(state, SCOUT, STAGE.map.tunnel, "A Ranger cannot occupy a gate")
	_reject(state, FACILITY, Vector2i(2, 0), "A Facility requires both consecutive elevated cells")
	_check(_deploy(state, PAIR, Vector2i(5, 3), 1) and state.tokens == 46, "Both ground tiles register for one charge")
	_check(state.occupancy.has(Vector2i(5, 3)) and state.occupancy.has(Vector2i(6, 3)), "Two-cell Ranger occupies both tiles")
	_reject(state, PATROL, Vector2i(6, 3), "Overlap on the second ground tile is atomic")

	_check(_deploy(state, FACILITY, Vector2i(8, 2)), "Two adjacent elevated cells accept a Facility")
	_reject(state, SCOUT, Vector2i(9, 2), "Facility blocks its second elevated cell")
	_check(not state.retreat(&"facility"), "Facilities cannot retreat")
	_reject(state, SENTRY, Vector2i(6, 0), "Sentry clearance cannot extend beyond the board")
	_check(_deploy(state, SENTRY, Vector2i(5, 2)), "Sentry occupies one elevated cell")
	_check(state.occupancy.get(Vector2i(5, 1)) == &"sentry", "Sentry reserves the cell above")
	_reject(state, SCOUT, Vector2i(5, 1), "Another deployable cannot use the Sentry reserve")

	var empty := DeploymentState.new(STAGE.map, clock, 0)
	_reject(empty, PATROL, Vector2i(6, 3), "Unaffordable drag changes no Tokens or occupancy")
	_check(state.retreat(&"two_cell") and not state.occupancy.has(Vector2i(5, 3)) and not state.occupancy.has(Vector2i(6, 3)), "Retreat releases both ground cells")
	_reject(state, PAIR, Vector2i(5, 3), "Redeploy requires cooldown")
	clock.set_speed(2)
	clock.paused = true
	for frame in 160:
		clock.advance_frame()
	_check(state.cooldown_ticks(&"two_cell") == 300, "Redeploy cooldown freezes with combat")
	clock.paused = false
	for frame in 149:
		clock.advance_frame()
	_check(state.cooldown_ticks(&"two_cell") == 2, "Redeploy cooldown uses 2× combat time")
	clock.advance_frame()
	_check(_deploy(state, PAIR, Vector2i(5, 3), -1), "Redeploy succeeds exactly at the cooldown deadline")

func _attacks_and_skills() -> void:
	var state := DeploymentState.new(STAGE.map, CombatClock.new(), 60)
	_deploy(state, PAIR, Vector2i(5, 3), 1)
	_deploy(state, PATROL, Vector2i(9, 3), -1)
	_deploy(state, SCOUT, Vector2i(8, 2))
	var pair: DeploymentState.Placement = state.placed[&"two_cell"]
	var patrol: DeploymentState.Placement = state.placed[&"patrolman"]
	var scout: DeploymentState.Placement = state.placed[&"scout"]
	_check(pair.facing == 1 and state.can_attack(pair, Vector2i(8, 3), false) and not state.can_attack(pair, Vector2i(4, 3), false), "Right-facing pair attacks from its front occupied cell")
	_check(patrol.facing == -1 and state.can_attack(patrol, Vector2i(8, 3), false) and not state.can_attack(patrol, Vector2i(10, 3), false), "Left-facing melee excludes the rear")
	_check(not state.can_attack(patrol, Vector2i(8, 3), true), "Ground melee excludes aerial targets")
	_check(state.can_attack(scout, Vector2i(10, 4), true) and not state.can_attack(scout, Vector2i(11, 4), true), "Scout uses square coverage and accepts eligible aerial targets")

	var fired: Array = []
	state.skill_fired.connect(func(id: StringName, cell: Vector2i) -> void: fired.append([id, cell]))
	state.quick_tap(&"patrolman")
	_check(fired == [[&"patrolman", DeploymentState.NO_CELL]], "Quick tap triggers an immediate skill")
	state.quick_tap(&"scout")
	_check(not state.confirm_target() and fired.size() == 1, "Targeted tap only arms")
	_check(not state.select_target(Vector2i(0, 0)) and not state.confirm_target(), "Out-of-range targets cannot confirm")
	_check(state.select_target(Vector2i(9, 3)) and fired.size() == 1, "Selection alone never fires")
	_check(state.confirm_target() and fired.back() == [&"scout", Vector2i(9, 3)] and not state.confirm_target(), "Confirmation fires exactly once")

func _gestures() -> void:
	var gesture := DeploymentGesture.new()
	gesture.press(Vector2.ZERO, 100, null, &"patrolman", false)
	_check(gesture.release(Vector2.ZERO, 449) == DeploymentGesture.Release.TAP, "349 ms releases as a tap")
	gesture.press(Vector2.ZERO, 100, null, &"patrolman", false)
	_check(not gesture.reveal_hold(449) and gesture.reveal_hold(450), "Retreat reveals at 350 ms")
	_check(gesture.release(Vector2.ZERO, 510) == DeploymentGesture.Release.HOLD, "A hold suppresses the tap")
	gesture.press(Vector2.ZERO, 0, null, &"", true)
	_check(gesture.release(Vector2(80, 0), 50) == DeploymentGesture.Release.NONE, "Target-mode drag cannot select or fire")
	gesture.press(Vector2.ZERO, 0, ROSTER.entries[0], &"", false)
	_check(gesture.release(Vector2(80, 0), 400) == DeploymentGesture.Release.DROP, "A slow card drag still drops")

func _touch_scene() -> void:
	var scene := SCENE.instantiate() as BattleScene
	scene.get_node("%DeploymentController").preview_budget = 60
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.set_physics_process(false)
	await process_frame
	await process_frame
	var controller := scene.get_node("%DeploymentController")
	var state: DeploymentState = controller.state
	var board: BattleBoard = scene.get_node("%Board")
	var tray: Control = scene.get_node("%DeploymentTray")
	var card: Control = tray.get_child(PATROL)
	var start := card.get_global_rect().get_center()
	var ground := board.get_global_transform_with_canvas() * (board.cell_center(Vector2i(6, 3)) - Vector2(8, 0))
	var elevated := board.get_global_transform_with_canvas() * board.cell_center(Vector2i(8, 2))

	_drag(start, Vector2(2, 2))
	_check(state.tokens == 60 and state.occupancy.is_empty(), "Off-grid native touch release preserves budget and board")
	_drag(start, elevated)
	_check(state.tokens == 60 and state.occupancy.is_empty(), "Wrong-tile native touch release preserves budget and board")
	_drag(start, ground)
	var patrol: DeploymentState.Placement = state.placed.get(&"patrolman")
	_check(patrol != null and patrol.facing == -1 and state.tokens == 50, "Native touch press, drag and release deploy with locked facing")
	if patrol == null:
		scene.queue_free()
		return

	_touch(ground, true)
	await create_timer(0.40).timeout
	var retreat: Button = scene.get_node("%Retreat")
	_check(retreat.visible, "Holding touch on the placed actor reveals nearby Retreat")
	_touch(ground, false)
	retreat.pressed.emit()
	_check(not state.placed.has(&"patrolman") and state.cooldown_ticks(&"patrolman") == 300, "Nearby Retreat action starts redeploy cooldown")

	card = tray.get_child(SCOUT)
	_drag(card.get_global_rect().get_center(), elevated)
	_touch(elevated, true)
	_touch(elevated, false)
	var fired: Array = []
	state.skill_fired.connect(func(id: StringName, cell: Vector2i) -> void: fired.append([id, cell]))
	var confirm: Button = scene.get_node("%ConfirmSkill")
	_check(state.armed == &"scout" and confirm.visible and confirm.disabled, "Native short tap arms Scout with confirmation disabled")
	_drag(elevated, ground)
	_check(confirm.disabled and state.pending_target == DeploymentState.NO_CELL and fired.is_empty(), "An unconfirmed touch drag does not select or activate")
	var target := board.get_global_transform_with_canvas() * board.cell_center(Vector2i(8, 3))
	_touch(target, true)
	_touch(target, false)
	await process_frame
	_check(not confirm.disabled, "Tap on a covered tile enables explicit confirmation")
	confirm.pressed.emit()
	_check(state.armed.is_empty() and state.pending_target == DeploymentState.NO_CELL and fired == [[&"scout", Vector2i(8, 3)]], "Confirmed target fires once and clears the armed skill")
	scene.queue_free()

func _drag(from: Vector2, to: Vector2) -> void:
	_touch(from, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = to
	drag.relative = to - from
	root.push_input(drag, true)
	_touch(to, false)

func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	root.push_input(event, true)

func _deploy(state: DeploymentState, entry: int, anchor: Vector2i, facing := -1) -> bool:
	return state.deploy(ROSTER.entries[entry], anchor, facing).is_empty()

func _reject(state: DeploymentState, entry: int, anchor: Vector2i, label: String) -> void:
	var budget := state.tokens
	var occupied := state.occupancy.duplicate()
	var count := state.placed.size()
	_check(not _deploy(state, entry, anchor) and state.tokens == budget and state.occupancy == occupied and state.placed.size() == count, label)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failures += 1
