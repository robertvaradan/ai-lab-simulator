class_name RuleGraphTraceRuleView
extends RefCounted

var rule_id: StringName = &""
var status: SimulationRuleEvaluation.Status = SimulationRuleEvaluation.Status.DID_NOT_FIRE
var condition_ids: Array[StringName] = []
var condition_results: Array[bool] = []
var write_state_paths: Array[StringName] = []
var write_before_values: Array[int] = []
var write_after_values: Array[int] = []
var write_has_before_values: Array[bool] = []
var write_has_after_values: Array[bool] = []


func is_fired() -> bool:
	return status == SimulationRuleEvaluation.Status.FIRED


func is_inactive() -> bool:
	return status == SimulationRuleEvaluation.Status.DID_NOT_FIRE


func is_failed() -> bool:
	return status == SimulationRuleEvaluation.Status.FAILED
