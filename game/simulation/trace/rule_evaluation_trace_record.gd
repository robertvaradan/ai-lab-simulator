class_name RuleEvaluationTraceRecord
extends SimulationTraceRecord

var rule_id: StringName:
	get:
		return _rule_id
var status: SimulationRuleEvaluation.Status:
	get:
		return _status

var _rule_id: StringName
var _status: SimulationRuleEvaluation.Status


func _init(p_sequence_index: int, p_rule_id: StringName) -> void:
	super(p_sequence_index, Kind.RULE_EVALUATION)
	_rule_id = p_rule_id
	_status = SimulationRuleEvaluation.Status.FAILED


func _set_status(p_status: SimulationRuleEvaluation.Status) -> void:
	if is_sealed():
		return
	_status = p_status


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"status"] = status
	return data
