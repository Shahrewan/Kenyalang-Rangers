class_name PresentationAudio
extends Node

signal cue_dispatched(group: String, source: String)

const DEFAULTS := {"master": 80, "music": 45, "sfx": 75, "text": 100}
const TEXT_SIZES := [100, 115, 130]
const BUS_LAYOUT := preload("res://default_bus_layout.tres")
const CUES := {
	"confirm": [494], "deploy": [330, 494], "invalid": [185, 147],
	"support": [392, 440], "tokens": [659], "skill": [440, 659], "victory": [392, 494, 587], "defeat": [330, 262, 196],
	"recon": [523, 523], "siege": [147, 196, 147], "heat": [294, 349, 392], "boss": [196, 196, 247],
	"water": [587, 494], "collect": [523, 659], "visitor": [784, 659, 880], "education": [392, 523],
}
const CATALOG_PATH := "res://data/presentation/sfx_catalog.json"
const CACHE_LIMIT := 40
const BATTLE_CATEGORIES := ["combat", "rangers", "facilities", "enemies", "bosses"]
const LEGACY_ALERTS := ["recon", "siege", "heat", "boss", "victory", "defeat", "visitor"]

class Voice:
	var player: AudioStreamPlayer
	var group := ""
	var category := ""
	var priority := 0
	var gain_db := 0.0

static var _registry: Dictionary
static var _streams: Dictionary[String, AudioStreamWAV] = {}
var path := "user://presentation.json"
var values := DEFAULTS.duplicate()
var _soundtrack := Soundtrack.new()
var music: AudioStreamPlayer:
	get:
		return _soundtrack.player()
var effects := AudioStreamPlayer.new()
var alerts := AudioStreamPlayer.new()
var _away := false
var _held := false
var _voices: Array[Voice] = []
var _pending: Dictionary[String, Dictionary] = {}
var _last_played: Dictionary[String, int] = {}
var _next_variant: Dictionary[String, int] = {}
var _cache: Dictionary[String, AudioStreamWAV] = {}
var _cache_order: Array[String] = []
var _failed_paths: Dictionary[String, bool] = {}
var _variant_rng := RandomNumberGenerator.new()

func _ready() -> void:
	var saved := ProfileFile.read(path)
	for key: String in DEFAULTS:
		var value: Variant = saved.get(key)
		if valid_setting(key, value):
			values[key] = int(value)
	if AudioServer.get_bus_index(&"Music") < 0:
		AudioServer.set_bus_layout(BUS_LAYOUT)
	add_child(_soundtrack)
	var voice_count := 8 if OS.has_feature("android") else 12
	for index in voice_count:
		var voice := Voice.new()
		voice.player = effects if index == 0 else (alerts if index == 1 else AudioStreamPlayer.new())
		voice.player.bus = &"SFX"
		add_child(voice.player)
		_voices.append(voice)
	_mix()
	set_process(false)

func valid_setting(key: String, value: Variant) -> bool:
	if key == "text":
		return ProfileFile.whole_between(value, TEXT_SIZES.front(), TEXT_SIZES.back()) and int(value) in TEXT_SIZES
	return key in DEFAULTS and ProfileFile.whole_between(value, 0, 100)

func change(key: String, value: int) -> bool:
	if not valid_setting(key, value):
		return false
	var next := values.duplicate()
	next[key] = value
	if not ProfileFile.replace(path, next, false):
		return false
	values = next
	_mix()
	return true

static func catalog() -> Dictionary:
	if _registry.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH)) if FileAccess.file_exists(CATALOG_PATH) else null
		_registry = parsed if parsed is Dictionary else {"groups": {}, "aliases": {}, "entities": {}}
	return _registry

static func entity_cue(id: StringName, action: String, fallback := "") -> String:
	var entities: Dictionary = catalog().get("entities", {})
	return str(entities.get(String(id), {}).get(action, fallback))

