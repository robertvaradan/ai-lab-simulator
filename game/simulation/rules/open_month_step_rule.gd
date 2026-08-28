class_name OpenMonthStepRule
extends SimulationRule

const RULE_ID: StringName = &"rule.time.open_month_step"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Open Month Step"
	phase_id = SimulationRulePhase.OPEN_MONTH_STEP
	execution_order = 10
	read_state_paths = [CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX]
	write_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.CALENDAR_QUARTER_INDEX,
	]
	graph_group_id = &"rule_group.time_model"
	specification_references = ["docs/simulation/time-model.md"]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	var next_month_index: int = month_result.value + 1
	if not context.write_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		next_month_index
	):
		return _failed_from_context(context)
	var next_quarter_index: int = (next_month_index + 2) / 3
	if next_quarter_index < 1:
		next_quarter_index = 1
	if not context.write_integer(
		CanonicalSimulationStatePaths.CALENDAR_QUARTER_INDEX,
		next_quarter_index
	):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
