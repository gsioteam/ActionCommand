tool
extends EditorPlugin

const ResourceEditorPanel = preload("res://addons/action_command/lib/resource_editor.tscn")

var editor_pannel

func _enter_tree():
	editor_pannel = ResourceEditorPanel.instance()
	get_editor_interface().get_editor_viewport().add_child(editor_pannel)
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_selection_changed")
	add_custom_type(
		"CommandManager",
		"Node",
		preload("res://addons/action_command/lib/command_manager.gd"),
		preload("res://addons/action_command/lib/command_manager.png")
	)
	make_visible(false)

func _exit_tree():
	remove_custom_type("CommandManager")
	if editor_pannel:
		editor_pannel.queue_free()

func has_main_screen():
	return true

func make_visible(visible):
	if editor_pannel:
		editor_pannel.visible = visible

func handles(object):
	return object is CommandManager

func get_plugin_name():
	return "Commands"
	
func get_plugin_icon():
	return preload("res://addons/action_command/lib/command_manager.png")

func _on_selection_changed():
	if editor_pannel == null:
		return
	var nodes = get_editor_interface().get_selection().get_selected_nodes()
	var resource = null
	if nodes.size() == 1:
		var node = nodes[0]
		if node is CommandManager:
			if node.resource == null:
				node.resource = CommandResource.new()
			resource = node.resource
	
	editor_pannel.set_target(resource)
	
func apply_changes():
	editor_pannel.save()
