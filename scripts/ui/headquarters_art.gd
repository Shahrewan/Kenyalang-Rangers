class_name HeadquartersArt
extends RefCounted

const REGISTRATION := "res://data/presentation/w29/headquarters.json"
const THEME := preload("res://resources/presentation/w29_ui_theme.tres")
const TROPHIES := "res://assets/imported/chaos/trophy/"

var data: Dictionary
var rooms: Dictionary[StringName, Dictionary] = {}

func _init() -> void:
	if not FileAccess.file_exists(REGISTRATION):
		return
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRATION))
	if not source is Dictionary or source.get("schema_version") != 1:
		return
	data = source
	for row: Dictionary in data.rooms:
		rooms[StringName(row.id)] = row

static func point(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

static func rectangle(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])

static func resource(file: String, type: String) -> Resource:
	var path := file if file.begins_with("res://") else "res://" + file
	return ResourceLoader.load(path, type) if not file.is_empty() and ResourceLoader.exists(path, type) else null

static func sprite(parent: Node, file: String, bounds: Rect2, layer: int, id: String) -> Sprite2D:
	var texture := resource(file, "Texture2D") as Texture2D
	if texture == null:
		return null
	var item := Sprite2D.new()
	item.name = id
	item.texture = texture
	item.centered = false
	item.position = bounds.position
	if bounds.has_area():
		item.scale = bounds.size / texture.get_size()
	item.z_index = layer
	parent.add_child(item)
	return item
