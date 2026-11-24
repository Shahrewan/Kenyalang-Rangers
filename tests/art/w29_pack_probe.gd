extends SceneTree

const CATALOG := "res://data/presentation/w29/art_catalog.json"
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _json(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(data is Dictionary, "Read manifest " + path)
	return data if data is Dictionary else {}

func _packed(path: String) -> Node:
	var packed := load(path) as PackedScene
	_check(packed != null, "Load scene " + path)
	return packed.instantiate() if packed != null else null

func _run() -> void:
	var catalog := _json(CATALOG)
	_check(catalog.actors.size() == 31, "All 30 field identities and the K9 companion")
	_check(catalog.facilities.size() == 13 and catalog.environments.size() == 6, "All Facilities and boards")
	for id: String in catalog.actors:
		_actor(id, catalog.actors[id])
	for id: String in catalog.facilities:
		_facility(id, catalog.facilities[id])
	for id: String in catalog.environments:
		if id != "T01":
			_json(catalog.environments[id])
	_headquarters(_json(catalog.headquarters))
	_support(_json(catalog.support_receipts), _json(catalog.portrait_receipts))
	_heat(catalog.heat_meter)
	_check(load(catalog.menu_theme) is Theme, "Menu theme imports into Godot")
	print("W29 assembled art: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _actor(id: String, record: Dictionary) -> void:
	var rig := _packed(record.rig) as Node2D
	if rig == null:
		return
	root.add_child(rig)
	_check(rig.find_children("*", "Sprite2D", true, false).size() >= record.part_count, id + " part nodes")
	if record.has("badge"):
		_check(load(record.badge) is Texture2D, id + " badge")
	if record.has("animation"):
		var driver := rig as FirstContactCutout
		_check(driver != null, id + " presentation driver")
		if driver != null:
			var contract := _json(record.animation)
			var player := driver.player
			_check(player.get_animation_list().size() == record.state_count, id + " animation count")
			for clip: String in contract.states:
				driver.play_state(clip)
				driver.advance_combat(player.get_animation(clip).length * 0.35)
				_check(player.current_animation == clip, id + " animation " + clip)
			driver.set_facing(-1)
			_check(is_equal_approx(rig.get_node("Facing").transform.determinant(), -1.0), id + " mirror")
	rig.free()

func _facility(id: String, record: Dictionary) -> void:
	var rig := _packed(record.rig) as Node2D
	if rig == null:
		return
	root.add_child(rig)
	var player := rig.get_node("AnimationPlayer") as AnimationPlayer
	for state: String in record.states:
		_check(player.has_animation(state), id + " facility state " + state)
	var sentry := id == "facility.sentry_tower"
	_check(rig.has_node("MountSocket") == sentry, id + " tower mount")
	_check(record.footprint.size() == (1 if sentry else 2), id + " facility footprint")
	_check(record.reserved.size() == (1 if sentry else 0), id + " facility above reservation")
	rig.free()

func _headquarters(manifest: Dictionary) -> void:
	_check(manifest.rooms.size() == 11, "HQ has all named rooms")
	var distinct := {}
	for room: Dictionary in manifest.rooms:
		distinct[room.id] = true
		for layer: String in room.assets:
			_texture(room.assets[layer].texture, room.assets[layer].dimensions)
		_texture(room.detail.texture, room.detail.dimensions)
		var staff: Dictionary = room.staff
		var rig := _packed("res://" + staff.rig) as Node2D
		if rig == null:
			continue
		root.add_child(rig)
		var player := rig.get_node("AnimationPlayer") as AnimationPlayer
		var hand := rig.get_node("Facing/Skeleton/torso/hand") as Bone2D
		var boots := rig.get_node("Facing/Skeleton/legs") as Bone2D
		var base := boots.transform
		var clip: String = staff.clip
		var anim := player.get_animation(clip)
		_check(anim.loop_mode == Animation.LOOP_LINEAR, room.id + " stationary loop")
		_check(is_equal_approx(anim.length, float(staff.duration)), room.id + " loop duration")
		player.play(clip)
		player.seek(anim.length * 0.24, true)
		_check(absf(hand.rotation_degrees) > 1.0, room.id + " moves the active arm")
		_check(boots.transform.is_equal_approx(base) and rig.position == Vector2.ZERO, room.id + " planted feet")
		player.seek(anim.length, true)
		_check(is_zero_approx(hand.rotation_degrees), room.id + " neutral match at loop boundary")
		rig.free()
	_check(distinct.size() == 11, "HQ room IDs are unique")

func _texture(path: String, size: Array) -> void:
	var full := path if path.begins_with("res://") else "res://" + path
	var image := load(full) as Texture2D
	_check(image != null and image.get_size() == Vector2(size[0], size[1]), "Texture dimensions " + path)

func _support(support: Dictionary, portraits: Dictionary) -> void:
	for id: String in support.exports:
		var record: Dictionary = support.exports[id]
		_texture(record.path, [record.width, record.height])
	var poses := 0
	for id: String in portraits.portraits:
		for pose: Dictionary in portraits.portraits[id].values():
			var card: Dictionary = pose.texture
			_texture(card.path, [card.width, card.height])
			for layer: Dictionary in pose.layers:
				_texture(layer.path, [layer.width, layer.height])
			poses += 1
	_check(poses == 9, "New story and Outreach poses")
	_check(portraits.speaker_aliases.get("speaker.poacher_messenger") == "portrait.poacher", "Messenger uses Poacher art")

func _heat(path: String) -> void:
	var scene := _packed(path) as Control
	if scene == null:
		return
	root.add_child(scene)
	var gauge := scene.get_node("HeatGauge") as TextureProgressBar
	_check(gauge.texture_under != null and gauge.texture_progress != null, "Heat track and fill")
	for cap: float in [73.0, 100.0]:
		gauge.max_value = cap
		for normalized: float in [0.0, 0.25, 0.52, 1.0]:
			gauge.value = normalized * cap
			_check(absf(gauge.ratio - normalized) < 0.002, "Heat visual ratio/%s at %s" % [cap, normalized])
	scene.free()
