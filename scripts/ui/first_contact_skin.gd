class_name FirstContactSkin
extends RefCounted

const FIELD_DATA := "res://data/presentation/first_contact/field.json"
const W29_CATALOG := "res://data/presentation/w29/art_catalog.json"
const POACHER := &"E02"
const RUNNER := &"E03"
const MEDIC := &"ranger.combat_medic"
const SONIC := &"facility.sonic_turret"
const NARROW_ESCAPE := &"C1-03"
const ATLASES := {
	"terrain": preload("res://assets/imported/first_contact/t01_terrain_atlas.png"),
	"interface": preload("res://assets/imported/first_contact/first_contact_ui_atlas.png"),
	"effects": preload("res://assets/imported/first_contact/first_contact_fx_atlas.png"),
}
const BADGES := preload("res://assets/imported/first_contact/first_contact_actor_badges.png")
var _data := read_json(FIELD_DATA)
var _regions: Dictionary[String, AtlasTexture] = {}

static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func illustrates_operation(stage_id: StringName) -> bool:
	return stage_id in [&"C1-01", &"C1-02", NARROW_ESCAPE]

static func poacher_art() -> Dictionary:
	return w29_art(POACHER)

static func w29_art(id: StringName) -> Dictionary:
	var catalog := read_json(W29_CATALOG)
	var family := "facilities" if String(id).begins_with("facility.") else "actors"
	return catalog.get(family, {}).get(id, {})

static func w29_badge(id: StringName) -> Texture2D:
	return optional_art(w29_art(id).get("badge", ""), "Texture2D") as Texture2D

static func optional_art(path: String, type: String) -> Resource:
	return ResourceLoader.load(path, type) if not path.is_empty() and ResourceLoader.exists(path, type) else null

func registration() -> Dictionary:
	return _data.get("layout", {})

func patrolman_sockets() -> Dictionary:
	return _data.patrolman_sockets

static func vector(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

func region(family: String, key: String) -> AtlasTexture:
	var path := family + "/" + key
	if _regions.has(path):
		return _regions[path]
	var atlas: Texture2D = ATLASES.get(family)
	var rect: Array
	if family == "badge":
		atlas = BADGES
		rect = registration().thumbnails.regions[key]
	else:
		rect = _data.atlas[family].regions[key].region_px
	var part := AtlasTexture.new()
	part.atlas = atlas
	part.region = Rect2(rect[0], rect[1], rect[2], rect[3])
	part.filter_clip = true
	_regions[path] = part
	return part

func panel(id: String, margin := 16.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = region("interface", id)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		style.set_content_margin(side, 8.0)
	return style

func button(button_node: Button, id: String) -> void:
	var style := panel(id)
	button_node.add_theme_stylebox_override("normal", style)
	var hot := style.duplicate() as StyleBoxTexture
	hot.modulate_color = Color(1.14, 1.14, 1.08)
	button_node.add_theme_stylebox_override("hover", hot)
	var down := style.duplicate() as StyleBoxTexture
	down.modulate_color = Color(0.82, 0.84, 0.75)
	button_node.add_theme_stylebox_override("pressed", down)
