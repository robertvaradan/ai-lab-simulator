class_name PostOperatingCostRule
extends SimulationRule

const RULE_ID: StringName = &"rule.finance.post_operating_cost"
const EVENT_ID: StringName = &"event.finance.operating_cost"
const LEDGER_CATEGORY_ID: StringName = &"cash_category.operating_cost"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Post Company operating cost"
	phase_id = SimulationRulePhase.RESOLVE_CONTRACTS_REVENUE_OPERATING_COSTS
	execution_order = 10
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.COMPANY_FIXED_OPERATING_COST,
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS,
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.finance"
	specification_references = [
		"docs/marketing/marketing-scenario.md",
		"docs/simulation/time-model.md",
	]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	var cost_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.COMPANY_FIXED_OPERATING_COST
	)
	if not cost_result.has_value:
		return SimulationRuleEvaluation.failed(cost_result.diagnostic)
	if cost_result.value < 1:
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.finance.missing_operating_cost",
				"The Company operating cost must be at least 1 MUSD.",
				stable_id,
				CanonicalSimulationStatePaths.COMPANY_FIXED_OPERATING_COST
			)
		)
	var ledger_sequence_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE
	)
	if not ledger_sequence_result.has_value:
		return SimulationRuleEvaluation.failed(ledger_sequence_result.diagnostic)
	var transaction: LedgerTransactionState = LedgerTransactionState.new()
	transaction.stable_id = StableIdentifier.format_runtime_identifier(
		&"ledger_transaction",
		ledger_sequence_result.value
	)
	transaction.month_step_index = month_result.value
	transaction.source_rule_id = stable_id
	transaction.category_id = LEDGER_CATEGORY_ID
	transaction.amount_musd = -cost_result.value
	if not context.append_ledger_transaction(transaction):
		return _failed_from_context(context)
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
		ledger_sequence_result.value + 1
	):
		return _failed_from_context(context)
	var payload: Dictionary[StringName, Variant] = {
		&"month_step_index": month_result.value,
		&"amount_musd": -cost_result.value,
	}
	if not context.emit_event(EVENT_ID, payload):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
