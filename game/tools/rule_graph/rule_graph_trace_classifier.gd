class_name RuleGraphTraceClassifier
extends RefCounted


static func classify(
		ordered_rules: Array[SimulationRule],
		trace: SimulationTrace,
		month_step_index: int
	) -> RuleGraphTraceViewResult:
	var result: RuleGraphTraceViewResult = RuleGraphTraceViewResult.new()
	if month_step_index < 1:
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule_graph_trace.invalid_month_step",
				"The selected Month Step index must be positive."
			)
		)
		return result
	if trace == null:
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule_graph_trace.missing_trace",
				"The Simulation Trace is missing."
			)
		)
		return result
	var slice: Array[SimulationTraceRecord] = _month_slice(trace, month_step_index)
	if slice.is_empty():
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule_graph_trace.month_step_mismatch",
				"The selected Month Step %d is not present in the Simulation Trace." % month_step_index
			)
		)
		return result
	var view: RuleGraphTraceView = RuleGraphTraceView.new()
	view.month_step_index = month_step_index
	for rule: SimulationRule in ordered_rules:
		if rule == null:
			continue
		view.rule_views.append(_classify_rule(rule, slice))
	result.view = view
	return result


static func _month_slice(trace: SimulationTrace, month_step_index: int) -> Array[SimulationTraceRecord]:
	var records: Array[SimulationTraceRecord] = trace.get_records()
	var open_indexes: Array[int] = []
	for record_index: int in range(records.size()):
		var record: SimulationTraceRecord = records[record_index]
		if record.kind != SimulationTraceRecord.Kind.RULE_EVALUATION:
			continue
		var rule_record: RuleEvaluationTraceRecord = record as RuleEvaluationTraceRecord
		if rule_record != null and rule_record.rule_id == OpenMonthStepRule.RULE_ID:
			open_indexes.append(record_index)
	if month_step_index > open_indexes.size():
		return []
	var start_index: int = open_indexes[month_step_index - 1]
	var end_index: int = records.size()
	if month_step_index < open_indexes.size():
		end_index = open_indexes[month_step_index]
	var slice: Array[SimulationTraceRecord] = []
	for record_index: int in range(start_index, end_index):
		slice.append(records[record_index])
	return slice


static func _classify_rule(
		rule: SimulationRule,
		slice: Array[SimulationTraceRecord]
	) -> RuleGraphTraceRuleView:
	var rule_view: RuleGraphTraceRuleView = RuleGraphTraceRuleView.new()
	rule_view.rule_id = rule.stable_id
	rule_view.status = SimulationRuleEvaluation.Status.DID_NOT_FIRE
	var saw_evaluation: bool = false
	for record: SimulationTraceRecord in slice:
		if record.kind == SimulationTraceRecord.Kind.RULE_EVALUATION:
			var rule_record: RuleEvaluationTraceRecord = record as RuleEvaluationTraceRecord
			if rule_record == null or rule_record.rule_id != rule.stable_id:
				continue
			rule_view.status = rule_record.status
			saw_evaluation = true
			continue
		if record.kind == SimulationTraceRecord.Kind.CONDITION:
			var condition_record: ConditionTraceRecord = record as ConditionTraceRecord
			if condition_record == null or condition_record.rule_id != rule.stable_id:
				continue
			rule_view.condition_ids.append(condition_record.condition_id)
			rule_view.condition_results.append(condition_record.result)
			continue
		if record.kind != SimulationTraceRecord.Kind.STATE_WRITE:
			continue
		var write_record: StateWriteTraceRecord = record as StateWriteTraceRecord
		if write_record == null or write_record.rule_id != rule.stable_id:
			continue
		rule_view.write_state_paths.append(write_record.state_path)
		rule_view.write_has_before_values.append(write_record.has_before_value)
		rule_view.write_before_values.append(write_record.before_value)
		rule_view.write_has_after_values.append(write_record.has_after_value)
		rule_view.write_after_values.append(write_record.after_value)
	if not saw_evaluation:
		rule_view.status = SimulationRuleEvaluation.Status.DID_NOT_FIRE
	return rule_view
