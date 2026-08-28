class_name CloseMonthStepRule
extends SimulationRule

const RULE_ID: StringName = &"rule.time.close_month_step"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Close Month Step"
	phase_id = SimulationRulePhase.CLOSE_MONTH_STEP
	execution_order = 10
	read_state_paths = [CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX]
	graph_group_id = &"rule_group.time_model"
	specification_references = ["docs/simulation/time-model.md"]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	if month_result.value < 1:
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.time.month_step_not_open",
				"Close Month Step ran with month index %d." % month_result.value,
				stable_id,
				CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
			)
		)
	return SimulationRuleEvaluation.fired()
