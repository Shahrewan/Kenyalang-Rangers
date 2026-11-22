class_name ProfileFile
extends RefCounted

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
