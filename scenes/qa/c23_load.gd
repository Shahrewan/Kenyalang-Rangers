extends MarginContainer

# QA-only T05 residency fixture. No changes to shared resources or player progress.
const FIELD := preload("res://scenes/battle/sample_battle.tscn")
const ANCHORS := {
	&"ranger.scout_sniper": Vector2i(2, 2), &"ranger.crowd_controller": Vector2i(5, 0),
	&"facility.sonic_turret": Vector2i(1, 0), &"facility.logistics_post": Vector2i(8, 0),
}
const SAMPLE_TICKS := 410
var field: BattleScene
var auto_finish := true
var siege_hits := 0
var heat_events := 0
var samples := PackedFloat64Array()
var _previous := 0
var _memory_start := 0
var _memory_peak := 0
var _start_tick := -1

func _ready() -> void:
	if auto_finish:
		Engine.max_fps = 60
	var config := ChaosConfiguration.new()
	config.select_route(&"T05")
	config.set_quantity(0, &"E04", 46)
	config.set_quantity(0, &"E11", 2)
	config.set_quantity(0, &"E14", 1)
	config.set_quantity(0, &"boss.diversion_captain", 1)
	field = FIELD.instantiate()
	field.stage = config.build_stage()
	field.stage.opening_delay_seconds = 8.0
	for group in field.stage.waves[0].groups:
		group.interval_seconds = CombatClock.STEP_SECONDS
		group.enemy = group.enemy.duplicate()
		group.enemy.max_hp *= 10
	field.sandbox = true
	field.sandbox_title = "C23 · 50-enemy load fixture"
	var controller := field.get_node("%DeploymentController")
	var roster := DeploymentRoster.new()
	for id: StringName in ANCHORS:
		roster.entries.append(DeployableLevels.definition(id))
	controller.roster = roster
	controller.preview_budget = 200
	add_child(field)
	var battle := field.battle
	for spec in roster.entries:
		var error := battle.deployment.deploy(spec, ANCHORS[spec.id], -1)
		if not error.is_empty():
			push_error("%s deployment: %s" % [spec.id, error])
	battle.enemy_spawned.connect(_spread)
	battle.siege_hit.connect(func() -> void: siege_hits += 1)
	battle.heat_overflow.connect(func() -> void: heat_events += 1)

func _spread(id: int, kind: StringName) -> void:
	var battle := field.battle
	var enemy := battle.active[id]
	enemy.distance = 1.0 if kind == &"E11" else float(id % 8) + float(id % 3) / 4.0
	enemy.add_damage_mark(battle.clock.tick, battle.clock.tick + 1000, 10)
	enemy.sonic_slow_until = battle.clock.tick + 1000
	enemy.sonic_speed_scale = 0.65
	if kind == &"E14":
		battle.heat = 98.0

func _process(_delta: float) -> void:
	if not auto_finish:
		return
	var battle := field.battle
	if battle.clock.dialogue_open:
		field.close_dialogue()
	if battle.active.size() != 50:
		_previous = 0
		if battle.clock.tick > 600 or battle.clock.stopped:
			push_error("Load fixture lost residency")
			get_tree().quit(1)
		return
	var now := Time.get_ticks_usec()
	var memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	if _start_tick < 0:
		_memory_start = memory
		_start_tick = battle.clock.tick
	_memory_peak = maxi(_memory_peak, memory)
	if _previous > 0:
		samples.append((now - _previous) / 1000.0)
	_previous = now
	if battle.clock.tick - _start_tick < SAMPLE_TICKS:
		return
	var elapsed_ms := 0.0
	for interval in samples:
		elapsed_ms += interval
	samples.sort()
	if samples.is_empty() or siege_hits == 0 or heat_events == 0:
		push_error("Missing frame samples or combat events")
		get_tree().quit(1)
		return
	var viewport_size := get_viewport_rect().size
	var result := {
		"os": OS.get_name(), "model": OS.get_model_name(), "cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(), "viewport": str(viewport_size),
		"window_px": str(DisplayServer.window_get_size()), "os_version": OS.get_version(),
		"physical_memory_bytes": OS.get_memory_info().get("physical", -1),
		"godot": Engine.get_version_info().string, "display": DisplayServer.get_name(),
		"count": samples.size(), "fps": 1000.0 * samples.size() / elapsed_ms,
		"p50_ms": _percentile(0.50), "p95_ms": _percentile(0.95), "p99_ms": _percentile(0.99),
		"max_ms": samples[-1], "static_bytes_at_start": _memory_start, "static_bytes_peak": _memory_peak,
		"resident": battle.active.size(), "units": battle.deployment.placed.size(),
		"siege_hits": siege_hits, "heat_events": heat_events,
	}
	print("C23_BENCH ", JSON.stringify(result))
	get_tree().quit()

func _percentile(fraction: float) -> float:
	return samples[ceili(samples.size() * fraction) - 1]
