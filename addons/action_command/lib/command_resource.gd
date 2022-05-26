extends Resource

class_name CommandResource

export (Resource) var direction2
export (Resource) var direction4
export (Resource) var direction6
export (Resource) var direction8

export (Array, Resource) var buttons

const Status = preload("status.gd")
const TestResult = Status.TestResult
const ActionStatus = Status.ActionStatus

class Action:
	var action_name: String
	var status: int
	
	func _init(name):
		action_name = name
		status = ActionStatus.Released
	
	func test(event: InputEvent) -> int:
		return TestResult.NoRelevant
		

class ProxyAction extends Action:
	var action
	
	func _init(action).(action.action_name):
		self.action = action
	
	func test(event: InputEvent) -> int:
		var ret = action.test(event)
		if ret == TestResult.Active:
			status = ActionStatus.Pressed
		elif ret == TestResult.Silent:
			status = ActionStatus.Released
		return ret

class ManagedAction extends Action:
	
	func _init(name).(name):
		pass
	
	func set_active(active: bool):
		if active:
			status = ActionStatus.Pressed
		else:
			status = ActionStatus.Released

class Controller:
	var actions = []
	var dir1
	var dir2
	var dir3
	var dir4
	var dir5
	var dir6
	var dir7
	var dir8
	var dir9
	
	var action2
	var action4
	var action6
	var action8
	
	var direction = 5
	
	func new_action(res_action, name):
		if res_action == null:
			return Action.new(name)
		else:
			return ProxyAction.new(res_action)
	
	func _init(resource):
		action2 = new_action(resource.direction2, "dir2")
		action4 = new_action(resource.direction4, "dir4")
		action6 = new_action(resource.direction6, "dir6")
		action8 = new_action(resource.direction8, "dir8")
		
		dir1 = ManagedAction.new("1")
		dir2 = ManagedAction.new("2")
		dir3 = ManagedAction.new("3")
		dir4 = ManagedAction.new("4")
		dir5 = ManagedAction.new("5")
		dir6 = ManagedAction.new("6")
		dir7 = ManagedAction.new("7")
		dir8 = ManagedAction.new("8")
		dir9 = ManagedAction.new("9")
		dir5.set_active(true)
		
		actions = [
			dir1,
			dir2,
			dir3,
			dir4,
			dir5,
			dir6,
			dir7,
			dir8,
			dir9
		]
		
		for button in resource.buttons:
			if button.has_method("test"):
				actions.append(ProxyAction.new(button))
	
	func test(event: InputEvent) -> Dictionary:
		action2.test(event)
		action4.test(event)
		action6.test(event)
		action8.test(event)
		
		var dir = 5
		var p4 = action4.status == ActionStatus.Pressed
		var p6 = action6.status == ActionStatus.Pressed
		if p4 and p6:
			pass
		elif p4:
			dir = 4
		elif p6:
			dir = 6
		
		var p8 = action8.status == ActionStatus.Pressed
		var p2 = action2.status == ActionStatus.Pressed
		if p8 and p2:
			pass
		elif p8:
			dir = dir + 3
		elif p2:
			dir = dir - 3
		
		var add = []
		var remove = []
		if dir != direction:
			var n = actions[dir - 1]
			var o = actions[direction - 1]
			direction = dir
			n.set_active(true)
			o.set_active(false)
			add.append(n)
			remove.append(o)
		
		for i in range(9, actions.size()):
			var action = actions[i]
			var ret = action.test(event)
			match ret:
				TestResult.Active:
					add.append(action)
				TestResult.Silent:
					remove.append(action)
		
		return {
			"add": add,
			"remove": remove
		}

func get_controller() -> Controller:
	return Controller.new(self)

func tick():
	pass
