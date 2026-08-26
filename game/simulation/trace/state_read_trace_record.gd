class_name StateReadTraceRecord
extends SimulationTraceRecord

var rule_id: StringName:
	get:
		return _rule_id
var state_path: StringName:
	get:
		return _state_path
var succeeded: bool:
	get:
		return _succeeded
var has_value: bool:
	get:
		return _has_value
var value: int:
	get:
		return _value

var _rule_id: StringName
var _state_path: StringName
var _succeeded: bool
var _has_value: bool
var _value: int


func _init(
		p_sequence_index: int,
		p_rule_id: StringName,
		p_state_path: StringName,
		p_succeeded: bool,
		p_has_value: bool,
		p_value: int
	) -> void:
	super(p_sequence_index, Kind.STATE_READ)
	_rule_id = p_rule_id
	_state_path = p_state_path
	_succeeded = p_succeeded
	_has_value = p_has_value
	_value = p_value


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"state_path"] = state_path
	data[&"succeeded"] = succeeded
	data[&"has_value"] = has_value
	if has_value:
		data[&"value"] = value
	return data
