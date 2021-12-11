extends Node

enum TestResult {
	NoRelevant,
	Active,
	Silent
}

func test(event: InputEvent) -> int:
	return TestResult.NoRelevant
