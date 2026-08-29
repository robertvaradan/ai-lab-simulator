class_name SimulationInvariantChecker
extends RefCounted

const INVARIANT_IDENTITY: StringName = &"invariant.identity"
const INVARIANT_TIME: StringName = &"invariant.time"
const INVARIANT_CASH: StringName = &"invariant.cash"
const INVARIANT_CAPACITY: StringName = &"invariant.capacity"
const INVARIANT_RULES: StringName = &"invariant.rules"


static func check_after_month_step(
		state: GameState,
		trace: SimulationTrace,
		ordered_rules: Array[SimulationRule],
		content_registry: SimulationContentRegistry,
		previous_month_step_index: int,
		previous_cash_balance_musd: int,
		trace_start_index: int
	) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	if state == null:
		diagnostics.append(
			_fail(
				&"invariant.missing_state",
				INVARIANT_IDENTITY,
				-1,
				"The Month Step produced a missing Game State."
			)
		)
		return diagnostics
	var month_step_index: int = state.calendar.current_month_step_index
	_check_identity(state, content_registry, month_step_index, diagnostics)
	_check_time(state, content_registry, previous_month_step_index, month_step_index, diagnostics)
	_check_cash(state, previous_cash_balance_musd, month_step_index, diagnostics)
	_check_capacity(state, month_step_index, diagnostics)
	_check_rules(
		state,
		trace,
		ordered_rules,
		month_step_index,
		trace_start_index,
		diagnostics
	)
	return diagnostics


