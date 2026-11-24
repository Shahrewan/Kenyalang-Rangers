class_name HeadquartersOfficeArt
extends Control

var catalog: HeadquartersArt
var room_id: StringName
var level := 0

var stage := Node2D.new()
var staff: Node2D
var player: AnimationPlayer
var _canvas := Vector2(314, 105)
var _suspended := false
var _focused := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	resized.connect(_fit)
	visibility_changed.connect(_update_playback)
	_compose()

func update_level(value: int) -> void:
	if level != value:
		level = value
		_compose()

func _compose() -> void:
	for layer in stage.get_children():
		stage.remove_child(layer)
		layer.queue_free()
	staff = null
	player = null
	var room: Dictionary = catalog.rooms.get(room_id, {})
	if not room.is_empty():
		_canvas = HeadquartersArt.rectangle(room.rect).size
	var bounds := Rect2(Vector2.ZERO, _canvas)
	if level == 0:
		if HeadquartersArt.sprite(stage, catalog.data.get("unbuilt", ""), bounds, 0, "EmptyRoom") == null:
			_missing_art()
	elif room.is_empty():
		_missing_art()
	else:
		var back := HeadquartersArt.sprite(stage, room.back, bounds, 0, "RoomBack")
		var front := HeadquartersArt.sprite(stage, room.front, bounds, 20, "RoomFront")
		if back != null and front != null:
			_add_staff(room.staff)
		else:
			if back != null:
				back.queue_free()
			if front != null:
				front.queue_free()
			if HeadquartersArt.sprite(stage, room.detail, bounds, 0, "RoomDetail") == null:
				_missing_art()
	_fit()

func _add_staff(record: Dictionary) -> void:
	var packed := HeadquartersArt.resource(record.rig, "PackedScene") as PackedScene
	if packed == null:
		return
	staff = packed.instantiate()
	staff.name = "Staff"
	staff.position = HeadquartersArt.point(record.anchor_in_room)
	staff.scale = Vector2.ONE * float(record.scale)
	stage.add_child(staff)
	player = staff.get_node("AnimationPlayer")
	player.play(record.clip)
	_update_playback()

func _missing_art() -> void:
	var label := StoryUI.label("Room artwork unavailable", 16)
	label.size = _canvas
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(label)

func _fit() -> void:
	var ratio := minf(size.x / _canvas.x, size.y / _canvas.y)
	stage.scale = Vector2.ONE * ratio
	stage.position = (size - _canvas * ratio) * 0.5

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_suspended = true
		NOTIFICATION_APPLICATION_RESUMED:
			_suspended = false
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
		_:
			return
	_update_playback()

func _update_playback() -> void:
	if player != null:
		player.active = is_visible_in_tree() and _focused and not _suspended
