extends "res://addons/action_command/lib/action.gd"

export(int) var scancode

func test(event: InputEvent) -> int:
	if event is InputEventKey && event.scancode == scancode:
		if event.is_pressed():
			return TestResult.Active
		else:
			return TestResult.Silent
	return TestResult.NoRelevant
