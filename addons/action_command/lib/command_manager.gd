extends Node
var Action = preload("res://addons/action_command/lib/action.gd")
	
export(int) var max_cache_frame = 30
	
var _actions = []
var _actives: Array = []
var _silents: Array = []
var _frames: Array = []

var _current_frame: Array = []

enum ActionState {
	Press = 1,
	Release = 1 << 1,
	Hold = 1 << 2
}

class ActionData:
	var name: String
	var state: int
	var used: bool

class MatchResult:
	enum UseType {
		All,
		Last
	}
	var frame_data: Array
	
	func _init(frame_data: Array):
		self.frame_data = frame_data
	
	func use(var type: int = UseType.Last):
		if frame_data.empty(): 
			return
		if type == UseType.Last:
			var last = frame_data[frame_data.size() - 1]
			for data in last:
				data.used = true
		else:
			for frame in frame_data:
				for data in frame:
					data.used = true

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
	
	if to_silent == null:
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
		if i >= _frames.size():
			return false
		var frame = _frames[_frames.size() - i -1]
		for data in frame:
			if data.name == action and data.state == ActionState.Press:
				return true
	return false

func is_release(action: String, in_frame:int = 1) -> bool:
	for i in range(0, in_frame - 1):
		if i >= _frames.size():
			return false
		var frame = _frames[_frames.size() - i -1]
		for data in frame:
			if data.name == action and data.state == ActionState.Release:
				return true
	return false

func is_press(action: String, in_frame:int = 1) -> bool:
	for i in range(0, in_frame):
		if i >= _frames.size():
			return false
		var frame = _frames[_frames.size() - i -1]
		for data in frame:
			if data.name == action and (data.state == ActionState.Press || data.state == ActionState.Hold):
				return true
	return false

class CommandMatcher:
	var name: String
	var whether: bool
	var state_mask: int
	
	func _init(command: String):
		var regex = RegEx.new()
		regex.compile("^(\\!?)(\\w+)([<\\->]*)$")
		var result = regex.search(command)
		var str1:String = result.strings[1]
		whether = str1.empty()
		name = result.strings[2]
		var str2:String = result.strings[3]
		if str2.length() > 0:
			state_mask = 0
			if str2.find('<') >= 0:
				state_mask |= ActionState.Press
			if str2.find('-') >= 0:
				state_mask |= ActionState.Hold
			if str2.find('>') >= 0:
				state_mask |= ActionState.Release
		else:
			state_mask = ActionState.Press | ActionState.Hold
	
	func _test(action_data: ActionData) -> bool:
		if action_data.used:
			return false
		if action_data.name != name:
			return false
		return action_data.state & state_mask > 0 
		# return action_data.state & state_mask == 0 
	
	func test(frame):
		for data in frame:
			if _test(data):
				return data

class FrameMatcher:
	var matchers: Array
	var in_frame: int
	
	func _init(command: String, in_frame: int):
		self.in_frame = in_frame
		var list = command.split('&')
		matchers = []
		for fragment in list:
			matchers.append(CommandMatcher.new(fragment))
	
	func test(frame):
		var result = []
		for matcher in matchers:
			if matcher.whether:
				var ret = matcher.test(frame)
				if ret == null:
					return null
				else:
					result.append(ret)
			else:
				if matcher.test(frame) != null:
					return null
		return result

# down&!right:20,down&right,!down&right,action<:5
# 	means: ⇩⬊⇨+A 
func parse_command(command_str:String):
	var list = command_str.split(',')
	var frames = []
	var last_frame = max_cache_frame
	for fragment in list:
		var arr = fragment.split(':')
		var command
		if arr.size() == 2:
			command = arr[0]
			last_frame = int(arr[1])
		elif arr.size() == 1:
			command = fragment
		else:
			continue
		frames.append(FrameMatcher.new(command, last_frame))
	return frames

func command_match(queue: Array) -> MatchResult:
	var frame_count = 0
	var c_queue = queue.slice(0, queue.size())
	var frame_data = []
	while true:
		if c_queue.empty():
			if frame_data.empty():
				return null
			return MatchResult.new(frame_data)
		var tester: FrameMatcher = c_queue[c_queue.size() - 1]
		if tester.in_frame < frame_count:
			return null
		var frame_idx = _frames.size() - frame_count - 1
		var frame = _frames[frame_idx]
		var ret = tester.test(frame)
		if ret != null:
			frame_data.append(ret)
			c_queue.pop_back()
		frame_count+=1
		if frame_count >= _frames.size() and not c_queue.empty():
			return null
	return null
