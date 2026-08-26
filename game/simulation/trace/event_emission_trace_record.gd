class_name EventEmissionTraceRecord
extends SimulationTraceRecord

var rule_id: StringName:
	get:
		return _rule_id
var event_id: StringName:
	get:
		return _event_id
var succeeded: bool:
	get:
		return _succeeded
var payload: Dictionary[StringName, Variant]:
	get:
		var copied_payload: Dictionary[StringName, Variant] = {}
		copied_payload.assign(_payload.duplicate(true))
		return copied_payload

var _rule_id: StringName
var _event_id: StringName
var _succeeded: bool
var _payload: Dictionary[StringName, Variant] = {}


func _init(
		p_sequence_index: int,
		p_rule_id: StringName,
		p_event_id: StringName,
		p_succeeded: bool,
		p_payload: Dictionary[StringName, Variant]
	) -> void:
	super(p_sequence_index, Kind.EVENT_EMISSION)
	_rule_id = p_rule_id
	_event_id = p_event_id
	_succeeded = p_succeeded
	_payload.assign(p_payload.duplicate(true))


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"event_id"] = event_id
	data[&"succeeded"] = succeeded
	data[&"payload"] = payload
	return data
