class_name CampaignVisualAssets
extends RefCounted

const DATA := "res://data/presentation/w29/campaign_visuals.json"

var catalog := FirstContactSkin.read_json(FirstContactSkin.W29_CATALOG)
var registration := FirstContactSkin.read_json(DATA)
var _loaded := {}

func actor(id: StringName) -> Dictionary:
	return catalog.get("actors", {}).get(id, {})

func facility(id: StringName) -> Dictionary:
	return catalog.get("facilities", {}).get(id, {})

func load_art(path: String, type: String) -> Resource:
	if path.is_empty():
		return null
	var resource_path := path if path.begins_with("res://") else "res://" + path
	if not _loaded.has(resource_path):
		_loaded[resource_path] = FirstContactSkin.optional_art(resource_path, type)
	return _loaded[resource_path]

func texture(path: String) -> Texture2D:
	return load_art(path, "Texture2D") as Texture2D

func rig(data: Dictionary) -> PackedScene:
	if data.has("animation") and not FileAccess.file_exists(data.animation):
		return null
	return load_art(data.get("rig", ""), "PackedScene") as PackedScene

func badge(id: StringName) -> Texture2D:
	var record := facility(id) if String(id).begins_with("facility.") else actor(id)
	return texture(record.get("badge", ""))

func region(id: StringName) -> Dictionary:
	return registration.get("maps", {}).get(id, {})

func facility_layout(id: StringName) -> Dictionary:
	return registration.get("facilities", {}).get(id, {})

func socket(id: StringName, cue: String) -> Array:
	return registration.get("sockets", {}).get(id, {}).get(cue, [])

func effect(id: String) -> Texture2D:
	return texture(registration.get("effects", {}).get(id, ""))

func portrait(id: String, pose: String) -> Texture2D:
	return texture(registration.get("portraits", {}).get(id, {}).get(pose, ""))
