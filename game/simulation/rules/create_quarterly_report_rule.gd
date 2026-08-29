class_name CreateQuarterlyReportRule
extends SimulationRule

const RULE_ID: StringName = &"rule.report.create_quarterly_report"
const EVENT_ID: StringName = &"event.report.quarterly"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Create Quarterly Report"
	phase_id = SimulationRulePhase.CREATE_ATTENTION_EVENTS
	execution_order = 30
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.CALENDAR_QUARTER_INDEX,
		CanonicalSimulationStatePaths.COMPANY_PUBLIC_TRUST_POINTS,
		CanonicalSimulationStatePaths.COMPANY_GOVERNMENT_TRUST_POINTS,
		CanonicalSimulationStatePaths.COMPANY_PROJECTS,
		CanonicalSimulationStatePaths.COMPANY_MODELS,
		CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
		CanonicalSimulationStatePaths.WORLD_COMPETITORS,
		CanonicalSimulationStatePaths.WORLD_MODELS,
		CanonicalSimulationStatePaths.WORLD_MARKETS,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_CODING,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_REASONING,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
		CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS,
		CanonicalSimulationStatePaths.ATTENTION_EVENTS,
		CanonicalSimulationStatePaths.QUARTERLY_REPORTS,
		CanonicalSimulationStatePaths.RUNTIME_QUARTERLY_REPORT_SEQUENCE,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.QUARTERLY_REPORTS,
		CanonicalSimulationStatePaths.RUNTIME_QUARTERLY_REPORT_SEQUENCE,
	]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.reports"
	specification_references = [
		"docs/simulation/time-model.md",
		"docs/marketing/marketing-scenario.md",
	]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	if month_result.value < 1 or month_result.value % 3 != 0:
		return SimulationRuleEvaluation.did_not_fire()
	var quarter_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_QUARTER_INDEX
	)
	if not quarter_result.has_value:
		return SimulationRuleEvaluation.failed(quarter_result.diagnostic)
	var attention_events: Array[AttentionEventState] = context.read_attention_events()
	if context.has_fault():
		return _failed_from_context(context)
	var has_quarter_boundary: bool = false
	for attention_event: AttentionEventState in attention_events:
		if (
			attention_event != null
			and attention_event.event_type_id == CreateQuarterBoundaryAttentionRule.EVENT_TYPE_ID
		):
			has_quarter_boundary = true
			break
	if not has_quarter_boundary:
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.report.missing_quarter_boundary_attention",
				"The Quarterly Report must follow the Quarter Boundary Attention Event.",
				stable_id,
				CanonicalSimulationStatePaths.ATTENTION_EVENTS
			)
		)
	var public_trust_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.COMPANY_PUBLIC_TRUST_POINTS
	)
	if not public_trust_result.has_value:
		return SimulationRuleEvaluation.failed(public_trust_result.diagnostic)
	var government_trust_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.COMPANY_GOVERNMENT_TRUST_POINTS
	)
	if not government_trust_result.has_value:
		return SimulationRuleEvaluation.failed(government_trust_result.diagnostic)
	context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS)
	if context.has_fault():
		return _failed_from_context(context)
	context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_MODELS)
	if context.has_fault():
		return _failed_from_context(context)
	context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_APPLICATIONS)
	if context.has_fault():
		return _failed_from_context(context)
	var competitors: Dictionary[StringName, CompetitorState] = {}
	competitors.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_COMPETITORS))
	if context.has_fault():
		return _failed_from_context(context)
	context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MODELS)
	if context.has_fault():
		return _failed_from_context(context)
	context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MARKETS)
	if context.has_fault():
		return _failed_from_context(context)
	var frontier_coding_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_CODING
	)
	if not frontier_coding_result.has_value:
		return SimulationRuleEvaluation.failed(frontier_coding_result.diagnostic)
	var frontier_reasoning_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_REASONING
	)
	if not frontier_reasoning_result.has_value:
		return SimulationRuleEvaluation.failed(frontier_reasoning_result.diagnostic)
	var frontier_efficiency_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_EFFICIENCY
	)
	if not frontier_efficiency_result.has_value:
		return SimulationRuleEvaluation.failed(frontier_efficiency_result.diagnostic)
	if context.read_cash_ledger() == null:
		return _failed_from_context(context)
	var reports: Array[QuarterlyReportState] = context.read_quarterly_reports()
	if context.has_fault():
		return _failed_from_context(context)
	if reports.is_empty():
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.report.missing_opening_report",
				"The ending Quarterly Report requires the opening Quarterly Report.",
				stable_id,
				CanonicalSimulationStatePaths.QUARTERLY_REPORTS
			)
		)
	var sequence_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.RUNTIME_QUARTERLY_REPORT_SEQUENCE
	)
	if not sequence_result.has_value:
		return SimulationRuleEvaluation.failed(sequence_result.diagnostic)
	var competitor_ids: Array[StringName] = []
	competitor_ids.assign(competitors.keys())
	competitor_ids.sort()
	var competitor_definitions: Array[CompetitorDefinition] = []
	for competitor_id: StringName in competitor_ids:
		var definition: CompetitorDefinition = context.get_competitor_definition(competitor_id)
		if definition == null:
			return _failed_from_context(context)
		competitor_definitions.append(definition)
	var report_id: StringName = StableIdentifier.format_runtime_identifier(
		&"quarterly_report",
		sequence_result.value
	)
	var candidate: GameState = context.get_candidate_state_for_report()
	if candidate == null:
		return _failed_from_context(context)
	var compiled_report: QuarterlyReportState = QuarterlyReportCompiler.compile_ending(
		candidate,
		competitor_definitions,
		report_id,
		reports[reports.size() - 1]
	)
	reports.append(compiled_report)
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_QUARTERLY_REPORT_SEQUENCE,
		sequence_result.value + 1
	):
		return _failed_from_context(context)
	if not context.write_quarterly_reports(reports):
		return _failed_from_context(context)
	var payload: Dictionary[StringName, Variant] = {
		&"report_id": compiled_report.stable_id,
		&"report_kind_id": compiled_report.report_kind_id,
		&"quarter_index": quarter_result.value,
		&"month_step_index": month_result.value,
	}
	if not context.emit_event(EVENT_ID, payload):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