func _mix() -> void:
	_set_bus_gain(&"Master", float(values.master) / 100.0)
	_set_bus_gain(&"Music", Soundtrack.slider_gain(values.music))
	_set_bus_gain(&"SFX", float(values.sfx) / 100.0)
	if values.master == 0 or values.sfx == 0:
		_clear_effects()

func _set_bus_gain(bus: StringName, gain: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, gain == 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(gain) if gain > 0.0 else 0.0)

func set_route(route: StringName, stage_id := &"") -> void:
	_clear_effects()
	_last_played.clear()
	_soundtrack.select(Soundtrack.cue_for(route, stage_id))
	hold(false)

func hold(paused: bool) -> void:
	if paused and not _held:
		for group: String in _pending.keys():
			if _routine(group, _pending[group]):
				_pending.erase(group)
		for voice in _voices:
			if voice.group != "combat_messenger_withdrawal" and voice.priority < 75 and voice.category in BATTLE_CATEGORIES:
				_stop_voice(voice)
	_held = paused
	_soundtrack.hold(_held or _away)

func background(away: bool) -> void:
	_away = away
	if away:
		_clear_effects()
		_last_played.clear()
	hold(_held)

func cue(id: String) -> void:
	if _away or values.master == 0 or values.sfx == 0 or id.is_empty():
		return
	var registry := catalog()
	var group: String = registry.get("aliases", {}).get(id, id)
	var spec: Dictionary = registry.get("groups", {}).get(group, {})
	if spec.is_empty():
		if not CUES.has(id):
			return
		spec = {"priority": 80 if id in LEGACY_ALERTS else 30, "gain_db": 0.0,
			"category": "legacy", "cooldown_ms": 120, "limit": 1, "paths": [], "fallback": id}
	if (_held and _routine(group, spec)) or _pending.has(group):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(group, -100000)) < int(spec.cooldown_ms):
		return
	_pending[group] = spec
	set_process(true)

func _routine(group: String, spec: Dictionary) -> bool:
	return group != "combat_messenger_withdrawal" and int(spec.priority) < 75 and spec.category in BATTLE_CATEGORIES

func _process(_delta: float) -> void:
	if _pending.is_empty():
		set_process(false)
		return
	# Commit one request per group per frame, with warnings ahead of common attacks.
	var requested := _pending.duplicate()
	_pending.clear()
	var ordered: Array = requested.keys()
	ordered.sort_custom(func(a: String, b: String) -> bool: return int(requested[a].priority) > int(requested[b].priority))
	if ordered.size() > 1:
		ordered.erase("ui_confirm")
	if requested.has("ui_back") or int(requested[ordered.front()].priority) > 45:
		ordered.erase("ui_navigate")
	if requested.has("combat_fatal_escape"):
		ordered.erase("combat_integrity_loss")
	for group: String in ordered:
		_dispatch(group, requested[group])

func _dispatch(group: String, spec: Dictionary) -> void:
	var voice := _available_voice(group, spec)
	if voice == null:
		return
	var source := _resolve(group, spec)
	if source.is_empty():
		return
	voice.player.stop()
	voice.group = group
	voice.category = spec.category
	voice.priority = int(spec.priority)
	voice.gain_db = float(spec.gain_db)
	voice.player.stream = source.stream
	voice.player.volume_db = voice.gain_db
	_last_played[group] = Time.get_ticks_msec()
	_start_player(voice.player)
	cue_dispatched.emit(group, source.path)

