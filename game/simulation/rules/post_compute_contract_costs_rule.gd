class_name PostComputeContractCostsRule
extends SimulationRule

const RULE_ID: StringName = &"rule.finance.post_compute_contract_costs"
const EVENT_ID: StringName = &"event.finance.compute_contract_cost"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Post compute-contract costs"
	phase_id = SimulationRulePhase.RESOLVE_CONTRACTS_REVENUE_OPERATING_COSTS
	execution_order = 20
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.COMPANY_CONTRACTS,
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
	var contracts: Dictionary[StringName, ContractState] = {}
	contracts.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_CONTRACTS))
	if context.has_fault():
		return _failed_from_context(context)
	var ledger_sequence_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE
	)
	if not ledger_sequence_result.has_value:
		return SimulationRuleEvaluation.failed(ledger_sequence_result.diagnostic)
	var next_ledger_sequence: int = ledger_sequence_result.value
	var contract_ids: Array[StringName] = []
	contract_ids.assign(contracts.keys())
	contract_ids.sort()
	var posted: bool = false
	for contract_id: StringName in contract_ids:
		var contract: ContractState = contracts[contract_id]
		if contract == null or contract.status_id != &"contract_state.active":
			continue
		var definition: ContractDefinition = context.get_contract_definition(contract.content_definition_id)
		if definition == null:
			return _failed_from_context(context)
		if definition.monthly_cost_musd < 1:
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.finance.missing_compute_contract_cost",
					"Compute contract %s monthly cost must be at least 1 MUSD." % contract_id,
					stable_id,
					CanonicalSimulationStatePaths.COMPANY_CONTRACTS
				)
			)
		var transaction: LedgerTransactionState = LedgerTransactionState.new()
		transaction.stable_id = StableIdentifier.format_runtime_identifier(
			&"ledger_transaction",
			next_ledger_sequence
		)
		transaction.month_step_index = month_result.value
		transaction.source_rule_id = stable_id
		transaction.category_id = definition.ledger_category_id
		transaction.amount_musd = -definition.monthly_cost_musd
		transaction.source_entity_id = contract_id
		if not context.append_ledger_transaction(transaction):
			return _failed_from_context(context)
		next_ledger_sequence += 1
		var payload: Dictionary[StringName, Variant] = {
			&"contract_id": contract_id,
			&"month_step_index": month_result.value,
			&"amount_musd": -definition.monthly_cost_musd,
		}
		if not context.emit_event(EVENT_ID, payload):
			return _failed_from_context(context)
		posted = true
	if not posted:
		return SimulationRuleEvaluation.did_not_fire()
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
		next_ledger_sequence
	):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
