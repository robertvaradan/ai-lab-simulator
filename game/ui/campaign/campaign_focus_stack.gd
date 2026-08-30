class_name CampaignFocusStack
extends RefCounted

var _stack: Array[Control] = []


func _init() -> void:
	pass


func push(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		ServiceContract.fail("missing_focus_control", "A focus stack push must have a Control.")
		return
	_stack.append(control)


func pop() -> Control:
	if _stack.is_empty():
		return null
	return _stack.pop_back()


func peek() -> Control:
	if _stack.is_empty():
		return null
	return _stack[_stack.size() - 1]


func clear() -> void:
	_stack.clear()