func _available_voice(group: String, spec: Dictionary) -> Voice:
	var idle: Voice
	var weakest: Voice
	var weakest_lane: Voice
	var group_count := 0
	var lane_count := 0
	var count := 0
	var lane := _lane(spec.category, int(spec.priority))
	var lane_limit := (_voices.size() >> 1) if lane == 0 else (_voices.size() - 2 if lane == 1 else 4)
	for voice in _voices:
		if not voice.player.playing:
			if idle == null:
				idle = voice
			continue
		count += 1
		if voice.group == group:
			group_count += 1
		if weakest == null or voice.priority < weakest.priority:
			weakest = voice
		if _lane(voice.category, voice.priority) == lane:
			lane_count += 1
			if weakest_lane == null or voice.priority < weakest_lane.priority:
				weakest_lane = voice
	if group_count >= int(spec.limit):
		return null
	if lane_count >= lane_limit:
		return weakest_lane if weakest_lane != null and weakest_lane.priority < int(spec.priority) else null
	if count < _voices.size() - 2 or lane == 2:
		if idle != null:
			return idle
	return weakest if weakest != null and weakest.priority < int(spec.priority) else null

func _lane(category: String, priority: int) -> int:
	if priority >= 75:
		return 2
	return 0 if category in BATTLE_CATEGORIES else 1

func _resolve(group: String, spec: Dictionary) -> Dictionary:
	var groups: Dictionary = catalog().get("groups", {})
	var cursor := group
	var row := spec
	for depth in 8:
		var paths: Array = row.paths
		if not paths.is_empty():
			var index: int = _next_variant[cursor] if _next_variant.has(cursor) else _variant_rng.randi_range(0, paths.size() - 1)
			for offset in paths.size():
				var index_at := (index + offset) % paths.size()
				var path_at: String = paths[index_at]
				var stream := _resource(path_at)
				if stream != null:
					_next_variant[cursor] = (index_at + 1) % paths.size()
					return {"stream": stream, "path": path_at}
		var fallback := str(row.fallback) if row.fallback != null else ""
		if CUES.has(fallback):
			return {"stream": _sound(fallback, CUES[fallback], false), "path": "procedural:" + fallback}
		if not groups.has(fallback):
			return {}
		cursor = fallback
		row = groups[cursor]
	return {}

func _resource(path_at: String) -> AudioStreamWAV:
	if _cache.has(path_at):
		_cache_order.erase(path_at)
		_cache_order.append(path_at)
		return _cache[path_at]
	if _failed_paths.has(path_at):
		return null
	var stream: AudioStreamWAV
	if ResourceLoader.exists(path_at, "AudioStreamWAV"):
		stream = ResourceLoader.load(path_at, "AudioStreamWAV") as AudioStreamWAV
	if stream == null:
		_failed_paths[path_at] = true
		return null
	if _cache.size() >= CACHE_LIMIT:
		_cache.erase(_cache_order.pop_front())
	_cache[path_at] = stream
	_cache_order.append(path_at)
	return stream

func _stop_voice(voice: Voice) -> void:
	voice.player.stop()
	voice.player.stream = null

func _clear_effects() -> void:
	_pending.clear()
	for voice in _voices:
		_stop_voice(voice)

func _start_player(player: AudioStreamPlayer) -> void:
	# A window can also be running without an audio output. Movie capture supplies its own mixer.
	if AudioServer.get_driver_name() != "Dummy" or not Engine.get_write_movie_path().is_empty():
		player.play()

func _exit_tree() -> void:
	_clear_effects()

# Original procedural development audio. Each note starts and ends at silence.
static func _sound(id: String, notes: Array, loop: bool) -> AudioStreamWAV:
	if _streams.has(id):
		return _streams[id]
	var rate := 11025
	var length := 6615 if loop else 1102
	var data := PackedByteArray()
	data.resize(notes.size() * length * 2)
	for n in notes.size():
		for i in length:
			var t := float(i) / rate
			var phase := TAU * float(notes[n]) * t
			var envelope := sin(PI * i / (length - 1)) * exp(-3 * i / float(length))
			var sample := (sin(phase) + 0.22 * sin(2 * phase)) * envelope
			data.encode_s16(2 * (n * length + i), roundi(sample * (4600 if loop else 11000)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = length * notes.size()
	_streams[id] = stream
	return stream
