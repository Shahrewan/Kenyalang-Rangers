class_name ScoutRig
extends Node2D

const TORSO := "Facing/Skeleton/torso"
const CLIPS := [&"Idle", &"Deploy", &"Attack", &"Skill", &"Hit", &"Retreat", &"Defeat"]

@onready var _facing: Node2D = $Facing
@onready var player: AnimationPlayer = $AnimationPlayer
var facing_locked := false

func _ready() -> void:
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library := AnimationLibrary.new()
	# Whole-body recoil keeps the W06 tool and both palms registered.
	_add_clip(library, &"Idle", 1.5, [0.0, 0.75, 1.5], [0.0, -1.5, 0.0], [0.0, -1.0, 0.0], [0.0, 1.0, 0.0], true)
	_add_clip(library, &"Deploy", 0.42, [0.0, 0.23, 0.42], [-8.0, 1.0, 0.0], [-4.0, 2.0, 0.0], [3.0, -2.0, 0.0])
	_add_clip(library, &"Attack", 0.38, [0.0, 0.11, 0.17, 0.38], [0.0, -1.0, 1.2, 0.0], [0.0, 2.0, -5.0, 0.0], [0.0, -1.0, 2.0, 0.0])
	_add_clip(library, &"Skill", 0.66, [0.0, 0.24, 0.32, 0.66], [0.0, -3.0, 0.8, 0.0], [0.0, 4.0, -6.0, 0.0], [0.0, -4.0, 3.0, 0.0])
	_add_clip(library, &"Hit", 0.32, [0.0, 0.08, 0.32], [0.0, 1.0, 0.0], [0.0, -6.0, 0.0], [0.0, 4.0, 0.0])
	_add_clip(library, &"Retreat", 0.50, [0.0, 0.22, 0.50], [0.0, -3.0, 4.0], [0.0, -3.0, 7.0], [0.0, 1.0, 4.0])
	_add_clip(library, &"Defeat", 0.52, [0.0, 0.20, 0.52], [0.0, 1.0, 8.0], [0.0, -4.0, -13.0], [0.0, 3.0, 5.0])
	player.add_animation_library(&"", library)
	for clip in [&"Deploy", &"Attack", &"Skill", &"Hit"]:
		player.animation_set_next(clip, &"Idle")
	play_state(&"Idle")

func play_state(state: StringName) -> void:
	if player.has_animation(state):
		player.stop()
		player.play(state)
		player.advance(0.0)

func advance_combat(seconds: float) -> void:
	player.advance(seconds)

func set_facing(direction: int) -> void:
	if not facing_locked:
		# Rebuild the basis from a fixed neutral orientation on every flip.
		_facing.transform = Transform2D(Vector2(-1 if direction < 0 else 1, 0), Vector2.DOWN, Vector2.ZERO)

func _add_clip(library: AnimationLibrary, state: StringName, duration: float,
		times: Array, lift: Array, lean: Array, head: Array, loop := false) -> void:
	var clip := Animation.new()
	clip.length = duration
	clip.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var position_track := clip.add_track(Animation.TYPE_VALUE)
	var lean_track := clip.add_track(Animation.TYPE_VALUE)
	var head_track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(position_track, NodePath(TORSO + ":position"))
	clip.track_set_path(lean_track, NodePath(TORSO + ":rotation"))
	clip.track_set_path(head_track, NodePath(TORSO + "/head:rotation"))
	var neutral: Vector2 = get_node(TORSO).position
	for i in times.size():
		clip.track_insert_key(position_track, times[i], neutral + Vector2(0, lift[i]))
		clip.track_insert_key(lean_track, times[i], deg_to_rad(lean[i]))
		clip.track_insert_key(head_track, times[i], deg_to_rad(head[i]))
	library.add_animation(state, clip)
