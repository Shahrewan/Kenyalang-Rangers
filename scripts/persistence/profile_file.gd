class_name ProfileFile
extends RefCounted

const MAX_EXACT_INTEGER := 9007199254740991

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	return json.data

static func whole_between(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= minimum and value <= maximum and value == floorf(value)

static func unique_ids(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen := {}
	for id: Variant in value:
		if not id is String or id.is_empty() or seen.has(id):
			return false
		seen[id] = true
	return true

static func replace(path: String, data: Dictionary, primary_is_valid: bool) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	# Preserve the last readable primary. Keep an existing backup when recovering.
	if primary_is_valid:
		var backup := path + ".bak"
		if DirAccess.copy_absolute(path, backup + ".tmp") != OK:
			return false
		if DirAccess.rename_absolute(backup + ".tmp", backup) != OK:
			return false
	return DirAccess.rename_absolute(temporary, path) == OK

static func finish_reset(path: String, empty: Dictionary) -> bool:
	# The confirmed reset marker stays until the new primary is durable.
	for suffix in [".bak", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix) and DirAccess.remove_absolute(path + suffix) != OK:
			return false
	if not replace(path, empty, false):
		return false
	return DirAccess.remove_absolute(path + ".reset") == OK
