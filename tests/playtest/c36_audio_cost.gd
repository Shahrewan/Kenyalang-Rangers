extends SceneTree

const GROUPS := [
	"ranger_scout_sniper_attack", "ranger_melee_attack", "enemy_ranged_light",
	"facility_electric_pulse_turret_attack", "boss_diversion_captain_intro",
	"boss_illegal_logging_foreman_phase", "result_victory", "result_defeat",
]
const BLOCKS := 400
const FRAMES := 256

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var groups: Dictionary = PresentationAudio.catalog().groups
	var mixer := PresentationAudio.new()
	root.add_child(mixer)
	var before := Performance.get_monitor(Performance.MEMORY_STATIC)
	for row: Dictionary in groups.values():
		for path: String in row.paths:
			assert(mixer._resource(path) != null)
	var warm := Performance.get_monitor(Performance.MEMORY_STATIC)
	var cached_bytes := 0
	for stream: AudioStreamWAV in mixer._cache.values():
		cached_bytes += stream.data.size()
	print("C36 warm cache files ", mixer._cache.size(), ", stream bytes ", cached_bytes,
		", engine tracked memory delta ", int(warm - before), " bytes")
	var voices: Array[AudioStreamPlayback] = []
	var qoa := 0
	for group: String in GROUPS:
		var stream := mixer._resource(groups[group].paths[0])
		if stream.format == AudioStreamWAV.FORMAT_QOA:
			qoa += 1
		voices.append(stream.instantiate_playback())
	_sample(voices, voices.size())
	_sample(voices, 1)
	print("Hardware-independent Godot decoder and mix-buffer timing, ", qoa,
		" QOA and ", voices.size() - qoa, " PCM test streams")
	mixer.free()
	quit()

func _sample(voices: Array[AudioStreamPlayback], count: int) -> void:
	for voice: AudioStreamPlayback in voices:
		voice.start()
	var total := 0
	var worst := 0
	for block in BLOCKS:
		var start := Time.get_ticks_usec()
		for i in count:
			if not voices[i].is_playing():
				voices[i].start()
			var buffer := voices[i].mix_audio(1.0, FRAMES)
			assert(buffer.size() <= FRAMES)
		var elapsed := Time.get_ticks_usec() - start
		total += elapsed
		worst = maxi(worst, elapsed)
	print(count, " voice(s), mean ", float(total) / BLOCKS, " μs and worst ",
		worst, " μs per ", FRAMES, " stereo frames across ", BLOCKS, " blocks")
