extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const VOLUME_STEPS := [0, 25, 50, 75, 100]
const EXPECTED_DB := [0.0, -18.0618, -9.0309, -3.7482, 0.0]
var _checks := 0
var _failures := 0
var _path := "user://c38-music-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	_routes_and_mix()
	_loops()
	await _live_launcher()
	for suffix in ["", ".settings", ".legacy", ".bak", ".settings.bak", ".tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C38 soundtrack: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _routes_and_mix() -> void:
	var bank := PresentationAudio.new()
	bank.path = _path + ".settings"
	root.add_child(bank)
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	var master := AudioServer.get_bus_index(&"Master")
	_check(AudioServer.get_bus_send(music_bus) == &"Master" and AudioServer.get_bus_send(sfx_bus) == &"Master", "Music and SFX use independent sends to Master")
	_check(AudioServer.get_bus_effect(master, 0) is AudioEffectHardLimiter, "Master has mix-only peak protection")
	var contexts := [
		[&"menu", &"", Soundtrack.MENU], [&"headquarters", &"", Soundtrack.MANAGEMENT],
		[&"hq_room", &"", Soundtrack.MANAGEMENT], [&"plan", &"", Soundtrack.MANAGEMENT],
		[&"battle", &"C1-01", Soundtrack.STORY], [&"battle", &"C2-10", Soundtrack.FINALE],
		[&"chaos_battle", &"", Soundtrack.CHAOS], [&"hq_garden", &"", Soundtrack.LEARNING],
		[&"records", &"", Soundtrack.LEARNING], [&"quiz", &"", Soundtrack.LEARNING],
		[&"outreach", &"", Soundtrack.LEARNING],
	]
	for index in VOLUME_STEPS.size():
		var level: int = VOLUME_STEPS[index]
		_check(bank.change("music", level), "Music setting %d%% saves" % level)
		for context: Array in contexts:
			bank.set_route(context[0], context[1])
			bank._soundtrack._process(Soundtrack.FADE_SECONDS)
			var stream := bank.music.stream as AudioStreamOggVorbis
			_check(stream != null and bank.music.bus == &"Music" and bank._soundtrack.current_cue() == context[2]
				and stream.resource_path.ends_with(context[2] + ".ogg"), "%s %s loads the right stream at %d%%" % [context[0], context[1], level])
			_check(AudioServer.is_bus_mute(music_bus) == (level == 0)
				and absf(AudioServer.get_bus_volume_db(music_bus) - EXPECTED_DB[index]) < 0.01,
				"Changing %s preserves Music bus level %d%%" % [context[0], level])
	bank.set_route(&"headquarters")
	bank._soundtrack._process(Soundtrack.FADE_SECONDS)
	var player := bank.music
	var track_gain := player.volume_db
	bank.set_route(&"hq_room")
	_check(bank.music == player and bank.music.volume_db == track_gain and not bank._soundtrack.is_processing(), "HQ and department navigation preserve the same stream and playhead")
	bank.change("music", 25)
	_check(bank.music.volume_db == track_gain and not AudioServer.is_bus_mute(sfx_bus), "User Music setting changes only its bus")
	bank.change("music", 0)
	_check(AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(sfx_bus), "Music zero is hard mute while SFX stays audible")
	bank.change("music", 50)
	bank.change("sfx", 0)
	_check(not AudioServer.is_bus_mute(music_bus) and AudioServer.is_bus_mute(sfx_bus), "SFX zero leaves Music audible")
	bank.change("sfx", 75)
	bank.change("master", 0)
	_check(AudioServer.is_bus_mute(master), "Master zero hard-mutes both category sends")
	bank.change("master", 80)
	bank.set_route(&"battle", &"C2-10")
	var soundtrack := bank._soundtrack
	soundtrack._process(0.18)
	var halfway := soundtrack._elapsed
	bank.background(true)
	soundtrack._process(1.0)
	_check(soundtrack._paused and soundtrack._elapsed == halfway and soundtrack._outgoing.player.stream != null, "Background freezes the music transition")
	bank.background(false)
	soundtrack._process(0.05)
	_check(soundtrack._active.weight + soundtrack._outgoing.weight <= 1.000001 and not soundtrack._paused, "Resumed fade remains inside unity envelope")
	bank.set_route(&"headquarters")
	_check(bank.music == player and soundtrack._active.weight + soundtrack._outgoing.weight <= 1.000001, "Reversing a fade reuses the still-playing theme")
	soundtrack._process(Soundtrack.FADE_SECONDS)
	_check(soundtrack._outgoing.player.stream == null and soundtrack._active.weight == 1.0, "Completed fade releases the previous decoder")
	bank.free()
	bank = PresentationAudio.new()
	bank.path = _path + ".settings"
	root.add_child(bank)
	_check(bank.values.music == 50 and bank.values.master == 80 and bank.values.sfx == 75, "Music and mix settings restore after the audio node restarts")
	bank.free()

func _loops() -> void:
	for row: Dictionary in Soundtrack.manifest().tracks:
		var track := load("res://" + String(row.runtime_path)) as AudioStreamOggVorbis
		_check(track.loop and track.loop_offset == 0.0 and absf(track.get_length() - float(row.loop_points.end_seconds)) < 0.01,
			"%s ships the baked full-file loop" % row.title)
		var playback := track.instantiate_playback()
		playback.start()
		var wraps_with_signal := 0
		for block in ceili((track.get_length() * 2.0 + 0.2) * AudioServer.get_mix_rate() / 4096):
			var prior := playback.get_loop_count()
			var pcm := playback.mix_audio(1.0, 4096)
			if playback.get_loop_count() == prior:
				continue
			for frame: Vector2 in pcm:
				if frame.length_squared() > 0.00001:
					wraps_with_signal += 1
					break
		_check(playback.get_loop_count() == 2 and wraps_with_signal == 2 and playback.is_playing(),
			"%s decodes both consecutive wraps with nonzero buffers" % row.title)
		playback.stop()

func _live_launcher() -> void:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	app.save_path = _path + ".legacy"
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.rooms[String(HeadquartersCatalog.CONTROL)] = 5
	profile.rooms[String(HeadquartersCatalog.MECHANICAL)] = 1
	var content := CampaignContent.new()
	for operation: StoryOperation in content.operations:
		if operation.stage.stage_id != &"C2-10":
			profile.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
	ProfileFile.replace(_path, profile, false)
	root.add_child(app)
	app.presentation.change("text", 130)
	app._restyle()
	app._screen.get_node("%OpenFAQ").pressed.emit()
	_press(app._guide, "References")
	_check(_has_label(app._guide, "Forest Department Sarawak") and _has_label(app._guide, "Arknights"), "Main Menu FAQ still shows education and art references")
	_press(app._guide, FieldGuide.CREDITS)
	await process_frame
	await process_frame
	_check(_has_label(app._guide, "Music and Audio Credits") and _has_label(app._guide, "Godot Engine"), "Offline music credits and the engine license share the existing credits page")
	for row: Dictionary in Soundtrack.manifest().tracks:
		_check(_has_label(app._guide, row.title) and _has_label(app._guide, row.artist) and _has_label(app._guide, row.source_url),
			"Offline credits contain the title, creator and source of %s" % row.title)
	var scroll := app._guide._body.get_parent() as ScrollContainer
	_check(scroll.get_v_scroll_bar().max_value > scroll.size.y and not scroll.get_h_scroll_bar().visible,
		"Credits can be vertically scrolled at 960×540 and 130% text")
	var args := OS.get_cmdline_user_args()
	if DisplayServer.get_name() != "headless" and args.size() == 1:
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(args[0]) == OK, "Native rendered Credits screenshot")
		if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
			_press(app._guide, "Copy track source URL")
			_check(DisplayServer.clipboard_get() == Soundtrack.manifest().tracks[0].source_url, "Native clipboard copies the source address")
	app.show_menu()
	app._screen.get_node("%OpenSettings").pressed.emit()
	_press(app._screen, "Help and references")
	_check(_has_label(app._guide, "Offline references"), "Settings Help goes directly to References")
	_press(app._guide, FieldGuide.CREDITS)
	_check(_has_label(app._guide, "Music and Audio Credits"), "Settings reaches the same credits")
	app.show_story()
	app._show_campaign_plan(app._campaign.operation(&"C2-10"))
	app._start_campaign()
	_check(app._screen is CampaignBattle and app.presentation._soundtrack.current_cue() == Soundtrack.FINALE,
		"Real Final Interception route selects the finale theme")
	_check(app._screen is CampaignBattle and app.presentation._soundtrack._paused, "Finale opening still holds music during dialogue")
	app.free()
	await process_frame

func _press(parent: Node, caption: String) -> void:
	if parent != null:
		for button: Node in parent.find_children("*", "Button", true, false):
			if (button as Button).text == caption:
				button.pressed.emit()
				return
	_check(false, "Missing button " + caption)

func _has_label(parent: Node, text: String) -> bool:
	return parent != null and parent.find_children("*", "Label", true, false).any(func(label: Node) -> bool: return text in (label as Label).text)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
