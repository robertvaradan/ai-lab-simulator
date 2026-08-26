class_name StateWriteTraceRecord
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
var has_before_value: bool:
	get:
		return _has_before_value
var before_value: int:
	get:
		return _before_value
var has_after_value: bool:
	get:
		return _has_after_value
var after_value: int:
	get:
		return _after_value

var _rule_id: StringName
var _state_path: StringName
var _succeeded: bool
var _has_before_value: bool
var _before_value: int
var _has_after_value: bool
var _after_value: int


func _init(
		p_sequence_index: int,
		p_rule_id: StringName,
		p_state_path: StringName,
		p_succeeded: bool,
		p_has_before_value: bool,
		p_before_value: int,
		p_has_after_value: bool,
		p_after_value: int
	) -> void:
	super(p_sequence_index, Kind.STATE_WRITE)
	_rule_id = p_rule_id
	_state_path = p_state_path
	_succeeded = p_succeeded
	_has_before_value = p_has_before_value
	_before_value = p_before_value
	_has_after_value = p_has_after_value
	_after_value = p_after_value


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"state_path"] = state_path
	data[&"succeeded"] = succeeded
	data[&"has_before_value"] = has_before_value
	if has_before_value:
		data[&"before_value"] = before_value
	data[&"has_after_value"] = has_after_value
	if has_after_value:
		data[&"after_value"] = after_value
	return data
