class_name ConditionTraceRecord
extends SimulationTraceRecord

var rule_id: StringName:
	get:
		return _rule_id
var condition_id: StringName:
	get:
		return _condition_id
var result: bool:
	get:
		return _result

var _rule_id: StringName
var _condition_id: StringName
var _result: bool


func _init(
		p_sequence_index: int,
		p_rule_id: StringName,
		p_condition_id: StringName,
		p_result: bool
	) -> void:
	super(p_sequence_index, Kind.CONDITION)
	_rule_id = p_rule_id
	_condition_id = p_condition_id
	_result = p_result


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"condition_id"] = condition_id
	data[&"result"] = result
	return data
