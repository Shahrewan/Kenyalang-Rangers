class_name FirstContactProgress
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://first_contact_progress.json"

var _path: String
var _data: Dictionary

func _init(path := DEFAULT_PATH) -> void:
	_path = path
	_data = _read(path)
	if _data.is_empty():
		_data = _read(path + ".bak")
	if _data.is_empty():
		_data = {"version": SCHEMA_VERSION, "first_clear": false, "perfect_clear": false, "funds": 0}

func snapshot() -> Dictionary:
	return _data.duplicate()

func record_clear(perfect: bool, clear_funds: int, perfect_funds: int) -> int:
	var next := _data.duplicate()
	var reward := 0
	if not next.first_clear:
		next.first_clear = true
		reward += clear_funds
	if perfect and not next.perfect_clear:
		next.perfect_clear = true
		reward += perfect_funds
	if next == _data:
		return 0
	next.funds = int(next.funds) + reward
	var temporary := _path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return -1
	file.store_string(JSON.stringify(next))
	file.close()

	# Retain the last readable primary before replacing it.
	if not _read(_path).is_empty():
		var backup := _path + ".bak"
		if DirAccess.copy_absolute(_path, backup + ".tmp") != OK:
			return -1
		if DirAccess.rename_absolute(backup + ".tmp", backup) != OK:
			return -1
	if DirAccess.rename_absolute(temporary, _path) != OK:
		return -1
	_data = next
	return reward

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var decoded: Variant = parser.data
	if not decoded is Dictionary or decoded.get("version") != SCHEMA_VERSION:
		return {}
	if not decoded.get("first_clear") is bool or not decoded.get("perfect_clear") is bool:
		return {}
	var funds: Variant = decoded.get("funds")
	if (not funds is float and not funds is int) or not is_finite(float(funds)) or funds < 0 or funds != floorf(funds):
		return {}
	if decoded.perfect_clear and not decoded.first_clear:
		return {}
	decoded.version = SCHEMA_VERSION
	decoded.funds = int(funds)
	return decoded
