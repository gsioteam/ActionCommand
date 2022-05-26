extends Resource

class_name CommandAction, "action.png"

const TestResult = preload("res://addons/action_command/lib/status.gd").TestResult

export(String) var action_name

func test(event: InputEvent) -> int:
	return TestResult.NoRelevant
