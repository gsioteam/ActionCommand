tool
extends Control

const KeyEditor = preload("res://addons/action_command/lib/key_editor.tscn")
const KeyInputDialog = preload("res://addons/action_command/lib/key_input_dialog.gd")
const ArrowButtonEditor = preload("res://addons/action_command/lib/arrow_button_editor.gd")

var target: CommandResource

var path_field: LineEdit
var new_button: Button
var save_button: Button

var buttons_group: GridContainer
var add_button: Button
var panel: Panel

var save_file_dialog: FileDialog
var open_file_dialog: FileDialog
var key_input_dialog: KeyInputDialog

var arrow2: ArrowButtonEditor
var arrow4: ArrowButtonEditor
var arrow6: ArrowButtonEditor
var arrow8: ArrowButtonEditor

func _ready():
	
	path_field = $row/path
	new_button = $row/new
	save_button = $row/save
	buttons_group = $panel/vbox/buttons
	add_button = $panel/vbox/buttons/add_button
	panel = $panel
	save_file_dialog = $save_file_dialog
	open_file_dialog = $open_file_dialog
	key_input_dialog = $key_input_dialog
	
	arrow2 = $panel/vbox/hbox/arrow2
	arrow4 = $panel/vbox/hbox/arrow4
	arrow6 = $panel/vbox/hbox/arrow6
	arrow8 = $panel/vbox/hbox/arrow8
	
	_update()

func set_target(target):
	self.target = target
	_update()
	
func _update():
	if target == null:
		path_field.text = "null"
		panel.visible = false
	else:
		panel.visible = true
		var path = target.resource_path
		if path.empty():
			path_field.text = "<memory>"
		else:
			path_field.text = path
		arrow2.set_action(target.direction2)
		arrow4.set_action(target.direction4)
		arrow6.set_action(target.direction6)
		arrow8.set_action(target.direction8)
		_reload_buttons()

func _reload_buttons():
	buttons_group.remove_child(add_button)
	for child in buttons_group.get_children():
		child.queue_free()
	var count = 0
	for btn in target.buttons:
		var btn_editor = KeyEditor.instance()
		btn_editor.set_action(btn)
		btn_editor.index = count
		btn_editor.connect("button_pressed", self, "_on_button_editor_pressed")
		buttons_group.add_child(btn_editor)
		count += 1
	buttons_group.add_child(add_button)

func _on_add_button_pressed():
	var session = KeyInputDialog.InputSession.new()
	yield(key_input_dialog.input_key(session), "completed")
	if session.confirmed:
		target.buttons.append(session.command_action)
		_reload_buttons()

func _on_new_pressed():
	set_target(CommandResource.new())

func save():
	if not is_visible_in_tree():
		return
	if target != null:
		var path  = target.resource_path
		if not path.empty():
			target.emit_changed()
		else:
			var size = OS.window_size
			save_file_dialog.popup_centered(Vector2(size.x * 0.8, size.y * 0.8))


func _on_file_dialog_file_selected(path):
	ResourceSaver.save(path, target, ResourceSaver.FLAG_CHANGE_PATH)
	set_target(load(path))

func _on2_button_pressed():
	var session = KeyInputDialog.InputSession.new()
	yield(key_input_dialog.input_key(session), "completed")
	if session.confirmed:
		var action = session.command_action
		action.action_name = '2'
		target.direction2 = action
		arrow2.set_action(action)

func _on4_button_pressed():
	var session = KeyInputDialog.InputSession.new()
	yield(key_input_dialog.input_key(session), "completed")
	if session.confirmed:
		var action = session.command_action
		action.action_name = '4'
		target.direction4 = action
		arrow4.set_action(action)

func _on6_button_pressed():
	var session = KeyInputDialog.InputSession.new()
	yield(key_input_dialog.input_key(session), "completed")
	if session.confirmed:
		var action = session.command_action
		action.action_name = '6'
		target.direction6 = action
		arrow6.set_action(action)

func _on8_button_pressed():
	var session = KeyInputDialog.InputSession.new()
	yield(key_input_dialog.input_key(session), "completed")
	if session.confirmed:
		var action = session.command_action
		action.action_name = '8'
		target.direction8 = action
		arrow8.set_action(action)

func _on_button_editor_pressed(button_editor):
	var session = KeyInputDialog.InputSession.new()
	yield(key_input_dialog.input_key(session), "completed")
	if session.confirmed:
		var action = session.command_action
		button_editor.replace_action(action)
		target.buttons[button_editor.index] = action

func _on_open_pressed():
	var size = OS.window_size
	open_file_dialog.popup_centered(Vector2(size.x * 0.8, size.y * 0.8))

func _on_open_file_dialog_file_selected(path):
	var resource = load(path)
	if resource is CommandResource:
		set_target(resource)

func _on_path_file_drop(resource):
	set_target(resource)
