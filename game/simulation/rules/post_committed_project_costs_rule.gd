class_name PostCommittedProjectCostsRule
extends SimulationRule

const RULE_ID: StringName = &"rule.project.post_committed_costs"
const EVENT_ID: StringName = &"event.project.started"
const LEDGER_CATEGORY_ID: StringName = &"cash_category.project.start"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Post committed Project costs and reservations"
	phase_id = SimulationRulePhase.POST_COMMITTED_COSTS
	execution_order = 10
	read_state_paths = [
		CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH,
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.COMPANY_PROJECTS,
		CanonicalSimulationStatePaths.COMPANY_PROJECT_TEAM_COUNT,
		CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY,
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH,
		CanonicalSimulationStatePaths.COMPANY_PROJECTS,
		CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS,
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.projects"
	specification_references = [
		"docs/marketing/marketing-scenario.md",
		"docs/simulation/time-model.md",
	]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var batch: PendingCommandBatchState = context.read_pending_command_batch()
	if context.has_fault():
		return _failed_from_context(context)
	if batch == null:
		return SimulationRuleEvaluation.did_not_fire()
	if not batch.is_consumed():
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.project.pending_command_batch_not_consumed",
				"Pending Command Batch %s is not consumed." % batch.stable_id,
				stable_id,
				CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH
			)
		)
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	var projects: Dictionary[StringName, ProjectState] = {}
	projects.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS))
	if context.has_fault():
		return _failed_from_context(context)
	var team_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.COMPANY_PROJECT_TEAM_COUNT
	)
	if not team_result.has_value:
		return SimulationRuleEvaluation.failed(team_result.diagnostic)
	var compute_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY
	)
	if not compute_result.has_value:
		return SimulationRuleEvaluation.failed(compute_result.diagnostic)
	var ledger_sequence_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE
	)
	if not ledger_sequence_result.has_value:
		return SimulationRuleEvaluation.failed(ledger_sequence_result.diagnostic)
	var next_ledger_sequence: int = ledger_sequence_result.value
	for command: Command in batch.commands:
		if command == null or command.command_type_id != ProjectPlanValidator.START_COMMAND_TYPE:
			continue
		var project_id: StringName = StringName(str(command.payload[ProjectDefinition.PAYLOAD_PROJECT_ID]))
		var definition: ProjectDefinition = context.get_project_definition(project_id)
		if definition == null:
			return _failed_from_context(context)
		if projects.has(project_id):
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.project.duplicate_active_project",
					"Project %s already exists." % project_id,
					stable_id,
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
		var project: ProjectState = ProjectState.new()
		project.stable_id = project_id
		project.content_definition_id = project_id
		project.status_id = ProjectState.STATUS_ACTIVE
		project.remaining_month_steps = definition.duration_month_steps
		project.reserved_project_teams = definition.reserved_project_teams
		project.reserved_compute_unit_months = definition.reserved_compute_unit_months
		project.started_month_step_index = month_result.value
		project.start_payload = command.payload
		projects[project_id] = project
		if ProjectCapacity.reserved_project_teams(projects) > team_result.value:
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.project.teams_exceeded",
					"Starting Project %s exceeds project-team capacity." % project_id,
					stable_id,
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
		if ProjectCapacity.reserved_compute_unit_months(projects) > compute_result.value:
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.project.compute_exceeded",
					"Starting Project %s exceeds free Compute Capacity." % project_id,
					stable_id,
					CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY
				)
			)
		if definition.start_cost_musd > 0:
			var transaction: LedgerTransactionState = LedgerTransactionState.new()
			transaction.stable_id = StableIdentifier.format_runtime_identifier(
				&"ledger_transaction",
				next_ledger_sequence
			)
			transaction.month_step_index = month_result.value
			transaction.source_rule_id = stable_id
			transaction.category_id = LEDGER_CATEGORY_ID
			transaction.amount_musd = -definition.start_cost_musd
			transaction.source_entity_id = project_id
			if not context.append_ledger_transaction(transaction):
				return _failed_from_context(context)
			next_ledger_sequence += 1
		var payload: Dictionary[StringName, Variant] = {
			&"project_id": project_id,
			&"month_step_index": month_result.value,
		}
		if not context.emit_event(EVENT_ID, payload):
			return _failed_from_context(context)
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
		next_ledger_sequence
	):
		return _failed_from_context(context)
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS, projects):
		return _failed_from_context(context)
	if not context.write_pending_command_batch(null):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