static func _check_identity(
		state: GameState,
		content_registry: SimulationContentRegistry,
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	_check_unique_site_ids(state.company.sites, month_step_index, diagnostics)
	_check_unique_project_ids(state.company.projects, month_step_index, diagnostics)
	_check_unique_model_ids(
		state.company.models,
		"Model",
		CanonicalSimulationStatePaths.COMPANY_MODELS,
		month_step_index,
		diagnostics
	)
	_check_unique_application_ids(state.company.applications, month_step_index, diagnostics)
	_check_unique_contract_ids(state.company.contracts, month_step_index, diagnostics)
	_check_unique_competitor_ids(state.world.competitors, month_step_index, diagnostics)
	_check_unique_model_ids(
		state.world.models,
		"World Model",
		CanonicalSimulationStatePaths.WORLD_MODELS,
		month_step_index,
		diagnostics
	)
	_check_unique_market_ids(state.world.markets, month_step_index, diagnostics)
	_check_unique_attention_ids(state.attention_events, month_step_index, diagnostics)
	_check_unique_notification_ids(state.notifications, month_step_index, diagnostics)
	_check_unique_report_ids(state.quarterly_reports, month_step_index, diagnostics)
	for project_id: StringName in state.company.projects.keys():
		var project: ProjectState = state.company.projects[project_id]
		if project == null:
			continue
		if content_registry == null or not content_registry.has_project_definition(project.content_definition_id):
			diagnostics.append(
				_fail(
					&"invariant.unknown_project_content",
					INVARIANT_IDENTITY,
					month_step_index,
					"Project %s references unknown content %s."
					% [project.stable_id, project.content_definition_id],
					&"",
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
	for application_id: StringName in state.company.applications.keys():
		var application: ApplicationState = state.company.applications[application_id]
		if application == null:
			continue
		if application.supporting_model_id == &"":
			diagnostics.append(
				_fail(
					&"invariant.application_missing_model",
					INVARIANT_IDENTITY,
					month_step_index,
					"Application %s does not reference a supporting Model." % application.stable_id,
					&"",
					CanonicalSimulationStatePaths.COMPANY_APPLICATIONS
				)
			)
		elif not state.company.models.has(application.supporting_model_id):
			diagnostics.append(
				_fail(
					&"invariant.application_unknown_model",
					INVARIANT_IDENTITY,
					month_step_index,
					"Application %s references unknown Model %s."
					% [application.stable_id, application.supporting_model_id],
					&"",
					CanonicalSimulationStatePaths.COMPANY_APPLICATIONS
				)
			)
	for contract_id: StringName in state.company.contracts.keys():
		var contract: ContractState = state.company.contracts[contract_id]
		if contract == null:
			continue
		if content_registry == null or not content_registry.has_contract_definition(contract.content_definition_id):
			diagnostics.append(
				_fail(
					&"invariant.unknown_contract_content",
					INVARIANT_IDENTITY,
					month_step_index,
					"Contract %s references unknown content %s."
					% [contract.stable_id, contract.content_definition_id],
					&"",
					CanonicalSimulationStatePaths.COMPANY_CONTRACTS
				)
			)
	for competitor_id: StringName in state.world.competitors.keys():
		var competitor: CompetitorState = state.world.competitors[competitor_id]
		if competitor == null:
			continue
		if content_registry == null or not content_registry.has_competitor_definition(competitor.stable_id):
			diagnostics.append(
				_fail(
					&"invariant.unknown_competitor",
					INVARIANT_IDENTITY,
					month_step_index,
					"Competitor %s is not registered content." % competitor.stable_id,
					&"",
					CanonicalSimulationStatePaths.WORLD_COMPETITORS
				)
			)


static func _check_time(
		state: GameState,
		content_registry: SimulationContentRegistry,
		previous_month_step_index: int,
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	if month_step_index != previous_month_step_index + 1:
		diagnostics.append(
			_fail(
				&"invariant.month_step_not_incremented",
				INVARIANT_TIME,
				month_step_index,
				"Month Step index changed from %d to %d."
				% [previous_month_step_index, month_step_index],
				OpenMonthStepRule.RULE_ID,
				CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
			)
		)
	var expected_quarter_index: int = (month_step_index + 2) / 3
	if expected_quarter_index < 1:
		expected_quarter_index = 1
	if state.calendar.current_quarter_index != expected_quarter_index:
		diagnostics.append(
			_fail(
				&"invariant.quarter_index_mismatch",
				INVARIANT_TIME,
				month_step_index,
				"Quarter index %d does not match Month Step %d."
				% [state.calendar.current_quarter_index, month_step_index],
				OpenMonthStepRule.RULE_ID,
				CanonicalSimulationStatePaths.CALENDAR_QUARTER_INDEX
			)
		)
	if month_step_index % 3 == 0 and not _has_quarter_boundary_attention(state):
		diagnostics.append(
			_fail(
				&"invariant.quarter_boundary_attention_missing",
				INVARIANT_TIME,
				month_step_index,
				"Month Step %d did not create a Quarter Boundary Attention Event." % month_step_index,
				CreateQuarterBoundaryAttentionRule.RULE_ID,
				CanonicalSimulationStatePaths.ATTENTION_EVENTS
			)
		)
	for project_id: StringName in state.company.projects.keys():
		var project: ProjectState = state.company.projects[project_id]
		if project == null:
			continue
		var definition: ProjectDefinition = null
		if content_registry != null:
			definition = content_registry.get_project_definition(project.content_definition_id)
		if project.is_active():
			if project.remaining_month_steps < 1:
				diagnostics.append(
					_fail(
						&"invariant.active_project_without_remaining_duration",
						INVARIANT_TIME,
						month_step_index,
						"Active Project %s has no remaining Month Steps." % project.stable_id,
						AdvanceActiveProjectsRule.RULE_ID,
						CanonicalSimulationStatePaths.COMPANY_PROJECTS
					)
				)
			if project.completed_month_step_index != 0:
				diagnostics.append(
					_fail(
						&"invariant.active_project_has_completion_month",
						INVARIANT_TIME,
						month_step_index,
						"Active Project %s has a completion Month Step." % project.stable_id,
						ResolveProjectCompletionsRule.RULE_ID,
						CanonicalSimulationStatePaths.COMPANY_PROJECTS
					)
				)
			continue
		if project.status_id != ProjectState.STATUS_COMPLETED:
			continue
		if project.remaining_month_steps != 0:
			diagnostics.append(
				_fail(
					&"invariant.completed_project_has_remaining_duration",
					INVARIANT_TIME,
					month_step_index,
					"Completed Project %s still has remaining Month Steps." % project.stable_id,
					ResolveProjectCompletionsRule.RULE_ID,
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
		if project.completed_month_step_index < 1:
			diagnostics.append(
				_fail(
					&"invariant.completed_project_missing_completion_month",
					INVARIANT_TIME,
					month_step_index,
					"Completed Project %s has no completion Month Step." % project.stable_id,
					ResolveProjectCompletionsRule.RULE_ID,
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
			continue
		if definition == null:
			continue
		var earliest_completion_month: int = (
			project.started_month_step_index + definition.duration_month_steps - 1
		)
		if project.completed_month_step_index < earliest_completion_month:
			diagnostics.append(
				_fail(
					&"invariant.project_completed_before_declared_month",
					INVARIANT_TIME,
					month_step_index,
					"Project %s completed in Month Step %d before declared Month Step %d."
					% [
						project.stable_id,
						project.completed_month_step_index,
						earliest_completion_month,
					],
					ResolveProjectCompletionsRule.RULE_ID,
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)


static func _check_cash(
		state: GameState,
		previous_cash_balance_musd: int,
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var ledger: CashLedgerState = state.cash_ledger
	if ledger == null:
		diagnostics.append(
			_fail(
				&"invariant.missing_cash_ledger",
				INVARIANT_CASH,
				month_step_index,
				"The Cash Ledger is missing.",
				&"",
				CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS
			)
		)
		return
	var calculated_balance_musd: int = ledger.calculate_balance_musd()
	var month_transaction_sum_musd: int = 0
	var seen_transaction_ids: Dictionary[StringName, bool] = {}
	var previous_transaction_month: int = -1
	for transaction: LedgerTransactionState in ledger.transactions:
		if transaction == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_ledger_transaction",
					INVARIANT_CASH,
					month_step_index,
					"The Cash Ledger contains a missing transaction.",
					&"",
					CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS
				)
			)
			continue
		if seen_transaction_ids.has(transaction.stable_id):
			diagnostics.append(
				_fail(
					&"invariant.duplicate_ledger_transaction",
					INVARIANT_CASH,
					month_step_index,
					"Ledger transaction identifier %s is duplicated." % transaction.stable_id,
					transaction.source_rule_id,
					CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS
				)
			)
		seen_transaction_ids[transaction.stable_id] = true
		if transaction.month_step_index < previous_transaction_month:
			diagnostics.append(
				_fail(
					&"invariant.ledger_month_order",
					INVARIANT_CASH,
					month_step_index,
					"Ledger transaction %s has Month Step index %d after Month Step index %d."
					% [
						transaction.stable_id,
						transaction.month_step_index,
						previous_transaction_month,
					],
					transaction.source_rule_id,
					CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS
				)
			)
		previous_transaction_month = transaction.month_step_index
		if transaction.month_step_index == month_step_index:
			month_transaction_sum_musd += transaction.amount_musd
	var expected_balance_musd: int = previous_cash_balance_musd + month_transaction_sum_musd
	if calculated_balance_musd != expected_balance_musd:
		diagnostics.append(
			_fail(
				&"invariant.cash_balance",
				INVARIANT_CASH,
				month_step_index,
				"Cash balance %d does not equal previous balance %d plus Month Step %d ledger sum %d."
				% [
					calculated_balance_musd,
					previous_cash_balance_musd,
					month_step_index,
					month_transaction_sum_musd,
				],
				&"",
				CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS
			)
		)
	for report: QuarterlyReportState in state.quarterly_reports:
		if report == null:
			continue
		if report.report_kind_id != QuarterlyReportState.KIND_ENDING:
			continue
		if report.month_step_index != month_step_index:
			continue
		if report.cash_balance_musd != calculated_balance_musd:
			diagnostics.append(
				_fail(
					&"invariant.report_cash_balance",
					INVARIANT_CASH,
					month_step_index,
					"Ending Quarterly Report Cash %d does not equal the Cash Ledger balance %d."
					% [report.cash_balance_musd, calculated_balance_musd],
					CreateQuarterlyReportRule.RULE_ID,
					CanonicalSimulationStatePaths.QUARTERLY_REPORTS
				)
			)


static func _check_capacity(
		state: GameState,
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var reserved_teams: int = ProjectCapacity.reserved_project_teams(state.company.projects)
	if reserved_teams > state.company.project_team_count:
		diagnostics.append(
			_fail(
				&"invariant.project_team_overcommit",
				INVARIANT_CAPACITY,
				month_step_index,
				"Reserved project teams %d exceed available project teams %d."
				% [reserved_teams, state.company.project_team_count],
				PostCommittedProjectCostsRule.RULE_ID,
				CanonicalSimulationStatePaths.COMPANY_PROJECTS
			)
		)
	var reserved_compute: int = ProjectCapacity.reserved_compute_unit_months(state.company.projects)
	if reserved_compute > state.company.compute_capacity_unit_months:
		diagnostics.append(
			_fail(
				&"invariant.compute_overcommit",
				INVARIANT_CAPACITY,
				month_step_index,
				"Reserved Compute Capacity %d exceeds available Compute Capacity %d."
				% [reserved_compute, state.company.compute_capacity_unit_months],
				PostCommittedProjectCostsRule.RULE_ID,
				CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY
			)
		)


static func _check_rules(
		state: GameState,
		trace: SimulationTrace,
		ordered_rules: Array[SimulationRule],
		month_step_index: int,
		trace_start_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	if state.pending_command_batch != null:
		var batch_code: StringName = &"invariant.pending_command_batch_retained"
		if state.pending_command_batch.is_consumed():
			batch_code = &"invariant.pending_command_batch_consumed"
		diagnostics.append(
			_fail(
				batch_code,
				INVARIANT_RULES,
				month_step_index,
				"A Pending Command Batch must not remain in Game State after the Month Step.",
				ConsumePendingCommandBatchRule.RULE_ID,
				CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH
			)
		)
	if month_step_index % 3 == 0 and not _has_quarter_boundary_attention(state):
		diagnostics.append(
			_fail(
				&"invariant.required_attention_event_missing",
				INVARIANT_RULES,
				month_step_index,
				"The required Quarter Boundary Attention Event is missing.",
				CreateQuarterBoundaryAttentionRule.RULE_ID,
				CanonicalSimulationStatePaths.ATTENTION_EVENTS
			)
		)
	if trace == null:
		diagnostics.append(
			_fail(
				&"invariant.missing_trace",
				INVARIANT_RULES,
				month_step_index,
				"The Month Step produced a missing Simulation Trace."
			)
		)
		return
	var rules_by_id: Dictionary[StringName, SimulationRule] = {}
	for rule: SimulationRule in ordered_rules:
		if rule == null:
			continue
		rules_by_id[rule.stable_id] = rule
	var records: Array[SimulationTraceRecord] = trace.get_records()
	var close_month_fired: bool = false
	for record_index: int in range(trace_start_index, records.size()):
		var record: SimulationTraceRecord = records[record_index]
		if record.kind == SimulationTraceRecord.Kind.STATE_WRITE:
			var write_record: StateWriteTraceRecord = record as StateWriteTraceRecord
			if write_record == null:
				continue
			if close_month_fired:
				diagnostics.append(
					_fail(
						&"invariant.write_after_close_month_step",
						INVARIANT_RULES,
						month_step_index,
						"Rule %s wrote state after Close Month Step." % write_record.rule_id,
						write_record.rule_id,
						write_record.state_path
					)
				)
			if not rules_by_id.has(write_record.rule_id):
				diagnostics.append(
					_fail(
						&"invariant.write_from_unknown_rule",
						INVARIANT_RULES,
						month_step_index,
						"State path %s was written by unknown Rule %s."
						% [write_record.state_path, write_record.rule_id],
						write_record.rule_id,
						write_record.state_path
					)
				)
			else:
				var writer: SimulationRule = rules_by_id[write_record.rule_id]
				if not writer.write_state_paths.has(write_record.state_path):
					diagnostics.append(
						_fail(
							&"invariant.undeclared_state_write",
							INVARIANT_RULES,
							month_step_index,
							"Rule %s wrote undeclared state path %s."
							% [write_record.rule_id, write_record.state_path],
							write_record.rule_id,
							write_record.state_path
						)
					)
			continue
		if record.kind != SimulationTraceRecord.Kind.RULE_EVALUATION:
			continue
		var rule_record: RuleEvaluationTraceRecord = record as RuleEvaluationTraceRecord
		if rule_record == null:
			continue
		if (
			rule_record.rule_id == CloseMonthStepRule.RULE_ID
			and rule_record.status == SimulationRuleEvaluation.Status.FIRED
		):
			close_month_fired = true


static func _check_unique_site_ids(
		sites: Dictionary[StringName, SiteState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var site_ids: Array[StringName] = []
	site_ids.assign(sites.keys())
	for site_id: StringName in site_ids:
		var site: SiteState = sites[site_id]
		if site == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Site %s is missing." % site_id
				)
			)
			continue
		_record_unique_id(
			seen,
			site_id,
			site.stable_id,
			"Site",
			CanonicalSimulationStatePaths.COMPANY_PROJECTS,
			month_step_index,
			diagnostics
		)
		_check_unique_plot_ids(site.site_plots, month_step_index, diagnostics)


static func _check_unique_plot_ids(
		plots: Dictionary[StringName, SitePlotState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var plot_ids: Array[StringName] = []
	plot_ids.assign(plots.keys())
	for plot_id: StringName in plot_ids:
		var plot: SitePlotState = plots[plot_id]
		if plot == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Site Plot %s is missing." % plot_id
				)
			)
			continue
		_record_unique_id(
			seen,
			plot_id,
			plot.stable_id,
			"Site Plot",
			CanonicalSimulationStatePaths.COMPANY_PROJECTS,
			month_step_index,
			diagnostics
		)


static func _check_unique_project_ids(
		projects: Dictionary[StringName, ProjectState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Project %s is missing." % project_id,
					&"",
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
			continue
		_record_unique_id(
			seen,
			project_id,
			project.stable_id,
			"Project",
			CanonicalSimulationStatePaths.COMPANY_PROJECTS,
			month_step_index,
			diagnostics
		)


static func _check_unique_model_ids(
		models: Dictionary[StringName, ModelState],
		entity_name: String,
		state_path: StringName,
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var model_ids: Array[StringName] = []
	model_ids.assign(models.keys())
	for model_id: StringName in model_ids:
		var model: ModelState = models[model_id]
		if model == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"%s %s is missing." % [entity_name, model_id],
					&"",
					state_path
				)
			)
			continue
		_record_unique_id(
			seen,
			model_id,
			model.stable_id,
			entity_name,
			state_path,
			month_step_index,
			diagnostics
		)


static func _check_unique_application_ids(
		applications: Dictionary[StringName, ApplicationState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var application_ids: Array[StringName] = []
	application_ids.assign(applications.keys())
	for application_id: StringName in application_ids:
		var application: ApplicationState = applications[application_id]
		if application == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Application %s is missing." % application_id,
					&"",
					CanonicalSimulationStatePaths.COMPANY_APPLICATIONS
				)
			)
			continue
		_record_unique_id(
			seen,
			application_id,
			application.stable_id,
			"Application",
			CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
			month_step_index,
			diagnostics
		)


static func _check_unique_contract_ids(
		contracts: Dictionary[StringName, ContractState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var contract_ids: Array[StringName] = []
	contract_ids.assign(contracts.keys())
	for contract_id: StringName in contract_ids:
		var contract: ContractState = contracts[contract_id]
		if contract == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Contract %s is missing." % contract_id,
					&"",
					CanonicalSimulationStatePaths.COMPANY_CONTRACTS
				)
			)
			continue
		_record_unique_id(
			seen,
			contract_id,
			contract.stable_id,
			"Contract",
			CanonicalSimulationStatePaths.COMPANY_CONTRACTS,
			month_step_index,
			diagnostics
		)


static func _check_unique_competitor_ids(
		competitors: Dictionary[StringName, CompetitorState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var competitor_ids: Array[StringName] = []
	competitor_ids.assign(competitors.keys())
	for competitor_id: StringName in competitor_ids:
		var competitor: CompetitorState = competitors[competitor_id]
		if competitor == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Competitor %s is missing." % competitor_id,
					&"",
					CanonicalSimulationStatePaths.WORLD_COMPETITORS
				)
			)
			continue
		_record_unique_id(
			seen,
			competitor_id,
			competitor.stable_id,
			"Competitor",
			CanonicalSimulationStatePaths.WORLD_COMPETITORS,
			month_step_index,
			diagnostics
		)


static func _check_unique_market_ids(
		markets: Dictionary[StringName, MarketState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	var market_ids: Array[StringName] = []
	market_ids.assign(markets.keys())
	for market_id: StringName in market_ids:
		var market: MarketState = markets[market_id]
		if market == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Market %s is missing." % market_id,
					&"",
					CanonicalSimulationStatePaths.WORLD_MARKETS
				)
			)
			continue
		_record_unique_id(
			seen,
			market_id,
			market.stable_id,
			"Market",
			CanonicalSimulationStatePaths.WORLD_MARKETS,
			month_step_index,
			diagnostics
		)


static func _check_unique_attention_ids(
		events: Array[AttentionEventState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for event: AttentionEventState in events:
		if event == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Attention Event entry is missing."
				)
			)
			continue
		if seen.has(event.stable_id):
			diagnostics.append(
				_fail(
					&"invariant.duplicate_entity_id",
					INVARIANT_IDENTITY,
					month_step_index,
					"Attention Event identifier %s is duplicated." % event.stable_id
				)
			)
		seen[event.stable_id] = true


static func _check_unique_notification_ids(
		notifications: Array[NotificationState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for notification: NotificationState in notifications:
		if notification == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Notification entry is missing."
				)
			)
			continue
		if seen.has(notification.stable_id):
			diagnostics.append(
				_fail(
					&"invariant.duplicate_entity_id",
					INVARIANT_IDENTITY,
					month_step_index,
					"Notification identifier %s is duplicated." % notification.stable_id
				)
			)
		seen[notification.stable_id] = true


static func _check_unique_report_ids(
		reports: Array[QuarterlyReportState],
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for report: QuarterlyReportState in reports:
		if report == null:
			diagnostics.append(
				_fail(
					&"invariant.missing_entity",
					INVARIANT_IDENTITY,
					month_step_index,
					"Quarterly Report entry is missing."
				)
			)
			continue
		if seen.has(report.stable_id):
			diagnostics.append(
				_fail(
					&"invariant.duplicate_entity_id",
					INVARIANT_IDENTITY,
					month_step_index,
					"Quarterly Report identifier %s is duplicated." % report.stable_id
				)
			)
		seen[report.stable_id] = true


static func _record_unique_id(
		seen: Dictionary[StringName, bool],
		entity_id: StringName,
		stable_id: StringName,
		entity_name: String,
		state_path: StringName,
		month_step_index: int,
		diagnostics: Array[SimulationDiagnostic]
	) -> void:
	if stable_id != entity_id:
		diagnostics.append(
			_fail(
				&"invariant.entity_key_mismatch",
				INVARIANT_IDENTITY,
				month_step_index,
				"%s key %s does not equal stable identifier %s." % [entity_name, entity_id, stable_id],
				&"",
				state_path
			)
		)
	if seen.has(stable_id):
		diagnostics.append(
			_fail(
				&"invariant.duplicate_entity_id",
				INVARIANT_IDENTITY,
				month_step_index,
				"%s identifier %s is duplicated." % [entity_name, stable_id],
				&"",
				state_path
			)
		)
	seen[stable_id] = true


static func _has_quarter_boundary_attention(state: GameState) -> bool:
	for event: AttentionEventState in state.attention_events:
		if event != null and event.event_type_id == CreateQuarterBoundaryAttentionRule.EVENT_TYPE_ID:
			return true
	return false


static func _fail(
		code: StringName,
		invariant_id: StringName,
		month_step_index: int,
		message: String,
		rule_id: StringName = &"",
		state_path: StringName = &""
	) -> SimulationDiagnostic:
	return SimulationDiagnostic.new(
		SimulationDiagnostic.Severity.ERROR,
		code,
		message,
		rule_id,
		state_path,
		invariant_id,
		month_step_index
	)
