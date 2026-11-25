class_name FirstContactCutout
extends Node2D

@export_file("*.json") var contract_path: String
@onready var player: AnimationPlayer = $AnimationPlayer

const CLIP_LIBRARIES := &"_cutout_clip_libraries"

var facing_locked := false
var default_state: StringName

func _ready() -> void:
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library := _library_for_scene()
	default_state = library.get_meta(&"default_state")
	player.add_animation_library(&"", library)
	play_state(default_state)

func _library_for_scene() -> AnimationLibrary:
	if scene_file_path.is_empty():
		return _build_library()
	var key := "%s|%s" % [scene_file_path, contract_path]
	# The root window owns weak entries so their lifetime follows the tree.
	# Each AnimationPlayer keeps its playback state and the shared tracks.
	var window := get_tree().root
	var libraries: Dictionary = window.get_meta(CLIP_LIBRARIES, {})
	var entry: WeakRef = libraries.get(key)
	var library := entry.get_ref() as AnimationLibrary if entry != null else null
	if library == null:
		library = _build_library()
		libraries[key] = weakref(library)
		window.set_meta(CLIP_LIBRARIES, libraries)
	return library

func _build_library() -> AnimationLibrary:
	var bones: Dictionary[StringName, Bone2D] = {}
	for bone: Bone2D in find_children("*", "Bone2D", true, false):
		bones[bone.name] = bone
	var contract := FirstContactSkin.read_json(contract_path)
	var library := AnimationLibrary.new()
	library.set_meta(&"default_state", StringName(contract.get("default", "Idle")))
	for id: String in contract.get("states", {}):
		var state: Dictionary = contract.states[id]
		var clip := Animation.new()
		clip.length = float(state.keys[-1][0])
		clip.loop_mode = Animation.LOOP_LINEAR if state.playback == "loop" else Animation.LOOP_NONE
		var torso := bones[&"torso"]
		var translation := _track(clip, torso, "position")
		for key: Array in state.keys:
			clip.track_insert_key(translation, float(key[0]), torso.rest.origin + Vector2(0, float(key[1])))
		for bone: Bone2D in bones.values():
			var rotation := _track(clip, bone, "rotation")
			for key: Array in state.keys:
				clip.track_insert_key(rotation, float(key[0]), deg_to_rad(float(key[2].get(String(bone.name), 0))))
		library.add_animation(id, clip)
	return library

func _track(clip: Animation, bone: Bone2D, property: String) -> int:
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("%s:%s" % [get_path_to(bone), property]))
	return track

func play_state(state: StringName) -> void:
	if player.has_animation(state):
		player.stop()
		player.play(state)
		player.advance(0.0)

func advance_combat(seconds: float) -> void:
	player.advance(seconds)

func set_facing(side: int) -> void:
	if not facing_locked:
		$Facing.transform = Transform2D(Vector2(-1 if side < 0 else 1, 0), Vector2.DOWN, Vector2.ZERO)
