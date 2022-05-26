tool
extends Control

export (String) var label
export (String) var button_text

signal button_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$label.text = label
	$button.text = button_text

func _on_button_pressed():
	emit_signal("button_pressed")

func set_action(action):
	if action is CommandKey:
		button_text = OS.get_scancode_string(action.scancode)
	else:
		button_text = "null"
