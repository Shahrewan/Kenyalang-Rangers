extends SceneTree

const STAGE := preload("res://data/stages/c02_first_contact.tres")
const SCENE := preload("res://scenes/battle/sample_battle.tscn")

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_check_grid()
	_check_waves()
	_check_speed_and_holds()
	_check_outcomes()
	_check_scene()
	print("Battle checks complete. Failures: ", _failures)
	quit(0 if _failures == 0 else 1)

func _check_grid() -> void:
	var map: BattleMap = STAGE.map
	_check(STAGE.validation_error().is_empty() and map.size == Vector2i(12, 5), "T01 fixture validates")
	_check(map.tile_at(Vector2i(4, 2)) == BattleMap.Tile.GROUND, "Bend is ground")
	_check(map.tile_at(Vector2i(8, 2)) == BattleMap.Tile.ELEVATED, "Raised tile is elevated")
	for cell in [Vector2i.ZERO, map.tunnel, map.spawns[0], Vector2i(-1, 2)]:
		_check(map.tile_at(cell) == BattleMap.Tile.NONDEPLOYABLE, "Scenery, endpoints and off-board cells are nondeployable")
	_check(STAGE.routes[0].position_at(4.5) == Vector2(4.0, 1.5), "Waypoints interpolate through the bend")
	var bad_stage := STAGE.duplicate() as BattleStage
	var bad_route := BattleRoute.new()
	bad_route.cells.assign(STAGE.routes[0].cells)
	bad_route.cells.insert(2, Vector2i(1, 0))
	bad_route.cells.insert(3, Vector2i(1, 1))
	bad_stage.routes = [bad_route]
	_check(bad_stage.validation_error() == "Interior route waypoints must be ground.", "Reject a route that crosses a platform")

func _check_waves() -> void:
	var empty := _wave([_group(&"unused", 0)], 100)
	var first := _wave([_group(&"A", 2, 2), _group(&"B", 1)], 4)
	var second := _wave([_group(&"C", 1)])
	var simulation := _battle([empty, first, empty, second, empty])
	var clock := simulation.clock
	var log: Array = []
	simulation.enemy_spawned.connect(func(id: int, key: StringName) -> void:
		log.append([id, key, clock.tick])
	)
	_check(simulation.wave_count == 2 and simulation.integrity == 100, "Only populated waves count and Integrity starts at 100")
	for frame in 15:
		clock.advance_frame()
		for id: int in simulation.active.keys():
			simulation.defeat_enemy(id)
	_check(log == [[1, &"A", 1], [2, &"A", 3], [3, &"B", 5], [4, &"C", 9]], "Individual spawns honor group order, interval and populated-wave rest")
	_check(simulation.is_perfect() and simulation.defeated == 4 and clock.tick == 9, "Last wave resolves once and stops the clock")
	_check(not simulation.defeat_enemy(4), "Duplicate resolution has no effect")

	var waiting := _battle([first, second])
	_frames(waiting.clock, 8)
	_check(waiting.wave_number == 1 and waiting.active.size() == 3, "Unresolved live enemies hold the next wave")
	var all_empty := _battle([empty, empty])
	_check(all_empty.outcome == BattleSimulation.Outcome.WON and all_empty.clock.tick == 0, "All-empty sequence adds no rest or spawns")

func _check_speed_and_holds() -> void:
	var waves := [_wave([_group(&"A", 3, 4)])] as Array[BattleWave]
	var normal := _battle(waves)
	var fast := _battle(waves)
	var elapsed: Array[float] = [0.0]
	fast.clock.stepped.connect(func(_tick: int, seconds: float) -> void: elapsed[0] += seconds)
	fast.clock.set_speed(2)
	_frames(normal.clock, 6)
	_frames(fast.clock, 3)
	_check(normal.clock.tick == fast.clock.tick and fast.active.size() == 2, "2× uses the same spawn ticks as 1×")
	_check(normal.active[1].grid_position() == fast.active[1].grid_position(), "2× uses the same movement steps as 1×")
	var at := fast.active[1].grid_position()
	fast.clock.paused = true
	fast.clock.dialogue_open = true
	_frames(fast.clock, 30)
	fast.clock.paused = false
	_frames(fast.clock, 30)
	_check(fast.clock.tick == 6 and fast.active.size() == 2 and fast.active[1].grid_position() == at, "Pause and dialogue each hold movement and spawns")
	_check(is_equal_approx(elapsed[0], 0.1) and not fast.defeat_enemy(1), "Combat subscribers freeze and defeat input stays blocked")
	fast.clock.dialogue_open = false
	_frames(fast.clock, 2)
	_check(fast.clock.tick == 10 and fast.active.size() == 3 and is_equal_approx(elapsed[0], 10.0 / 60.0), "Resume continues from the held timer state")

