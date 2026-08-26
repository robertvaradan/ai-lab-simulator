class_name Command
extends Resource

@export var stable_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Command cannot change its stable identifier.")
			return
		stable_id = value
@export var command_type_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Command cannot change its type identifier.")
			return
		command_type_id = value
@export var payload: Dictionary[StringName, Variant] = {}:
	set(value):
		if _is_immutable:
			push_error("An immutable Command cannot change its payload.")
			return
		payload = value.duplicate(true)
	get:
		if not _is_immutable:
			return payload
		var copied_payload: Dictionary[StringName, Variant] = {}
		copied_payload.assign(payload.duplicate(true))
		return copied_payload

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func immutable_copy() -> Command:
	var copied_command: Command = Command.new()
	copied_command.stable_id = stable_id
	copied_command.command_type_id = command_type_id
	copied_command.payload = payload
	copied_command._is_immutable = true
	return copied_command


func is_immutable() -> bool:
	return _is_immutable
