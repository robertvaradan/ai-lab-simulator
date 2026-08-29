class_name PostApplicationRevenueRule
extends SimulationRule

const RULE_ID: StringName = &"rule.market.post_application_revenue"
const EVENT_ID: StringName = &"event.application.coding_agent.revenue"
const LEDGER_CATEGORY_ID: StringName = &"cash_category.application.revenue"
const CODING_AGENT_ID: StringName = &"application.player.coding_agent"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Post Application Revenue"
	phase_id = SimulationRulePhase.RESOLVE_CONTRACTS_REVENUE_OPERATING_COSTS
	execution_order = 30
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
		CanonicalSimulationStatePaths.COMPANY_MODELS,
		CanonicalSimulationStatePaths.WORLD_MARKETS,
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
		CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS,
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.market"
	specification_references = [
		"docs/marketing/marketing-scenario.md",
		"docs/simulation/time-model.md",
		"docs/simulation/state-and-ledger.md",
	]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	var applications: Dictionary[StringName, ApplicationState] = {}
	applications.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_APPLICATIONS))
	if context.has_fault():
		return _failed_from_context(context)
	if not applications.has(CODING_AGENT_ID):
		return SimulationRuleEvaluation.did_not_fire()
	var application: ApplicationState = applications[CODING_AGENT_ID]
	if application == null or application.status_id != ApplicationState.STATUS_ACTIVE:
		return SimulationRuleEvaluation.did_not_fire()
	var models: Dictionary[StringName, ModelState] = {}
	models.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_MODELS))
	if context.has_fault():
		return _failed_from_context(context)
	if not models.has(application.supporting_model_id):
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.market.supporting_model_missing",
				"Coding Agent supporting Model %s does not exist." % application.supporting_model_id,
				stable_id,
				CanonicalSimulationStatePaths.COMPANY_MODELS
			)
		)
	var markets: Dictionary[StringName, MarketState] = {}
	markets.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MARKETS))
	if context.has_fault():
		return _failed_from_context(context)
	if not markets.has(CodingAgentMarket.MARKET_ID):
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.market.missing_market",
				"Market %s is missing from World State." % CodingAgentMarket.MARKET_ID,
				stable_id,
				CanonicalSimulationStatePaths.WORLD_MARKETS
			)
		)
	var calculation: CodingAgentDemandCalculation = CodingAgentMarket.calculate_demand(
		models[application.supporting_model_id],
		markets[CodingAgentMarket.MARKET_ID],
		application
	)
	if not calculation.succeeded:
		var diagnostic: SimulationDiagnostic = calculation.diagnostic
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				diagnostic.severity,
				diagnostic.code,
				diagnostic.message,
				stable_id,
				CanonicalSimulationStatePaths.COMPANY_APPLICATIONS
			)
		)
	if calculation.revenue_musd < 1:
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.market.zero_revenue",
				"Active Coding Agent Revenue must not be zero.",
				stable_id,
				CanonicalSimulationStatePaths.COMPANY_APPLICATIONS
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
	transaction.amount_musd = calculation.revenue_musd
	transaction.source_entity_id = application.stable_id
	if not context.append_ledger_transaction(transaction):
		return _failed_from_context(context)
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
		ledger_sequence_result.value + 1
	):
		return _failed_from_context(context)
	application.active_customer_contract_count = calculation.customer_contract_count
	if not context.write_resource_dictionary(
		CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
		applications
	):
		return _failed_from_context(context)
	var payload: Dictionary[StringName, Variant] = {
		&"application_id": application.stable_id,
		&"supporting_model_id": application.supporting_model_id,
		&"customer_expectation_coding_evaluation_points": (
			markets[CodingAgentMarket.MARKET_ID].customer_expectation_coding_evaluation_points
		),
		&"customer_contract_count": calculation.customer_contract_count,
		&"revenue_musd": calculation.revenue_musd,
		&"month_step_index": month_result.value,
	}
	if not context.emit_event(EVENT_ID, payload):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
