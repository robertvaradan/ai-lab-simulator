class_name QuarterlyReportValidator
extends RefCounted


static func validate(
		state: GameState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var seen_report_ids: Dictionary[StringName, bool] = {}
	var previous_report: QuarterlyReportState = null
	var previous_month: int = -1
	for report_index: int in range(state.quarterly_reports.size()):
		var report: QuarterlyReportState = state.quarterly_reports[report_index]
		if report == null:
			result.add_error("Quarterly Reports contain a missing report.")
			continue
		GameStateValidator._validate_identifier(report.stable_id, "Quarterly Report identifier", result)
		if seen_report_ids.has(report.stable_id):
			result.add_error("Quarterly Report identifier %s is duplicated." % report.stable_id)
		seen_report_ids[report.stable_id] = true
		if not report.is_immutable():
			result.add_error("Quarterly Report %s must be immutable." % report.stable_id)
		GameStateValidator._validate_content_reference(
			report.report_kind_id,
			"Quarterly Report %s kind identifier" % report.stable_id,
			known_content_ids,
			result
		)
		if (
			report.report_kind_id != QuarterlyReportState.KIND_OPENING
			and report.report_kind_id != QuarterlyReportState.KIND_ENDING
		):
			result.add_error(
				"Quarterly Report %s kind identifier %s is invalid."
				% [report.stable_id, report.report_kind_id]
			)
		if report.report_kind_id == QuarterlyReportState.KIND_OPENING:
			if report.stable_id != QuarterlyReportState.KIND_OPENING:
				result.add_error(
					"The opening Quarterly Report identifier %s is invalid." % report.stable_id
				)
			if report_index != 0:
				result.add_error("The opening Quarterly Report must be the first report.")
			if not report.cash_changes.is_empty():
				result.add_error("The opening Quarterly Report must not contain Cash changes.")
			if report.month_step_index != 0:
				result.add_error("The opening Quarterly Report Month Step index is invalid.")
		elif report.report_kind_id == QuarterlyReportState.KIND_ENDING:
			if report.stable_id != StableIdentifier.format_runtime_identifier(
				&"quarterly_report",
				report_index
			):
				result.add_error(
					"Quarterly Report %s does not equal allocated identifier quarterly_report.runtime.id_%06d."
					% [report.stable_id, report_index]
				)
			if report.month_step_index < 1 or report.month_step_index % 3 != 0:
				result.add_error(
					"Ending Quarterly Report %s Month Step index is invalid." % report.stable_id
				)
		if report.quarter_index < 1:
			result.add_error("Quarterly Report %s quarter index is invalid." % report.stable_id)
		if report.month_step_index < previous_month:
			result.add_error("Quarterly Reports are not in Month Step order.")
		previous_month = report.month_step_index
		_validate_entries(report, known_content_ids, result)
		_validate_world_snapshot(report, known_content_ids, result)
		_validate_previous_fields(report, previous_report, result)
		if (
			report.report_kind_id == QuarterlyReportState.KIND_ENDING
			and state.calendar != null
			and report.month_step_index == state.calendar.current_month_step_index
		):
			_validate_matches_current_state(report, state, result)
		previous_report = report


static func _validate_previous_fields(
		report: QuarterlyReportState,
		previous_report: QuarterlyReportState,
		result: GameStateValidationResult
	) -> void:
	if previous_report == null:
		if not _evaluations_equal(report.previous_technical_frontier, report.technical_frontier):
			result.add_error(
				"Quarterly Report %s previous technical frontier does not equal its current frontier."
				% report.stable_id
			)
		if (
			report.previous_customer_expectation_coding_evaluation_points
			!= report.customer_expectation_coding_evaluation_points
		):
			result.add_error(
				"Quarterly Report %s previous customer expectation does not equal its current value."
				% report.stable_id
			)
		if report.previous_public_trust_points != report.public_trust_points:
			result.add_error(
				"Quarterly Report %s previous Public Trust does not equal its current value."
				% report.stable_id
			)
		if report.previous_government_trust_points != report.government_trust_points:
			result.add_error(
				"Quarterly Report %s previous Government Trust does not equal its current value."
				% report.stable_id
			)
		return
	if not _evaluations_equal(report.previous_technical_frontier, previous_report.technical_frontier):
		result.add_error(
			"Quarterly Report %s previous technical frontier does not equal the prior report."
			% report.stable_id
		)
	if (
		report.previous_customer_expectation_coding_evaluation_points
		!= previous_report.customer_expectation_coding_evaluation_points
	):
		result.add_error(
			"Quarterly Report %s previous customer expectation does not equal the prior report."
			% report.stable_id
		)
	if report.previous_public_trust_points != previous_report.public_trust_points:
		result.add_error(
			"Quarterly Report %s previous Public Trust does not equal the prior report." % report.stable_id
		)
	if report.previous_government_trust_points != previous_report.government_trust_points:
		result.add_error(
			"Quarterly Report %s previous Government Trust does not equal the prior report."
			% report.stable_id
		)


static func _validate_entries(
		report: QuarterlyReportState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var seen_categories: Dictionary[StringName, bool] = {}
	for cash_change: QuarterlyReportCashChange in report.cash_changes:
		if cash_change == null:
			result.add_error("Quarterly Report %s contains a missing Cash change." % report.stable_id)
			continue
		if not cash_change.is_immutable():
			result.add_error(
				"Quarterly Report %s Cash change %s must be immutable."
				% [report.stable_id, cash_change.category_id]
			)
		GameStateValidator._validate_content_reference(
			cash_change.category_id,
			"Quarterly Report %s Cash category" % report.stable_id,
			known_content_ids,
			result
		)
		if seen_categories.has(cash_change.category_id):
			result.add_error(
				"Quarterly Report %s Cash category %s is duplicated."
				% [report.stable_id, cash_change.category_id]
			)
		seen_categories[cash_change.category_id] = true
	var seen_project_ids: Dictionary[StringName, bool] = {}
	for project_entry: QuarterlyReportProjectEntry in report.projects:
		if project_entry == null:
			result.add_error("Quarterly Report %s contains a missing Project entry." % report.stable_id)
			continue
		if not project_entry.is_immutable():
			result.add_error(
				"Quarterly Report %s Project entry %s must be immutable."
				% [report.stable_id, project_entry.project_id]
			)
		GameStateValidator._validate_identifier(
			project_entry.project_id,
			"Quarterly Report %s Project identifier" % report.stable_id,
			result
		)
		if seen_project_ids.has(project_entry.project_id):
			result.add_error(
				"Quarterly Report %s Project identifier %s is duplicated."
				% [report.stable_id, project_entry.project_id]
			)
		seen_project_ids[project_entry.project_id] = true
		GameStateValidator._validate_content_reference(
			project_entry.status_id,
			"Quarterly Report %s Project %s status" % [report.stable_id, project_entry.project_id],
			known_content_ids,
			result
		)
		GameStateValidator._validate_nonnegative(
			project_entry.remaining_month_steps,
			"Quarterly Report %s Project %s remaining Month Steps"
			% [report.stable_id, project_entry.project_id],
			result
		)
	var seen_model_ids: Dictionary[StringName, bool] = {}
	for model_entry: QuarterlyReportModelEntry in report.models:
		if model_entry == null:
			result.add_error("Quarterly Report %s contains a missing Model entry." % report.stable_id)
			continue
		if not model_entry.is_immutable():
			result.add_error(
				"Quarterly Report %s Model entry %s must be immutable."
				% [report.stable_id, model_entry.model_id]
			)
		GameStateValidator._validate_identifier(
			model_entry.model_id,
			"Quarterly Report %s Model identifier" % report.stable_id,
			result
		)
		if seen_model_ids.has(model_entry.model_id):
			result.add_error(
				"Quarterly Report %s Model identifier %s is duplicated."
				% [report.stable_id, model_entry.model_id]
			)
		seen_model_ids[model_entry.model_id] = true
		GameStateValidator._validate_evaluation(
			model_entry.coding_evaluation_points,
			"Quarterly Report %s Model %s coding evaluation" % [report.stable_id, model_entry.model_id],
			result
		)
		GameStateValidator._validate_evaluation(
			model_entry.reasoning_evaluation_points,
			"Quarterly Report %s Model %s reasoning evaluation"
			% [report.stable_id, model_entry.model_id],
			result
		)
		GameStateValidator._validate_evaluation(
			model_entry.efficiency_evaluation_points,
			"Quarterly Report %s Model %s efficiency evaluation"
			% [report.stable_id, model_entry.model_id],
			result
		)
	var seen_application_ids: Dictionary[StringName, bool] = {}
	for application_entry: QuarterlyReportApplicationEntry in report.applications:
		if application_entry == null:
			result.add_error("Quarterly Report %s contains a missing Application entry." % report.stable_id)
			continue
		if not application_entry.is_immutable():
			result.add_error(
				"Quarterly Report %s Application entry %s must be immutable."
				% [report.stable_id, application_entry.application_id]
			)
		GameStateValidator._validate_identifier(
			application_entry.application_id,
			"Quarterly Report %s Application identifier" % report.stable_id,
			result
		)
		if seen_application_ids.has(application_entry.application_id):
			result.add_error(
				"Quarterly Report %s Application identifier %s is duplicated."
				% [report.stable_id, application_entry.application_id]
			)
		seen_application_ids[application_entry.application_id] = true
		GameStateValidator._validate_identifier(
			application_entry.supporting_model_id,
			"Quarterly Report %s Application %s supporting Model"
			% [report.stable_id, application_entry.application_id],
			result
		)
		GameStateValidator._validate_nonnegative(
			application_entry.active_customer_contract_count,
			"Quarterly Report %s Application %s customer contract count"
			% [report.stable_id, application_entry.application_id],
			result
		)
		GameStateValidator._validate_nonnegative(
			application_entry.price_musd_per_contract_month,
			"Quarterly Report %s Application %s price"
			% [report.stable_id, application_entry.application_id],
			result
		)


static func _validate_world_snapshot(
		report: QuarterlyReportState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	for forecast: CompetitorForecast in report.competitor_forecasts:
		if forecast == null:
			result.add_error("Quarterly Report %s contains a missing Competitor forecast." % report.stable_id)
			continue
		GameStateValidator._validate_content_reference(
			forecast.competitor_id,
			"Quarterly Report %s Competitor forecast" % report.stable_id,
			known_content_ids,
			result
		)
		if forecast.known_release_quarter_index < 1:
			result.add_error(
				"Quarterly Report %s Competitor %s release quarter is invalid."
				% [report.stable_id, forecast.competitor_id]
			)
		GameStateValidator._validate_evaluation(
			forecast.projected_coding_evaluation_min,
			"Quarterly Report %s Competitor %s projected coding minimum"
			% [report.stable_id, forecast.competitor_id],
			result
		)
		GameStateValidator._validate_evaluation(
			forecast.projected_coding_evaluation_max,
			"Quarterly Report %s Competitor %s projected coding maximum"
			% [report.stable_id, forecast.competitor_id],
			result
		)
		GameStateValidator._validate_evaluation(
			forecast.projected_reasoning_evaluation_min,
			"Quarterly Report %s Competitor %s projected reasoning minimum"
			% [report.stable_id, forecast.competitor_id],
			result
		)
		GameStateValidator._validate_evaluation(
			forecast.projected_reasoning_evaluation_max,
			"Quarterly Report %s Competitor %s projected reasoning maximum"
			% [report.stable_id, forecast.competitor_id],
			result
		)
		GameStateValidator._validate_evaluation(
			forecast.projected_efficiency_evaluation_min,
			"Quarterly Report %s Competitor %s projected efficiency minimum"
			% [report.stable_id, forecast.competitor_id],
			result
		)
		GameStateValidator._validate_evaluation(
			forecast.projected_efficiency_evaluation_max,
			"Quarterly Report %s Competitor %s projected efficiency maximum"
			% [report.stable_id, forecast.competitor_id],
			result
		)
		if forecast.projected_coding_evaluation_min > forecast.projected_coding_evaluation_max:
			result.add_error(
				"Quarterly Report %s Competitor %s projected coding range is invalid."
				% [report.stable_id, forecast.competitor_id]
			)
		if forecast.projected_reasoning_evaluation_min > forecast.projected_reasoning_evaluation_max:
			result.add_error(
				"Quarterly Report %s Competitor %s projected reasoning range is invalid."
				% [report.stable_id, forecast.competitor_id]
			)
		if forecast.projected_efficiency_evaluation_min > forecast.projected_efficiency_evaluation_max:
			result.add_error(
				"Quarterly Report %s Competitor %s projected efficiency range is invalid."
				% [report.stable_id, forecast.competitor_id]
			)
	if report.competitor_stage_id != &"":
		GameStateValidator._validate_content_reference(
			report.competitor_stage_id,
			"Quarterly Report %s Competitor Stage" % report.stable_id,
			known_content_ids,
			result
		)
	if report.released_competitor_model_id != &"":
		GameStateValidator._validate_identifier(
			report.released_competitor_model_id,
			"Quarterly Report %s released Competitor Model" % report.stable_id,
			result
		)
	if report.released_competitor_evaluations != null:
		GameStateValidator._validate_model_evaluations(
			report.released_competitor_evaluations,
			"Quarterly Report %s released Competitor evaluations" % report.stable_id,
			result
		)
	GameStateValidator._validate_model_evaluations(
		report.technical_frontier,
		"Quarterly Report %s technical frontier" % report.stable_id,
		result
	)
	GameStateValidator._validate_model_evaluations(
		report.previous_technical_frontier,
		"Quarterly Report %s previous technical frontier" % report.stable_id,
		result
	)
	GameStateValidator._validate_evaluation(
		report.customer_expectation_coding_evaluation_points,
		"Quarterly Report %s customer expectation" % report.stable_id,
		result
	)
	GameStateValidator._validate_evaluation(
		report.previous_customer_expectation_coding_evaluation_points,
		"Quarterly Report %s previous customer expectation" % report.stable_id,
		result
	)
	GameStateValidator._validate_evaluation(
		report.public_trust_points,
		"Quarterly Report %s Public Trust" % report.stable_id,
		result
	)
	GameStateValidator._validate_evaluation(
		report.previous_public_trust_points,
		"Quarterly Report %s previous Public Trust" % report.stable_id,
		result
	)
	GameStateValidator._validate_evaluation(
		report.government_trust_points,
		"Quarterly Report %s Government Trust" % report.stable_id,
		result
	)
	GameStateValidator._validate_evaluation(
		report.previous_government_trust_points,
		"Quarterly Report %s previous Government Trust" % report.stable_id,
		result
	)


static func _validate_matches_current_state(
		report: QuarterlyReportState,
		state: GameState,
		result: GameStateValidationResult
	) -> void:
	if state.cash_ledger == null:
		result.add_error("The Cash Ledger is missing during Quarterly Report validation.")
		return
	if report.cash_balance_musd != state.cash_ledger.calculate_balance_musd():
		result.add_error(
			"Quarterly Report %s Cash balance does not equal the Cash Ledger." % report.stable_id
		)
	if report.report_kind_id == QuarterlyReportState.KIND_ENDING:
		var expected_changes: Dictionary[StringName, int] = _quarter_cash_totals(state)
		if report.cash_changes.size() != expected_changes.size():
			result.add_error(
				"Quarterly Report %s Cash changes do not equal the quarter ledger totals."
				% report.stable_id
			)
		else:
			for cash_change: QuarterlyReportCashChange in report.cash_changes:
				if cash_change == null:
					continue
				if (
					not expected_changes.has(cash_change.category_id)
					or expected_changes[cash_change.category_id] != cash_change.amount_musd
				):
					result.add_error(
						"Quarterly Report %s Cash category %s does not equal the quarter ledger total."
						% [report.stable_id, cash_change.category_id]
					)
	if state.company == null:
		result.add_error("Company State is missing during Quarterly Report validation.")
		return
	_validate_projects_match(report, state.company.projects, result)
	_validate_models_match(report, state.company.models, result)
	_validate_applications_match(report, state.company.applications, result)
	if (
		report.public_trust_points != state.company.public_trust_points
		or report.government_trust_points != state.company.government_trust_points
	):
		result.add_error("Quarterly Report %s trust values do not equal Company State." % report.stable_id)
	if state.world == null:
		result.add_error("World State is missing during Quarterly Report validation.")
		return
	if not _evaluations_equal(report.technical_frontier, state.world.technical_frontier):
		result.add_error(
			"Quarterly Report %s technical frontier does not equal World State." % report.stable_id
		)
	if state.world.competitors.size() == 1:
		var competitor_ids: Array[StringName] = []
		competitor_ids.assign(state.world.competitors.keys())
		var competitor: CompetitorState = state.world.competitors[competitor_ids[0]]
		if competitor != null and report.competitor_stage_id != competitor.stage_id:
			result.add_error(
				"Quarterly Report %s Competitor Stage does not equal World State." % report.stable_id
			)
	if state.world.models.is_empty():
		if report.released_competitor_model_id != &"" or report.released_competitor_evaluations != null:
			result.add_error(
				"Quarterly Report %s contains a released Competitor Model that World State does not have."
				% report.stable_id
			)
	elif state.world.models.has(report.released_competitor_model_id):
		var released_model: ModelState = state.world.models[report.released_competitor_model_id]
		if (
			released_model != null
			and not _evaluations_equal(report.released_competitor_evaluations, released_model.evaluations)
		):
			result.add_error(
				"Quarterly Report %s released Competitor evaluations do not equal World State."
				% report.stable_id
			)
	if (
		state.world.markets.has(&"market.coding_agent")
		and state.world.markets[&"market.coding_agent"] != null
		and (
			report.customer_expectation_coding_evaluation_points
			!= state.world.markets[&"market.coding_agent"].customer_expectation_coding_evaluation_points
		)
	):
		result.add_error(
			"Quarterly Report %s customer expectation does not equal World State." % report.stable_id
		)


static func _validate_projects_match(
		report: QuarterlyReportState,
		projects: Dictionary[StringName, ProjectState],
		result: GameStateValidationResult
	) -> void:
	if report.projects.size() != projects.size():
		result.add_error(
			"Quarterly Report %s Project entries do not equal Company Projects." % report.stable_id
		)
		return
	for project_entry: QuarterlyReportProjectEntry in report.projects:
		if project_entry == null:
			continue
		if not projects.has(project_entry.project_id):
			result.add_error(
				"Quarterly Report %s Project %s does not exist in Company State."
				% [report.stable_id, project_entry.project_id]
			)
			continue
		var project: ProjectState = projects[project_entry.project_id]
		if project == null:
			continue
		if (
			project_entry.status_id != project.status_id
			or project_entry.remaining_month_steps != project.remaining_month_steps
		):
			result.add_error(
				"Quarterly Report %s Project %s does not equal Company State."
				% [report.stable_id, project_entry.project_id]
			)


static func _validate_models_match(
		report: QuarterlyReportState,
		models: Dictionary[StringName, ModelState],
		result: GameStateValidationResult
	) -> void:
	if report.models.size() != models.size():
		result.add_error(
			"Quarterly Report %s Model entries do not equal Company Models." % report.stable_id
		)
		return
	for model_entry: QuarterlyReportModelEntry in report.models:
		if model_entry == null:
			continue
		if not models.has(model_entry.model_id):
			result.add_error(
				"Quarterly Report %s Model %s does not exist in Company State."
				% [report.stable_id, model_entry.model_id]
			)
			continue
		var model: ModelState = models[model_entry.model_id]
		if model == null or model.evaluations == null:
			continue
		if (
			model_entry.coding_evaluation_points != model.evaluations.coding_evaluation_points
			or model_entry.reasoning_evaluation_points != model.evaluations.reasoning_evaluation_points
			or model_entry.efficiency_evaluation_points != model.evaluations.efficiency_evaluation_points
		):
			result.add_error(
				"Quarterly Report %s Model %s does not equal Company State."
				% [report.stable_id, model_entry.model_id]
			)


static func _validate_applications_match(
		report: QuarterlyReportState,
		applications: Dictionary[StringName, ApplicationState],
		result: GameStateValidationResult
	) -> void:
	if report.applications.size() != applications.size():
		result.add_error(
			"Quarterly Report %s Application entries do not equal Company Applications." % report.stable_id
		)
		return
	for application_entry: QuarterlyReportApplicationEntry in report.applications:
		if application_entry == null:
			continue
		if not applications.has(application_entry.application_id):
			result.add_error(
				"Quarterly Report %s Application %s does not exist in Company State."
				% [report.stable_id, application_entry.application_id]
			)
			continue
		var application: ApplicationState = applications[application_entry.application_id]
		if application == null:
			continue
		if (
			application_entry.supporting_model_id != application.supporting_model_id
			or application_entry.active_customer_contract_count != application.active_customer_contract_count
			or application_entry.price_musd_per_contract_month != application.price_musd_per_contract_month
		):
			result.add_error(
				"Quarterly Report %s Application %s does not equal Company State."
				% [report.stable_id, application_entry.application_id]
			)


static func _quarter_cash_totals(state: GameState) -> Dictionary[StringName, int]:
	var totals: Dictionary[StringName, int] = {}
	if state.calendar == null or state.cash_ledger == null:
		return totals
	var first_month: int = (state.calendar.current_quarter_index - 1) * 3 + 1
	var last_month: int = state.calendar.current_quarter_index * 3
	for transaction: LedgerTransactionState in state.cash_ledger.transactions:
		if transaction == null:
			continue
		if transaction.month_step_index < first_month or transaction.month_step_index > last_month:
			continue
		if totals.has(transaction.category_id):
			totals[transaction.category_id] = totals[transaction.category_id] + transaction.amount_musd
		else:
			totals[transaction.category_id] = transaction.amount_musd
	return totals


static func _evaluations_equal(left: ModelEvaluationState, right: ModelEvaluationState) -> bool:
	if left == null and right == null:
		return true
	if left == null or right == null:
		return false
	return (
		left.coding_evaluation_points == right.coding_evaluation_points
		and left.reasoning_evaluation_points == right.reasoning_evaluation_points
		and left.efficiency_evaluation_points == right.efficiency_evaluation_points
	)
