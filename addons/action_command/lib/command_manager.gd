extends Node
var Action = preload("res://addons/action_command/lib/action.gd")
	
export(int) var max_cache_frame = 30
	
var _actions = []
var _actives: Array = []
var _silents: Array = []
var _frames: Array = []

var _current_frame: Array = []

enum ActionState {
	Press,
	Release,
	Hold
}

class ActionData:
	var name: String
	var state: int
	var used: bool

class MatchResult:
	var p

func _ready():
	refresh()

var _cached_action_data = []

func _action_data(name, state) -> ActionData:
	var action_data;
	if _cached_action_data.empty():
		action_data = ActionData.new()
	else:
		action_data = _cached_action_data.pop_back()
	action_data.name = name
	action_data.state = state
	action_data.used = false
	return action_data

func _cache_action_data(data: ActionData):
	_cached_action_data.push_back(data)

func tick():
	_frames.push_back(_current_frame)
	
	while _frames.size() > max_cache_frame:
		var frame = _frames.pop_front()
		for data in frame:
			_cache_action_data(data)
	
	var hold_actions = []
	for item in _current_frame:
		match item.state:
			ActionState.Release:
				if hold_actions.has(item.name):
					hold_actions.erase(item.name)
			_:
				if not hold_actions.has(item.name):
					hold_actions.append(item.name)
	var new_frame = []
	for action_name in hold_actions:
		new_frame.append(_action_data(action_name, ActionState.Hold))
	
	_current_frame = new_frame


func _input(event):
	var to_active
	var to_silent
	for action in _actives:
		if action.test(event) == Action.TestResult.Silent:
			to_silent = action
			break
	
	if to_silent != null:
		for action in _silents:
			if action.test(event) == Action.TestResult.Active:
				to_active = action
				break
	
	if to_active != null:
		_actives.append(to_active)
		_silents.erase(to_active)
		_current_frame.append(_action_data(to_active.name, ActionState.Press))
	elif to_silent != null:
		_actives.erase(to_silent)
		_silents.append(to_silent)
		_current_frame.append(_action_data(to_silent.name, ActionState.Release))

func refresh():
	_actions.clear()
	_actives.clear()
	_silents.clear()
	for child in get_children():
		if child is Action:
			_actions.append(child)
			_silents.append(child)

func is_down(action: String, in_frame:int = 1) -> bool:
	for i in range(0, in_frame - 1):
		var frame = _frames[_frames.size() - i -1]
		for data in frame:
			if data.name == action and data.state == ActionState.Press:
				return true
	return false

func is_release(action: String, in_frame:int = 1) -> bool:
	for i in range(0, in_frame - 1):
		var frame = _frames[_frames.size() - i -1]
		for data in frame:
			if data.name == action and data.state == ActionState.Release:
				return true
	return false

func action_match(queue: Array, in_frame: int = 10) -> MatchResult:
	
	return null
