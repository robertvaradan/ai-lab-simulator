class_name PlanCommitmentTraceRecord
extends SimulationTraceRecord

var pending_command_batch_id: StringName:
	get:
		return _pending_command_batch_id
var command_ids: Array[StringName]:
	get:
		var copied_command_ids: Array[StringName] = []
		copied_command_ids.assign(_command_ids)
		return copied_command_ids
var resolved_attention_event_ids: Array[StringName]:
	get:
		var copied_event_ids: Array[StringName] = []
		copied_event_ids.assign(_resolved_attention_event_ids)
		return copied_event_ids

var _pending_command_batch_id: StringName
var _command_ids: Array[StringName] = []
var _resolved_attention_event_ids: Array[StringName] = []


func _init(
		p_sequence_index: int,
		p_pending_command_batch_id: StringName,
		p_command_ids: Array[StringName],
		p_resolved_attention_event_ids: Array[StringName]
	) -> void:
	super(p_sequence_index, Kind.PLAN_COMMITMENT)
	_pending_command_batch_id = p_pending_command_batch_id
	_command_ids.assign(p_command_ids)
	_resolved_attention_event_ids.assign(p_resolved_attention_event_ids)


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"pending_command_batch_id"] = pending_command_batch_id
	data[&"command_ids"] = command_ids
	data[&"resolved_attention_event_ids"] = resolved_attention_event_ids
	return data
