extends SceneTree

const STAGE := preload("res://data/stages/c02_first_contact.tres")
const ROSTER := preload("res://data/rangers/c03_preview.tres")
const SCENE := preload("res://scenes/battle/sample_battle.tscn")
const STARTER_RULES := preload("res://data/stages/c04_logistics_rules.tres")
const FIRST := Vector2i(1, 0)
const LATER := Vector2i(5, 0)
const NEXT := Vector2i(8, 2)
const POST_ID := &"facility.logistics_post"
const FIRST_ID := &"facility.logistics_post#1"
const SECOND_ID := &"facility.logistics_post#2"
const SONIC_ID := &"facility.sonic_turret"

var _failed := 0
var _post: DeploymentSpec = ROSTER.entries[5]
var _sonic: DeploymentSpec = ROSTER.entries[6]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_starter()
	_yield_endpoints()
	_later_posts()
	_construction_and_stockpile()
	await _scene_workflow()
	print("Logistics checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _starter() -> void:
	var state := _state(STARTER_RULES)
	_check(state.tokens == 0, "First Contact begins at zero Tokens")
	_check(not state.has_legal_opening([ROSTER.entries[0]]), "Zero Tokens without a legal free Post blocks opening")
	_check(state.has_legal_opening([_post]), "C1-01 Starter Post allows a legal opening")
	_check(not state.deploy(_post, Vector2i(3, 3), 1).is_empty() and state.posts_deployed == 0, "Invalid drop leaves the free Post unspent")
	_check(state.deploy(_post, FIRST, 1).is_empty(), "First legal Post deploys free")
	_check(state.tokens == 0 and state.build_ticks_left(FIRST_ID) == 0 and state.cooldown_ticks(POST_ID) == 0, "Starter Post is instant and skips cooldown")
	_check(not state.deploy(_post, LATER, 1).is_empty(), "C1-01 supplies only one Starter Post")
	state.clock.set_speed(2)
	_frames(state, 299)
	state.clock.paused = true
	_frames(state, 120)
	state.clock.paused = false
	state.clock.dialogue_open = true
	_frames(state, 120)
	_check(state.tokens == 0 and state.clock.tick == 598, "Pause and dialogue hold the Post payout at 2×")
	state.clock.dialogue_open = false
	_frames(state, 1)
	_check(state.tokens == 9, "D01 pays 9 Level 1 Tokens at exactly ten combat seconds")
	_check(not state.cancel_construction(FIRST_ID) and not state.retreat(FIRST_ID), "An instant Post is complete and stationary")

func _yield_endpoints() -> void:
	for fixture in [[1, 1, 10], [100, 1, 15], [50, 4, 49]]:
		var post := _post.duplicate() as DeploymentSpec
		post.level = fixture[0]
		var state := _state()
		state.deploy(post, FIRST, 1)
		_frames(state, fixture[1] * LogisticsRules.PAYOUT_TICKS)
		_check(state.tokens == fixture[2], "Normal level %d payout carries exact fractional yield" % post.level)

func _later_posts() -> void:
	var state := _state()
	state.deploy(_post, FIRST, 1)
	_check(state.cost_for(_post) == 20 and not state.deploy(_post, LATER, 1).is_empty() and state.occupancy.size() == 2, "Unaffordable paid Post changes neither cost tier nor occupancy")
	_frames(state, 1200)
	_check(state.deploy(_post, LATER, 1).is_empty() and state.tokens == 0 and state.build_ticks_left(SECOND_ID) == 360, "Second Post charges 20 and begins its six-second build")
	_check(state.cooldown_ticks(POST_ID) == 480 and state.cost_for(_post) == 25, "Paid Post starts cooldown and raises the following price")
	_check(state.cancel_construction(SECOND_ID) and state.tokens == 20 and state.occupancy.size() == 2, "Cancelling the later Post refunds its exact paid cost and cells")
	_check(not state.cancel_construction(SECOND_ID) and state.tokens == 20, "Cancellation cannot pay twice")
	_check(not state.deploy(_post, NEXT, 1).is_empty() and state.cooldown_ticks(POST_ID) == 480, "Cancellation leaves the repeat deployment cooldown in place")
	_frames(state, 600)
	_check(state.tokens == 30 and state.deploy(_post, NEXT, 1).is_empty() and state.tokens == 5, "Next accepted Post pays the escalated price")
	_frames(state, 959)
	_check(state.tokens == 15, "A paid Post accrues nothing before build plus ten combat seconds")
	_frames(state, 1)
	_check(state.tokens == 25, "A completed paid Post generates Tokens on its own payout cadence")

func _construction_and_stockpile() -> void:
	var rules := LogisticsRules.new()
	rules.fixed_stockpile = true
	var state := _state(rules)
	_check(state.tokens == 120 and not state.has_legal_opening([_post]), "D05 stocks 120 and prohibits even the first free Post")
	_check(not state.deploy(_post, FIRST, 1).is_empty() and state.posts_deployed == 0 and state.occupancy.is_empty() and state.tokens == 120, "D05 Post rejection is atomic")
	_check(state.has_legal_opening([_sonic]) and state.deploy(_sonic, LATER, 1).is_empty() and state.tokens == 85, "D05 can pay for a legal non-Post opening")
	_check(state.build_ticks_left(SONIC_ID) == 420 and state.occupancy.size() == 2, "Sonic begins its seven-second build with both cells occupied")
	state.clock.set_speed(2)
	_frames(state, 100)
	state.clock.paused = true
	_frames(state, 300)
	_check(state.build_ticks_left(SONIC_ID) == 220 and not state.cancel_construction(SONIC_ID), "Construction freezes at pause and cannot mutate then")
	state.clock.paused = false
	_check(state.cancel_construction(SONIC_ID) and state.tokens == 120 and state.occupancy.is_empty(), "Sonic refund reconciles and frees both cells")
	var max_level := _sonic.duplicate() as DeploymentSpec
	max_level.level = 100
	_check(not state.deploy(max_level, LATER, 1).is_empty() and state.tokens == 120, "Cancelling Sonic preserves its per-type cooldown")
	_frames(state, state.cooldown_ticks(SONIC_ID))
	_check(state.deploy(max_level, LATER, 1).is_empty(), "Sonic can be placed again after its cooldown")
	var rebuilt := state.interaction_id(LATER)
	_check(state.build_ticks_left(rebuilt) == 420, "Level 100 retains Sonic's seven-second construction")
	_frames(state, 210)
	_check(state.build_ticks_left(rebuilt) == 0 and not state.cancel_construction(rebuilt) and not state.retreat(rebuilt), "Finished Facility cannot cancel or retreat")
	_check(not state.deploy(max_level, NEXT, 1).is_empty() and state.tokens == 85, "Finished Facility keeps the type cooldown until its deadline")
	_frames(state, state.cooldown_ticks(SONIC_ID))
	_check(state.deploy(max_level, NEXT, 1).is_empty() and state.interaction_id(NEXT) != rebuilt
		and state.occupancy.has(LATER) and state.tokens == 50, "Another copy builds while the earlier Facility stays in place")

func _scene_workflow() -> void:
	var scene := SCENE.instantiate() as BattleScene
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.set_physics_process(false)
	await process_frame
	await process_frame
	var controller := scene.get_node("%DeploymentController")
	var board: BattleBoard = scene.get_node("%Board")
	var tray: Control = scene.get_node("%DeploymentTray")
	var opening: OptionButton = scene.get_node("%Opening")
	var state: DeploymentState = controller.state
	_check(state.tokens == 0 and tray.get_child(5).visible and not tray.get_child(6).visible, "Scene defaults to First Contact mission supply")
	_drag(tray.get_child(5), board, FIRST)
	_check(state.placed.has(FIRST_ID) and state.build_ticks_left(FIRST_ID) == 0 and state.tokens == 0, "Touch deploys the free Starter Post")
	opening.select(2)
	opening.item_selected.emit(2)
	await process_frame
	await process_frame
	state = controller.state
	_check(state.tokens == 120 and not tray.get_child(5).visible and tray.get_child(6).visible, "D05 preview resets wallet and removes the Post card")
	_drag(tray.get_child(6), board, LATER)
	_check(state.tokens == 85 and state.build_ticks_left(SONIC_ID) == 420, "Touch starts paid Facility construction")
	var point := board.get_global_transform_with_canvas() * board.cell_center(LATER)
	_touch(point, true)
	_touch(point, false)
	var cancel: Button = scene.get_node("%Retreat")
	_check(cancel.visible and cancel.text == "Cancel build", "Touching an unfinished Facility exposes Cancel build")
	cancel.pressed.emit()
	_check(state.tokens == 120 and state.occupancy.is_empty(), "Cancel control refunds the full paid cost")
	scene.queue_free()

func _state(rules: LogisticsRules = null) -> DeploymentState:
	return DeploymentState.new(STAGE.map, CombatClock.new(), 0, rules)

func _frames(state: DeploymentState, count: int) -> void:
	for frame in count:
		state.clock.advance_frame()

func _drag(card: Control, board: BattleBoard, cell: Vector2i) -> void:
	var from := card.get_global_rect().get_center()
	var to := board.get_global_transform_with_canvas() * board.cell_center(cell)
	_touch(from, true)
	var drag := InputEventScreenDrag.new()
	drag.position = to
	drag.relative = to - from
	root.push_input(drag, true)
	_touch(to, false)

func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	root.push_input(event, true)

func _check(result: bool, label: String) -> void:
	if result:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failed += 1