func _check_outcomes() -> void:
	var waves := [_wave([_group(&"A", 1)])] as Array[BattleWave]
	var combat := _battle(waves)
	_frames(combat.clock, 14)
	_check(combat.escaped == 1 and combat.integrity == 90 and combat.outcome == BattleSimulation.Outcome.WON and not combat.is_perfect(), "A real tunnel escape costs Integrity and yields a non-perfect clear")
	var loss := _battle(waves)
	loss.lose_integrity(95)
	_frames(loss.clock, 14)
	_check(loss.escaped == 1 and loss.integrity == 0 and loss.outcome == BattleSimulation.Outcome.LOST, "A lethal escape clamps Integrity and defeats the operation")
	var story := _battle(waves)
	story.lose_integrity(7)
	story.clock.advance_frame()
	var events: Array[bool] = []
	story.cinematic_withdrawal.connect(func() -> void: events.append(true))
	story.record_cinematic_withdrawal()
	_check(events.size() == 1 and story.active.size() == 1 and story.escaped == 0 and story.integrity == 93, "Cinematic withdrawal never resolves a registered enemy or costs Integrity")
	story.defeat_enemy(1)
	_check(story.is_perfect(), "Non-escape Integrity damage preserves a perfect clear")

func _check_scene() -> void:
	var scene := SCENE.instantiate() as BattleScene
	root.add_child(scene)
	scene.set_physics_process(false)
	scene._physics_process(CombatClock.STEP_SECONDS)
	var dialogue: Button = scene.get_node("%OpenDialogue")
	var pause: Button = scene.get_node("%Pause")
	var skip: Button = scene.get_node("%Skip")
	var overlay: Control = scene.get_node("%Dialogue")
	pause.pressed.emit()
	dialogue.pressed.emit()
	var tick := scene.battle.clock.tick
	var position := scene.battle.active[1].grid_position()
	for frame in 300:
		scene._physics_process(CombatClock.STEP_SECONDS)
	_check(overlay.visible and scene.battle.clock.tick == tick and scene.battle.active[1].grid_position() == position and scene.battle.active.size() == 1, "Dialogue overlay holds the actual battle scene")
	skip.pressed.emit()
	scene._physics_process(CombatClock.STEP_SECONDS)
	_check(not overlay.visible and scene.battle.clock.tick == tick and scene.battle.integrity == 100 and scene.battle.escaped == 0, "Skipping dialogue keeps an existing pause and changes no combat counters")
	pause.pressed.emit()
	scene._physics_process(CombatClock.STEP_SECONDS)
	_check(scene.battle.clock.tick == tick + 1, "Scene resumes only after the remaining pause clears")
	var defeat: Button = scene.get_node("%DefeatEnemy")
	for frame in 4100:
		scene._physics_process(CombatClock.STEP_SECONDS)
		if not defeat.disabled:
			defeat.pressed.emit()
		if scene.battle.clock.stopped:
			break
	_check(scene.battle.is_perfect() and scene.battle.defeated == 14, "The demo's defeat control resolves both authored waves")
	_check(scene.battle.clock.tick == 4021, "The full fixture preserves its 3.5 s spawn cadence and 25 s rest")
	scene.queue_free()

func _group(id: StringName, count: int, interval_ticks: int = 1) -> BattleSpawnGroup:
	var enemy := BattleEnemyDefinition.new()
	enemy.enemy_id = id
	enemy.tiles_per_second = 60.0
	enemy.escape_penalty = 10
	var group := BattleSpawnGroup.new()
	group.enemy = enemy
	group.count = count
	group.interval_seconds = interval_ticks * CombatClock.STEP_SECONDS
	return group

func _wave(groups: Array[BattleSpawnGroup], rest_ticks: int = 0) -> BattleWave:
	var wave := BattleWave.new()
	wave.groups = groups
	wave.rest_after_seconds = rest_ticks * CombatClock.STEP_SECONDS
	return wave

func _battle(waves: Array[BattleWave]) -> BattleSimulation:
	var stage := STAGE.duplicate() as BattleStage
	stage.waves = waves
	return BattleSimulation.new(stage)

func _frames(clock: CombatClock, count: int) -> void:
	for frame in count:
		clock.advance_frame()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failures += 1
