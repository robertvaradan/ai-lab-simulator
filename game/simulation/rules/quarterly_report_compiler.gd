class_name QuarterlyReportCompiler
extends RefCounted

const NORTHSTAR_ID: StringName = &"competitor.northstar"
const CODING_AGENT_MARKET_ID: StringName = &"market.coding_agent"


static func compile_opening(
		state: GameState,
		competitor_definitions: Array[CompetitorDefinition]
	) -> QuarterlyReportState:
	return compile(
		state,
		competitor_definitions,
		QuarterlyReportState.KIND_OPENING,
		QuarterlyReportState.KIND_OPENING,
		null
	)


static func compile_ending(
		state: GameState,
		competitor_definitions: Array[CompetitorDefinition],
		report_id: StringName,
		previous_report: QuarterlyReportState
	) -> QuarterlyReportState:
	return compile(
		state,
		competitor_definitions,
		QuarterlyReportState.KIND_ENDING,
		report_id,
		previous_report
	)


static func compile(
		state: GameState,
		competitor_definitions: Array[CompetitorDefinition],
		report_kind_id: StringName,
		report_id: StringName,
		previous_report: QuarterlyReportState
	) -> QuarterlyReportState:
	var report: QuarterlyReportState = QuarterlyReportState.new()
	report.stable_id = report_id
	report.report_kind_id = report_kind_id
	report.quarter_index = state.calendar.current_quarter_index
	report.month_step_index = state.calendar.current_month_step_index
	report.cash_balance_musd = state.cash_ledger.calculate_balance_musd()
	report.cash_changes = _cash_changes_for_quarter(state, report_kind_id)
	report.projects = _project_entries(state.company.projects)
	report.models = _model_entries(state.company.models)
	report.applications = _application_entries(state.company.applications)
	report.competitor_forecasts = _forecasts(competitor_definitions)
	var competitor: CompetitorState = state.world.competitors[NORTHSTAR_ID]
	report.competitor_stage_id = competitor.stage_id
	if state.world.models.has(CompetitorDefinition.RELEASED_MODEL_ID):
		var released_model: ModelState = state.world.models[CompetitorDefinition.RELEASED_MODEL_ID]
		report.released_competitor_model_id = released_model.stable_id
		report.released_competitor_evaluations = QuarterlyReportState._copy_evaluations(
			released_model.evaluations
		)
	report.technical_frontier = QuarterlyReportState._copy_evaluations(state.world.technical_frontier)
	var market: MarketState = state.world.markets[CODING_AGENT_MARKET_ID]
	report.customer_expectation_coding_evaluation_points = (
		market.customer_expectation_coding_evaluation_points
	)
	report.public_trust_points = state.company.public_trust_points
	report.government_trust_points = state.company.government_trust_points
	if previous_report == null:
		report.previous_technical_frontier = QuarterlyReportState._copy_evaluations(
			report.technical_frontier
		)
		report.previous_customer_expectation_coding_evaluation_points = (
			report.customer_expectation_coding_evaluation_points
		)
		report.previous_public_trust_points = report.public_trust_points
		report.previous_government_trust_points = report.government_trust_points
	else:
		report.previous_technical_frontier = QuarterlyReportState._copy_evaluations(
			previous_report.technical_frontier
		)
		report.previous_customer_expectation_coding_evaluation_points = (
			previous_report.customer_expectation_coding_evaluation_points
		)
		report.previous_public_trust_points = previous_report.public_trust_points
		report.previous_government_trust_points = previous_report.government_trust_points
	return report.immutable_copy()


static func _cash_changes_for_quarter(
		state: GameState,
		report_kind_id: StringName
	) -> Array[QuarterlyReportCashChange]:
	var changes: Array[QuarterlyReportCashChange] = []
	if report_kind_id == QuarterlyReportState.KIND_OPENING:
		return changes
	var first_month: int = (state.calendar.current_quarter_index - 1) * 3 + 1
	var last_month: int = state.calendar.current_quarter_index * 3
	var totals: Dictionary[StringName, int] = {}
	for transaction: LedgerTransactionState in state.cash_ledger.transactions:
		if transaction == null:
			continue
		if transaction.month_step_index < first_month or transaction.month_step_index > last_month:
			continue
		if totals.has(transaction.category_id):
			totals[transaction.category_id] = totals[transaction.category_id] + transaction.amount_musd
		else:
			totals[transaction.category_id] = transaction.amount_musd
	var category_ids: Array[StringName] = []
	category_ids.assign(totals.keys())
	category_ids.sort()
	for category_id: StringName in category_ids:
		var cash_change: QuarterlyReportCashChange = QuarterlyReportCashChange.new()
		cash_change.category_id = category_id
		cash_change.amount_musd = totals[category_id]
		changes.append(cash_change)
	return changes


static func _project_entries(
		projects: Dictionary[StringName, ProjectState]
	) -> Array[QuarterlyReportProjectEntry]:
	var entries: Array[QuarterlyReportProjectEntry] = []
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	project_ids.sort()
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null:
			continue
		var entry: QuarterlyReportProjectEntry = QuarterlyReportProjectEntry.new()
		entry.project_id = project.stable_id
		entry.status_id = project.status_id
		entry.remaining_month_steps = project.remaining_month_steps
		entries.append(entry)
	return entries


static func _model_entries(
		models: Dictionary[StringName, ModelState]
	) -> Array[QuarterlyReportModelEntry]:
	var entries: Array[QuarterlyReportModelEntry] = []
	var model_ids: Array[StringName] = []
	model_ids.assign(models.keys())
	model_ids.sort()
	for model_id: StringName in model_ids:
		var model: ModelState = models[model_id]
		if model == null or model.evaluations == null:
			continue
		var entry: QuarterlyReportModelEntry = QuarterlyReportModelEntry.new()
		entry.model_id = model.stable_id
		entry.coding_evaluation_points = model.evaluations.coding_evaluation_points
		entry.reasoning_evaluation_points = model.evaluations.reasoning_evaluation_points
		entry.efficiency_evaluation_points = model.evaluations.efficiency_evaluation_points
		entries.append(entry)
	return entries


static func _application_entries(
		applications: Dictionary[StringName, ApplicationState]
	) -> Array[QuarterlyReportApplicationEntry]:
	var entries: Array[QuarterlyReportApplicationEntry] = []
	var application_ids: Array[StringName] = []
	application_ids.assign(applications.keys())
	application_ids.sort()
	for application_id: StringName in application_ids:
		var application: ApplicationState = applications[application_id]
		if application == null:
			continue
		var entry: QuarterlyReportApplicationEntry = QuarterlyReportApplicationEntry.new()
		entry.application_id = application.stable_id
		entry.supporting_model_id = application.supporting_model_id
		entry.active_customer_contract_count = application.active_customer_contract_count
		entry.price_musd_per_contract_month = application.price_musd_per_contract_month
		entries.append(entry)
	return entries


static func _forecasts(
		competitor_definitions: Array[CompetitorDefinition]
	) -> Array[CompetitorForecast]:
	var forecasts: Array[CompetitorForecast] = []
	var definitions: Array[CompetitorDefinition] = []
	definitions.assign(competitor_definitions)
	definitions.sort_custom(
		func(left: CompetitorDefinition, right: CompetitorDefinition) -> bool:
			return String(left.stable_id) < String(right.stable_id)
	)
	for definition: CompetitorDefinition in definitions:
		if definition == null:
			continue
		forecasts.append(definition.create_forecast())
	return forecasts
