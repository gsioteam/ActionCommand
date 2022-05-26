extends EditorInspectorPlugin

class ResourceEditor extends EditorProperty:
	
	var button: Button = Button.new()
	var plugin: EditorPlugin
	
	func _init(plugin):
		self.plugin = plugin
		add_child(button)
		add_focusable(button)
		button.text = "Edit"
		button.connect("pressed", self, "_on_edit")

	func _on_edit():
		var manager: CommandManager = get_edited_object()
		if manager.resource == null:
			manager.resource = CommandResource.new()
		plugin.editor_pannel.set_target(manager.resource)
		plugin.make_visible(true)

var plugin: EditorPlugin

func can_handle(object):
	return object is CommandManager

func parse_property(object, type, path, hint, hint_text, usage):
	if path == "resource":
		add_property_editor(path, ResourceEditor.new(plugin))
		return true
	else:
		return false

