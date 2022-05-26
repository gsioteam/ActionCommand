extends Node

class_name CommandManager

var Action = preload("res://addons/action_command/lib/action.gd")
const CommandResource = preload("command_resource.gd")

const Status = preload("status.gd")
const TestResult = Status.TestResult
const ActionStatus = Status.ActionStatus
	
export(int) var max_cache_frame = 30

export (Resource) var resource = CommandResource.new()

var _controller: CommandResource.Controller
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
		Last,
		Press
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
		elif UseType.Press:
			for frame in frame_data:
				for data in frame:
					if data.state == ActionState.Press:
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
	var data = _controller.test(event)
	
	for action in data.add:
		_actives.append(action)
		_silents.erase(action)
		_current_frame.append(_action_data(action.action_name, ActionState.Press))
	for action in data.remove:
		_actives.erase(action)
		_silents.append(action)
		_current_frame.append(_action_data(action.action_name, ActionState.Release))


func refresh():
	if resource == null:
		resource = CommandResource.new()
	_controller = resource.get_controller()
	_actives.clear()
	_silents.clear()
	var will_remove = []
	for child in _controller.actions:
		if child is CommandResource.Action:
			if child.status == ActionStatus.Released:
				_silents.append(child)
			else:
				_actives.append(child)
		else:
			will_remove.append(child)

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
		if result != null:
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
		return (action_data.state & state_mask) > 0
	
	func test(frame):
		for data in frame:
			if _test(data):
				return data
	
	func _to_string():
		var pre = ''
		if not whether:
			pre = '!'
		var post = ''
		if state_mask & ActionState.Press > 0:
			post += '<'
		if state_mask & ActionState.Hold > 0:
			post += '-'
		if state_mask & ActionState.Release > 0:
			post += '>'
		return str(pre, name, post)

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
	
	func _to_string():
		var arr = PoolStringArray(matchers)
		return arr.join('&')

# 236,a<:5
# 	means: ⇩⬊⇨+A 
static func parse_command(command_str:String):
	var list = command_str.split(',')
	var frames = []
	var last_frame = 99
	
	var numRegex = RegEx.new()
	numRegex.compile("^[1-9]+$")
	for fragment in list:
		var arr = fragment.split(':')
		var command
		if arr.size() == 2:
			command = arr[0]
			last_frame = int(arr[1])
		elif arr.size() == 1:
			if numRegex.search(fragment) == null:
				command = fragment
			else:
				for i in range(0, fragment.length()):
					var ch = fragment.substr(i, 1)
					frames.append(FrameMatcher.new(ch, last_frame))
				continue
		else:
			continue
		frames.append(FrameMatcher.new(command, last_frame))
	return frames

static func _reverse_command(matcher: CommandMatcher, name: String) -> CommandMatcher:
	var new_matcher = CommandMatcher.new(name)
	new_matcher.whether = matcher.whether
	new_matcher.state_mask = matcher.state_mask
	return new_matcher

static func reverse(queue: Array) -> Array:
	var new_queue = []
	for item in queue:
		var nobj = FrameMatcher.new("", item.in_frame)
		var matchers = []
		for matcher in item.matchers:
			var matcher_item = matcher
			match matcher.name:
				"1":
					matcher_item = _reverse_command(matcher, "3")
				"4":
					matcher_item = _reverse_command(matcher, "6")
				"7":
					matcher_item = _reverse_command(matcher, "9")
				"3":
					matcher_item = _reverse_command(matcher, "1")
				"6":
					matcher_item = _reverse_command(matcher, "4")
				"9":
					matcher_item = _reverse_command(matcher, "7")
			matchers.append(matcher_item)
		nobj.matchers = matchers
		new_queue.append(nobj)
	return new_queue

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
		var ret
		if frame_idx >= 0:
			var frame = _frames[frame_idx]
			ret = tester.test(frame)
		if ret != null:
			frame_data.append(ret)
			c_queue.pop_back()
		frame_count+=1
		if frame_count >= _frames.size() and not c_queue.empty():
			return null
	return null

func get_direction() -> int:
	return _controller.direction
