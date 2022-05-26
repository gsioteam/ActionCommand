tool
extends Control

var _action: Resource
var action: Resource setget set_action, get_action

var index 

signal button_pressed

func set_action(action):
	_action = action
	$label.text = action.action_name
	if action is CommandKey:
		$button.text = OS.get_scancode_string(action.scancode)

func replace_action(action):
	if action == null:
		return;
	if _action != null:
		action.action_name = _action.action_name
	_action = action
	if action is CommandKey:
		$button.text = OS.get_scancode_string(action.scancode)

func get_action():
	return _action

func _on_label_text_changed(new_text):
	_action.action_name = new_text

func _on_button_pressed():
	emit_signal("button_pressed", self)
