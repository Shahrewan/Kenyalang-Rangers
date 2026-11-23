class_name PresentationAudio
extends Node

const DEFAULTS := {"master": 80, "music": 45, "sfx": 75, "text": 100}
const TEXT_SIZES := [100, 115, 130]
const TRACKS := {
	"office": [220, 330, 294, 247, 262, 330, 294, 196],
	"story": [196, 247, 294, 220, 196, 294, 262, 220],
	"chaos": [165, 220, 196, 247, 165, 233, 220, 196],
	"quiet": [262, 392, 330, 294, 247, 330, 294, 196],
}
const CUES := {
	"confirm": [494], "deploy": [330, 494], "invalid": [185, 147],
	"support": [392, 440], "tokens": [659], "skill": [440, 659], "victory": [392, 494, 587], "defeat": [330, 262, 196],
	"recon": [523, 523], "siege": [147, 196, 147], "heat": [294, 349, 392], "boss": [196, 196, 247],
	"water": [587, 494], "collect": [523, 659], "visitor": [784, 659, 880], "education": [392, 523],
}
static var _streams: Dictionary[String, AudioStreamWAV] = {}
var path := "user://presentation.json"
var values := DEFAULTS.duplicate()
var music := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var alerts := AudioStreamPlayer.new()
var _track := ""
var _away := false
var _held := false

func _ready() -> void:
	var saved := ProfileFile.read(path)
	for key: String in DEFAULTS:
		var value: Variant = saved.get(key)
		if valid_setting(key, value):
			values[key] = int(value)
	for player in [music, effects, alerts]:
		add_child(player)
	_mix()

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

func _mix() -> void:
	var master := float(values.master) / 100
	music.volume_db = linear_to_db(master * float(values.music) / 100)
	effects.volume_db = linear_to_db(master * float(values.sfx) / 100)
	alerts.volume_db = effects.volume_db

func set_route(route: StringName) -> void:
	var track := "office"
	if route in [&"battle", &"sample"]:
		track = "story"
	elif String(route).begins_with("chaos"):
		track = "chaos"
	elif route in [&"hq_garden", &"records", &"quiz", &"outreach"]:
		track = "quiet"
	if track != _track:
		_track = track
		music.stream = _sound(track, TRACKS[track], true)
		_start_player(music)
	hold(false)

func hold(paused: bool) -> void:
	_held = paused
	music.stream_paused = _held or _away

func background(away: bool) -> void:
	_away = away
	if away:
		effects.stop()
		alerts.stop()
	hold(_held)

func cue(id: String) -> void:
	if _away or values.master == 0 or values.sfx == 0 or not CUES.has(id):
		return
	var player := alerts if id in ["recon", "siege", "heat", "boss", "victory", "defeat", "visitor"] else effects
	var stream := _sound(id, CUES[id], false)
	if player.playing and player.stream == stream:
		return
	player.stream = stream
	_start_player(player)

func _start_player(player: AudioStreamPlayer) -> void:
	# The headless server has no playback device. Streams remain available for decoding and tests.
	if DisplayServer.get_name() != "headless" or not Engine.get_write_movie_path().is_empty():
		player.play()

func _exit_tree() -> void:
	for player in [music, effects, alerts]:
		player.stop()
		player.stream = null

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
