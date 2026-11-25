extends SceneTree

var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var assets := CampaignVisualAssets.new()
	var scene := assets.rig(assets.actor(&"E04"))
	var other_scene := assets.rig(assets.actor(&"E03"))
	var first := scene.instantiate() as FirstContactCutout
	var second := scene.instantiate() as FirstContactCutout
	var other := other_scene.instantiate() as FirstContactCutout
	root.add_child(first)
	root.add_child(second)
	root.add_child(other)
	var shared: WeakRef = weakref(first.player.get_animation_library(&""))
	_check(shared.get_ref() == second.player.get_animation_library(&""), "Identical enemy rigs share one clip library")
	_check(shared.get_ref() != other.player.get_animation_library(&""), "Different rig scenes keep separate contracts")
	var second_torso := second.find_child("torso", true, false) as Bone2D
	var second_pose := second_torso.transform
	var second_time := second.player.current_animation_position
	first.play_state(&"Attack")
	first.advance_combat(0.15)
	first.set_facing(-1)
	_check(first.player.current_animation == &"Attack" and first.player.current_animation_position > 0.0,
		"Playing a shared clip advances the first player's clock")
	_check(second.player.current_animation == second.default_state and second.player.current_animation_position == second_time
		and second_torso.transform == second_pose and second.get_node("Facing").transform.x.x == 1.0,
		"Advancing and mirroring one rig leaves the other rig's playback, pose and facing intact")
	first.free()
	_check(is_instance_valid(shared.get_ref()), "The surviving rig keeps the clip library alive")
	second.free()
	await process_frame
	_check(shared.get_ref() == null, "Scene teardown releases unused animation data")
	var reopened := scene.instantiate() as FirstContactCutout
	root.add_child(reopened)
	_check(reopened.player.has_animation(&"Attack") and reopened.player.current_animation == reopened.default_state,
		"Re-entering a scene recreates and plays its valid library")
	reopened.free()
	other.free()
	print("C34 animation cache: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
