class_name PendingCommandBatchState
extends Resource

@export var stable_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Pending Command Batch cannot change its stable identifier.")
			return
		stable_id = value
@export var commands: Array[Command] = []:
	set(value):
		if _is_immutable:
			push_error("An immutable Pending Command Batch cannot change its Commands.")
			return
		commands = value
	get:
		if not _is_immutable:
			return commands
		var copied_commands: Array[Command] = []
		copied_commands.assign(commands)
		return copied_commands

@export_storage var _is_immutable: bool = false
@export_storage var _is_consumed: bool = false


func _init() -> void:
	pass


static func create_committed(
		batch_id: StringName,
		plan_commands: Array[Command]
	) -> PendingCommandBatchState:
	var batch: PendingCommandBatchState = PendingCommandBatchState.new()
	batch.stable_id = batch_id
	for command: Command in plan_commands:
		if command == null:
			return null
		batch.commands.append(command.immutable_copy())
	batch._is_immutable = true
	return batch


func consume_once() -> bool:
	if _is_consumed:
		return false
	_is_consumed = true
	return true


func is_immutable() -> bool:
	return _is_immutable


func is_consumed() -> bool:
	return _is_consumed
