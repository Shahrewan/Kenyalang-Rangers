extends SceneTree

class CapturingMixer extends PresentationAudio:
	func _start_player(player: AudioStreamPlayer) -> void:
		player.play()

const CASES := [
	[&"battle", &"C1-01", 111.8, "Epic Nusantara"],
	[&"chaos_battle", &"", 98.9, "The Tribe"],
	[&"battle", &"C2-10", 11.7, "Epic Gamelan"],
]
const DENSE_CUES := [
	"ranger_scout_sniper_attack", "enemy_ranged_light", "ranger_guard_attack",
	"facility_sonic_turret_attack", "combat_siege_warning",
	"enemy_e15_priority_warning", "combat_heat_overflow", "combat_boss_alert",
]
var _mixer: CapturingMixer
var _capture := AudioEffectCapture.new()
var _master := 0
var _failed := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_mixer = CapturingMixer.new()
	_mixer.path = "user://c38-mix-probe-%d.json" % OS.get_process_id()
	root.add_child(_mixer)
	_mixer.values = {"master": 100, "music": 100, "sfx": 100, "text": 100}
	_mixer._mix()
	_master = AudioServer.get_bus_index(&"Master")
	_capture.buffer_length = 1.0
	AudioServer.add_bus_effect(_master, _capture)
	for row: Array in CASES:
		await _dense(row)
	await _crossfade()
	await _independent_mute()
	await _limiter()
	_mixer._clear_effects()
	_mixer.music.stop()
	await create_timer(0.10).timeout
	AudioServer.remove_bus_effect(_master, 1)
	_mixer.free()
	await process_frame
	quit(1 if _failed else 0)

func _dense(row: Array) -> void:
	_mixer.set_route(row[0], row[1])
	_mixer._soundtrack._process(Soundtrack.FADE_SECONDS)
	_mixer.music.stop()
	await create_timer(0.075).timeout
	_capture.clear_buffer()
	_mixer.music.play(row[2])
	for cue: String in DENSE_CUES:
		_mixer.cue(cue)
	_mixer._process(0.0)
	var voices := 0
	for voice: PresentationAudio.Voice in _mixer._voices:
		if voice.player.playing:
			voices += 1
	await create_timer(0.55).timeout
	var stats := _read()
	print("Dense ", row[3], " @ ", row[2], " s: ", voices, " SFX voices, ", stats)
	_assert(voices == 8 and stats.frames > 1000 and stats.peak > 0.30 and stats.peak <= db_to_linear(-1.5) + 0.005,
		"Dense buffer contains eight admitted sounds and stays below the master ceiling")
	_mixer._clear_effects()

func _crossfade() -> void:
	_mixer.set_route(&"menu")
	_mixer._soundtrack._process(Soundtrack.FADE_SECONDS)
	_mixer.music.play(38.0)
	await create_timer(0.06).timeout
	_capture.clear_buffer()
	_mixer.set_route(&"headquarters")
	_mixer.music.play(58.0)
	await create_timer(Soundtrack.FADE_SECONDS + 0.05).timeout
	var stats := _read()
	print("Music-only crossfade: ", stats)
	_assert(stats.frames > 1000 and stats.peak > 0.15 and stats.peak <= db_to_linear(-5.5) + 0.01,
		"Crossfade stays within the higher of the two normalized track peaks")
	_mixer.music.stop()

func _independent_mute() -> void:
	_mixer.music.play(58.0)
	_mixer.values.music = 0
	_mixer._mix()
	await create_timer(0.1).timeout
	_capture.clear_buffer()
	await create_timer(0.12).timeout
	var silent_music := _read()
	_mixer.cue("combat_boss_alert")
	_mixer._process(0.0)
	await create_timer(0.22).timeout
	var effects := _read()
	print("Music muted, music-only and SFX peaks: ", silent_music.peak, ", ", effects.peak)
	_assert(silent_music.frames > 1000 and silent_music.peak == 0.0 and effects.peak > 0.02,
		"Music hard mute yields zero samples while SFX remains live")
	_mixer.values.music = 50
	_mixer.values.sfx = 0
	_mixer._mix()
	_capture.clear_buffer()
	await create_timer(0.18).timeout
	var music := _read()
	_assert(music.peak > 0.01, "SFX mute leaves normalized music in the mix")
	_mixer.values.master = 0
	_mixer._mix()
	await create_timer(0.10).timeout
	_capture.clear_buffer()
	await create_timer(0.15).timeout
	var silent_master := _read()
	var left := AudioServer.get_bus_peak_volume_left_db(_master, 0)
	var right := AudioServer.get_bus_peak_volume_right_db(_master, 0)
	print("SFX-muted music peak: ", music.peak, ", Master mute post-fader meters dB: ", left, ", ", right)
	# The Master effect slot is before its fader. The output meter is after it.
	_assert(silent_master.frames > 1000 and AudioServer.is_bus_mute(_master) and maxf(left, right) < -95.0, "Master mutes the output after the effects chain")
	_mixer.values = {"master": 100, "music": 100, "sfx": 100, "text": 100}
	_mixer._mix()
	_mixer.music.stop()

func _limiter() -> void:
	var signal_wave := AudioStreamWAV.new()
	signal_wave.format = AudioStreamWAV.FORMAT_16_BITS
	signal_wave.mix_rate = 32000
	var data := PackedByteArray()
	data.resize(32000 * 2)
	for index in 32000:
		data.encode_s16(index * 2, roundi(28000.0 * sin(TAU * index * 440.0 / 32000.0)))
	signal_wave.data = data
	var twins: Array[AudioStreamPlayer] = []
	for i in 2:
		var source := AudioStreamPlayer.new()
		source.bus = &"SFX"
		source.stream = signal_wave
		root.add_child(source)
		twins.append(source)
	for enabled: bool in [false, true]:
		AudioServer.set_bus_effect_enabled(_master, 0, enabled)
		await create_timer(0.075).timeout
		_capture.clear_buffer()
		for source in twins:
			source.play()
		await create_timer(0.32).timeout
		var stats := _read()
		print("Calibrated overload, limiter ", enabled, ": ", stats)
		_assert(stats.peak <= db_to_linear(-1.5) + 0.005 if enabled else stats.peak > 1.0,
			"Calibrated overload demonstrates the safety limiter")
		for source in twins:
			source.stop()
	for source in twins:
		source.free()

func _read() -> Dictionary:
	var data := _capture.get_buffer(_capture.get_frames_available())
	var peak := 0.0
	var power := 0.0
	for sample: Vector2 in data:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		power += sample.length_squared()
	return {"frames": data.size(), "peak": peak, "peak_dbfs": linear_to_db(peak),
		"rms_dbfs": linear_to_db(sqrt(power / maxf(1.0, data.size() * 2.0)))}

func _assert(ok: bool, text: String) -> void:
	if not ok:
		_failed = true
		printerr("FAIL ", text)
