extends Control
## Isolated display of the 11 modular rooms and their authored staff loops.

const MANIFEST := "res://assets/source-art/hq/manifest.json"
const TROPHY := "res://assets/imported/chaos/trophy/"
const THEME := preload("res://resources/presentation/w29_ui_theme.tres")
const CANVAS := Vector2(1280.0, 720.0)

var board: Node2D
var manifest: Dictionary
var staff_players: Array[AnimationPlayer] = []
var trophy_tier := 3
var show_opening := false
var still := false

func _ready() -> void:
	theme = THEME
	manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	board = Node2D.new()
	add_child(board)
	var controls := HBoxContainer.new()
	add_child(controls)
	controls.position = Vector2(16, 12)
	controls.add_theme_constant_override("separation", 8)
	_add_action(controls, "Opening day / built", _toggle_rooms)
	_add_action(controls, "Pause / play staff", _toggle_motion)
	_add_action(controls, "Cycle trophy", _cycle_trophy)
	resized.connect(_fit)
	_compose()

func _add_action(parent: Control, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(64, 48)
	button.pressed.connect(callback)
	parent.add_child(button)

func _fit() -> void:
	var ratio := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	board.scale = Vector2.ONE * ratio
	board.position = (size - CANVAS * ratio) / 2

func _place(file: String, origin: Vector2, extent: Vector2 = Vector2.ZERO, layer := 0) -> void:
	var path := file if file.begins_with("res://") else "res://" + file
	var item := Sprite2D.new()
	item.texture = load(path) as Texture2D
	item.centered = false
	item.position = origin
	item.z_index = layer
	if extent != Vector2.ZERO:
		item.scale = extent / item.texture.get_size()
	board.add_child(item)

func _shell(name: String, layer := 0) -> void:
	_place(manifest.shell[name].texture, Vector2.ZERO, Vector2.ZERO, layer)

func _compose() -> void:
	for child: Node in board.get_children():
		board.remove_child(child)
		child.queue_free()
	staff_players.clear()
	for name: String in ["jungle", "roof", "frame_back", "lobby"]:
		_shell(name)
	for i: int in manifest.rooms.size():
		var room: Dictionary = manifest.rooms[i]
		var rect: Array = room.overview_hit_rect
		var origin := Vector2(rect[0], rect[1])
		var extent := Vector2(rect[2], rect[3])
		if show_opening and i >= 3:
			_place(manifest.unbuilt.texture, origin, extent)
			continue
		_place(room.assets.back.texture, origin, extent)
		var staff := room.staff as Dictionary
		var rig := (load("res://" + staff.rig) as PackedScene).instantiate() as Node2D
		rig.position = origin + Vector2(staff.anchor_in_room[0], staff.anchor_in_room[1])
		rig.scale = Vector2.ONE * float(staff.scale)
		board.add_child(rig)
		var player := rig.get_node("AnimationPlayer") as AnimationPlayer
		player.speed_scale = 0.0 if still else 1.0
		staff_players.append(player)
		_place(room.assets.front.texture, origin, extent, 20)
	var last := manifest.rooms[-1] as Dictionary
	var empty := last.overview_hit_rect as Array
	_place(manifest.unbuilt.texture, Vector2(float(empty[0]) + 326.0, empty[1]), Vector2(empty[2], empty[3]))
	_shell("frame_front", 21)
	var size_trophy := Vector2.ONE * float(manifest.trophy_max_size[1])
	var foot := Vector2(manifest.trophy_anchor[0], manifest.trophy_anchor[1])
	var origin_trophy := foot - size_trophy * Vector2(0.5, 154.0 / 160.0)
	if trophy_tier > 0:
		_place(TROPHY + "tier_%s.png" % (trophy_tier * 1000), origin_trophy, size_trophy, 22)
	_place(TROPHY + "mount.png", origin_trophy, size_trophy, 22)
	_shell("foreground", 23)
	_fit()

func _toggle_rooms() -> void:
	show_opening = not show_opening
	_compose()

func _toggle_motion() -> void:
	still = not still
	for player: AnimationPlayer in staff_players:
		player.speed_scale = 0.0 if still else 1.0

func _cycle_trophy() -> void:
	trophy_tier = (trophy_tier + 1) % 4
	_compose()
