class_name Soundtrack
extends Node

const MANIFEST_PATH := "res://data/presentation/music_manifest.json"
const FADE_SECONDS := 0.45
const MENU := "bgm_main_menu"
const MANAGEMENT := "bgm_headquarters"
const STORY := "bgm_story_battle"
const CHAOS := "bgm_chaos"
const FINALE := "bgm_finale"
const LEARNING := "bgm_restoration"

class Track:
	var player := AudioStreamPlayer.new()
	var cue := ""
	var gain := 1.0
	var weight := 0.0

static var _manifest: Dictionary
var _active := Track.new()
var _outgoing := Track.new()
var _elapsed := FADE_SECONDS
var _start_in := 0.0
var _start_out := 0.0
var _paused := false

func _ready() -> void:
	for track: Track in [_active, _outgoing]:
		track.player.bus = &"Music"
		add_child(track.player)
	set_process(false)

static func manifest() -> Dictionary:
	if _manifest.is_empty() and FileAccess.file_exists(MANIFEST_PATH):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if data is Dictionary:
			_manifest = data
	return _manifest

static func cue_for(route: StringName, stage_id := &"") -> String:
	match route:
		&"menu", &"name", &"recovery":
			return MENU
		&"battle", &"sample":
			return FINALE if stage_id == &"C2-10" else STORY
		&"chaos_battle":
			return CHAOS
		&"hq_garden", &"records", &"quiz", &"outreach":
			return LEARNING
		&"settings":
			return ""
	return MANAGEMENT

static func slider_gain(percent: int) -> float:
	return pow(clampf(float(percent) / 100.0, 0.0, 1.0), 1.5)

func player() -> AudioStreamPlayer:
	return _active.player

func current_cue() -> String:
	return _active.cue

func select(cue: String) -> void:
	if cue.is_empty() or cue == _active.cue:
		return
	if cue == _outgoing.cue:
		_swap()
	else:
		var row := _find_track(cue)
		var path: String = row.get("runtime_path", "")
		if path.is_empty() or not ResourceLoader.exists("res://" + path, "AudioStreamOggVorbis"):
			return
		var stream := ResourceLoader.load("res://" + path, "AudioStreamOggVorbis") as AudioStreamOggVorbis
		if stream == null:
			return
		if _active.weight >= _outgoing.weight:
			_swap()
		_stop(_active)
		_active.cue = cue
		_active.gain = db_to_linear(float(row.get("normalization_gain_db", 0.0)))
		_active.player.stream = stream
		_set_weight(_active, 0.0 if _outgoing.player.stream != null else 1.0)
		if AudioServer.get_driver_name() != "Dummy" or not Engine.get_write_movie_path().is_empty():
			_active.player.play()
		_active.player.stream_paused = _paused
	_start_in = _active.weight
	_start_out = _outgoing.weight
	_elapsed = 0.0
	set_process(_outgoing.player.stream != null and not _paused)

func hold(paused: bool) -> void:
	_paused = paused
	for track: Track in [_active, _outgoing]:
		track.player.stream_paused = paused
	set_process(not paused and _outgoing.player.stream != null)

func _process(delta: float) -> void:
	if _paused or _outgoing.player.stream == null:
		return
	_elapsed += delta
	# Complementary linear weights keep a pair's combined amplitude bounded.
	var progress := clampf(_elapsed / FADE_SECONDS, 0.0, 1.0)
	_set_weight(_active, lerpf(_start_in, 1.0, progress))
	_set_weight(_outgoing, _start_out * (1.0 - progress))
	if progress >= 1.0:
		_stop(_outgoing)
		set_process(false)

func _swap() -> void:
	var previous := _active
	_active = _outgoing
	_outgoing = previous

func _set_weight(track: Track, weight: float) -> void:
	track.weight = weight
	track.player.volume_db = linear_to_db(track.gain * weight)

func _stop(track: Track) -> void:
	track.player.stop()
	track.player.stream = null
	track.cue = ""
	_set_weight(track, 0.0)

func _find_track(cue: String) -> Dictionary:
	for row: Dictionary in manifest().get("tracks", []):
		if row.cue_id == cue:
			return row
	return {}

func _exit_tree() -> void:
	_stop(_active)
	_stop(_outgoing)
