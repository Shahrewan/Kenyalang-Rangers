extends SceneTree
## Used by verify_w27_art.py in a disposable project with the real production PNGs.

const UNITS := ["rangers/patrolman", "enemies/e01"]
const RADIUS := 1.5
const SOCKETS := {
	"rangers/patrolman": {"shield": "far_shield_grip", "baton": "near_baton_grip"},
	"enemies/e01": {"pouch": "pouch_pin"},
	"enemies/e02": {"satchel": "satchel_pin"},
}

var failures := 0
var samples := 0
var part_count := 0
var clip_count := 0
var proof := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var units := Array(OS.get_cmdline_user_args())
	if units.is_empty():
		units = UNITS
	for unit: String in units:
		_check_unit(unit)
	var out := FileAccess.open("res://probe_result.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"sampled_poses": samples, "units": proof}, "  "))
	print("Cutout QA: %d imported parts, %d pose contracts, %d neutral and animated samples, %d failures" % [part_count, clip_count, samples, failures])
	quit(1 if failures else 0)


func _check_unit(unit: String) -> void:
	var path := "res://assets/source-art/" + unit + "/"
	var manifest: Dictionary = _json(path + "manifest.json")
	var contract: Dictionary = _json(path + "animation_contract.json")
	var rig: Node2D = load("res://" + unit.get_file() + ".tscn").instantiate()
	root.add_child(rig)
	var facing: Node2D = rig.get_node("Facing")
	var player: AnimationPlayer = rig.get_node("AnimationPlayer")
	var bones := {}
	var sprites := {}
	var images := {}
	var art_parts: Array = manifest.parts
	part_count += art_parts.size()
	clip_count += contract.states.size()
	if manifest.has("derived_badge"):
		_check_badge(manifest.derived_badge)
	for bone: Bone2D in facing.find_children("*", "Bone2D", true, false):
		bones[String(bone.name)] = bone
	_check(bones.size() == art_parts.size(), unit + " bone count")

	for part: Dictionary in art_parts:
		var id: String = part.id
		var bone: Bone2D = bones[id]
		var sprite: Sprite2D = bone.get_node("Art")
		var pixels := sprite.texture.get_image()
		sprites[id] = sprite
		images[id] = pixels
		var parent_pivot := _vector(manifest.ground_anchor_units)
		if part.parent != null:
			_check(bone.get_parent() == bones[part.parent], unit + " parent " + id)
			for candidate: Dictionary in art_parts:
				if candidate.id == part.parent:
					parent_pivot = _vector(candidate.pivot_canvas_units)
					break
		_check(bone.position.is_equal_approx(_vector(part.pivot_canvas_units) - parent_pivot), unit + " rest pivot " + id)
		_check(bone.rest.origin.is_equal_approx(bone.position), unit + " rest transform " + id)
		_check(pixels.get_size() == Vector2i(int(part.canvas_rect_px[2]), int(part.canvas_rect_px[3])), unit + " texture dimensions " + id)
		_check(pixels.detect_alpha() != Image.ALPHA_NONE and pixels.get_pixel(0, 0).a == 0.0, unit + " texture alpha " + id)
		_check(sprite.texture.resource_path == "res://" + part.png, unit + " texture path " + id)
		_check(sprite.scale == Vector2(0.25, 0.25) and not sprite.centered and not sprite.z_as_relative, unit + " sprite placement " + id)
		_check(sprite.position.is_equal_approx(-0.25 * _vector(part.pivot_local_px)), unit + " crop offset " + id)
		_check(sprite.z_index == int(part.draw_order), unit + " draw order " + id)

	_install_clips(player, bones, rig, contract.states)
	var snapshots := {}
	for side: int in [1, -1]:
		facing.transform = Transform2D(Vector2(side, 0), Vector2.DOWN, Vector2.ZERO)
		_check(facing.global_position == Vector2.ZERO, unit + " mirror anchor")
		_sample(unit, "neutral %s" % side, art_parts, bones, sprites, images, manifest.sockets)
		snapshots["neutral_%s" % side] = _capture(art_parts, sprites)
		for clip_name: String in contract.states:
			var clip: Dictionary = contract.states[clip_name]
			var length := float(clip.keys[-1][0])
			player.stop()
			player.play(clip_name)
			player.advance(0.0)
			var schedule: Array[float] = []
			for tick: int in range(ceili(length * int(contract.sampling_fps)) + 1):
				schedule.append(minf(float(tick) / int(contract.sampling_fps), length))
			for frame: Array in clip.keys:
				schedule.append(float(frame[0]))
			for seconds: float in schedule:
				player.seek(seconds, true)
				_sample(unit, "%s %.4f facing %d" % [clip_name, seconds, side], art_parts, bones, sprites, images, manifest.sockets)
			var review_time := float(clip.keys[clip.keys.size() / 2][0])
			if clip.has("accent"):
				review_time = float(clip.accent.preview_seconds)
			elif clip.playback == "hold":
				review_time = length
			# Show the longest walking stride and the strongest blocking stance.
			elif clip_name in ["Move", "Block", "Blocked"]:
				review_time = 0.0
			player.play(clip_name)
			player.seek(review_time, true)
			snapshots["%s_%s" % [clip_name, side]] = _capture(art_parts, sprites)
		player.stop()
		for bone: Bone2D in bones.values():
			bone.transform = bone.rest

	_test_playback(unit, player, contract, bones, art_parts, sprites)
	proof[unit] = snapshots
	rig.free()


func _check_badge(record: Dictionary) -> void:
	var texture := load("res://" + String(record.path)) as Texture2D
	if texture == null:
		_check(false, "Derived badge texture")
		return
	var image := texture.get_image()
	var bounds: Array = record.art_bounds_px
	var expected := Rect2i(int(bounds[0]), int(bounds[1]), int(bounds[2] - bounds[0]), int(bounds[3] - bounds[1]))
	_check(image.get_size() == Vector2i(_vector(record.dimensions_px)), "Derived badge dimensions")
	_check(image.get_used_rect() == expected and image.detect_alpha() != Image.ALPHA_NONE, "Derived badge alpha bounds")


func _install_clips(player: AnimationPlayer, bones: Dictionary, rig: Node2D, states: Dictionary) -> void:
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library := AnimationLibrary.new()
	for clip_name: String in states:
		var state: Dictionary = states[clip_name]
		var animation := Animation.new()
		animation.length = float(state.keys[-1][0])
		animation.loop_mode = Animation.LOOP_LINEAR if state.playback == "loop" else Animation.LOOP_NONE
		var translation := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(translation, NodePath(String(rig.get_path_to(bones.torso)) + ":position"))
		for key: Array in state.keys:
			animation.track_insert_key(translation, float(key[0]), bones.torso.rest.origin + Vector2(0, float(key[1])))
		for bone_id: String in bones:
			var rotation := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(rotation, NodePath(String(rig.get_path_to(bones[bone_id])) + ":rotation"))
			for key: Array in state.keys:
				animation.track_insert_key(rotation, float(key[0]), deg_to_rad(float(key[2].get(bone_id, 0))))
		library.add_animation(clip_name, animation)
	player.add_animation_library("", library)
	for clip_name: String in states:
		var state: Dictionary = states[clip_name]
		if state.playback == "return":
			player.animation_set_next(clip_name, state.next)


func _test_playback(unit: String, player: AnimationPlayer, contract: Dictionary,
		bones: Dictionary, art_parts: Array, sprites: Dictionary) -> void:
	for clip_name: String in contract.states:
		var state: Dictionary = contract.states[clip_name]
		var duration := float(state.keys[-1][0])
		player.stop()
		player.play(clip_name)
		player.advance(0)
		var start := _capture(art_parts, sprites)
		player.advance(0)
		_check(_capture(art_parts, sprites) == start, unit + " paused pose " + clip_name)
		player.advance(2.0 / 60)
		var sped := _capture(art_parts, sprites)
		player.seek(2.0 / 60, true)
		_check(_capture(art_parts, sprites) == sped, unit + " 2x combat delta " + clip_name)

		match state.playback:
			"loop":
				player.seek(duration - 0.01, true)
				player.advance(0.02)
				_check(is_equal_approx(player.current_animation_position, 0.01), unit + " loop " + clip_name)
			"return":
				var target: String = state.next
				player.advance(duration + 0.02)
				_check(player.current_animation == target, unit + " return " + clip_name)
				if state.has("return_if_blocking"):
					player.animation_set_next(clip_name, state.return_if_blocking)
					player.stop()
					player.play(clip_name)
					player.advance(duration + 0.02)
					_check(player.current_animation == state.return_if_blocking, unit + " blocked return " + clip_name)
					player.animation_set_next(clip_name, target)
			"hold":
				player.seek(duration - 0.01, true)
				player.advance(0.02)
				var final_pose := _capture(art_parts, sprites)
				player.advance(0.5)
				_check(_capture(art_parts, sprites) == final_pose, unit + " terminal hold " + clip_name)
	player.stop()
	for bone: Bone2D in bones.values():
		bone.transform = bone.rest


func _sample(unit: String, label: String, parts: Array, bones: Dictionary,
		sprites: Dictionary, images: Dictionary, sockets: Dictionary) -> void:
	samples += 1
	for part: Dictionary in parts:
		var id: String = part.id
		if part.parent == null:
			continue
		var joint: Vector2 = bones[id].global_position
		for offset: Vector2 in _radial_offsets():
			var point := joint + offset
			var joined := _opaque_at(sprites[id], images[id], point) and _opaque_at(sprites[part.parent], images[part.parent], point)
			if not joined:
				_check(false, "%s %s joint %s" % [unit, label, id])
				break

	var grip_pairs: Dictionary = SOCKETS.get(unit, {})
	for prop_id: String in grip_pairs:
		var socket: Dictionary = sockets[grip_pairs[prop_id]]
		var socket_part: Bone2D = bones[socket.part]
		var local := _vector(socket.canvas_units) - _rest_canvas_pivot(parts, socket.part)
		_check(socket_part.to_global(local).distance_to(bones[prop_id].global_position) < 0.001,
			unit + " grip socket " + prop_id)


func _rest_canvas_pivot(parts: Array, id: String) -> Vector2:
	for part: Dictionary in parts:
		if part.id == id:
			return _vector(part.pivot_canvas_units)
	return Vector2.INF


func _opaque_at(sprite: Sprite2D, image: Image, position: Vector2) -> bool:
	var point := Vector2i(sprite.to_local(position).floor())
	return Rect2i(Vector2i.ZERO, image.get_size()).has_point(point) and image.get_pixelv(point).a >= 0.94


func _radial_offsets() -> PackedVector2Array:
	var offsets := PackedVector2Array([Vector2.ZERO])
	for i: int in range(8):
		offsets.append(Vector2.from_angle(i * TAU / 8) * RADIUS)
	return offsets


func _capture(parts: Array, sprites: Dictionary) -> Dictionary:
	var transforms := {}
	for part: Dictionary in parts:
		var sprite: Sprite2D = sprites[part.id]
		var tx := sprite.global_transform
		transforms[part.id] = [tx.x.x, tx.x.y, tx.y.x, tx.y.y, tx.origin.x, tx.origin.y]
	return transforms


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _vector(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
