tool
extends ConfirmationDialog

class InputSession:
	var command_action: Resource
	var confirmed = false
	signal finished

var session: InputSession

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if session != null:
		if event is InputEventKey:
			if event.is_pressed():
				var scancode = event.scancode
				var string = OS.get_scancode_string(scancode)
				self.dialog_text = "Press Key:" + string
				session.command_action = CommandKey.new()
				session.command_action.scancode = scancode

func input_key(session: InputSession):
	self.session = session
	self.dialog_text = "Press Key: null"
	popup_centered()
	yield(session, "finished")
	yield(get_tree(), "idle_frame")
	self.session = null

func _on_key_input_dialog_confirmed():
	if session != null:
		session.confirmed = true


func _on_key_input_dialog_popup_hide():
	if session != null:
		session.emit_signal("finished")


