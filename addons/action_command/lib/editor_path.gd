tool
extends LineEdit

signal file_drop

func can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY:
		var files = data["files"]
		return files.size() == 1
	return false

func drop_data(position, data):
	var resource = load(data["files"][0])
	if resource is CommandResource:
		emit_signal("file_drop", resource)
