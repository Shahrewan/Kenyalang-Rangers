extends SceneTree

const PREVIEW := preload("res://scenes/qa/scout_rig_preview.tscn")
const MANIFEST := "res://assets/source-art/rangers/scout_sniper/manifest.json"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var preview := PREVIEW.instantiate()
	root.add_child(preview)
	preview.set_physics_process(false)
	await process_frame
	var rig: ScoutRig = preview.rig
	var facing: Node2D = rig.get_node("Facing")
	var skeleton: Skeleton2D = facing.get_node("Skeleton")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var torso: Bone2D = rig.get_node(ScoutRig.TORSO)
	_check(skeleton.get_bone_count() == 19, "Manifest parts each have a real Bone2D")
	var registered := true
	for part: Dictionary in manifest.parts:
		var bone := skeleton.find_child(part.id, true, false) as Bone2D
		var sprite: Sprite2D = bone.get_node("Art")
		var joint := Vector2(part.pivot_local_px[0], part.pivot_local_px[1])
		var expected := Vector2(part.pivot_canvas_units[0] - manifest.ground_anchor_units[0], part.pivot_canvas_units[1] - manifest.ground_anchor_units[1])
		registered = registered and facing.to_local(bone.global_position).is_equal_approx(expected)
		registered = registered and (sprite.position + joint * sprite.scale).is_zero_approx()
		registered = registered and sprite.texture.resource_path == "res://" + part.png and sprite.z_index == part.draw_order
		if part.parent != null:
			registered = registered and String(bone.get_parent().name) == part.parent
	_check(registered, "All neutral poses honor source parents, pivots, textures and draw order")
	for clip in ScoutRig.CLIPS:
		rig.play_state(clip)
		var neutral := torso.transform
		rig.advance_combat(0.12)
		_check(rig.player.current_animation == clip and torso.transform != neutral, "Running animation changes Bone2D pose: " + clip)
	rig.play_state(&"Attack")
	rig.advance_combat(0.20)
	rig.advance_combat(0.20)
	_check(rig.player.current_animation == &"Idle", "Attack returns to Idle")
	rig.play_state(&"Idle")
	var clock: CombatClock = preview.clock
	for i in 6:
		clock.advance_frame()
	var pose := torso.transform
	clock.paused = true
	for i in 12:
		clock.advance_frame()
	_check(torso.transform == pose and clock.tick == 6, "Pause holds actual bone transforms")
	clock.paused = false
	clock.set_speed(2)
	for i in 3:
		clock.advance_frame()
	var fast := torso.transform
	rig.play_state(&"Idle")
	for i in 12:
		rig.advance_combat(CombatClock.STEP_SECONDS)
	_check(torso.transform.is_equal_approx(fast), "2× repeats the same fixed animation steps")
	var anchor := rig.global_position
	var right := torso.global_position
	rig.set_facing(-1)
	_check(facing.transform.x.x == -1.0 and rig.global_position == anchor and is_equal_approx(torso.global_position.x + right.x, 2 * anchor.x), "Facing flips around the fixed ground anchor")
	rig.facing_locked = true
	rig.set_facing(1)
	_check(facing.transform.x.x == -1.0, "Locked-facing fixture rejects direction changes")
	preview.queue_free()
	print("Scout rig checks complete. Failures: ", failures)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		failures += 1
