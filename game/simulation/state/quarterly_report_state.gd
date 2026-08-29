class_name QuarterlyReportState
extends Resource

const KIND_OPENING: StringName = &"quarterly_report.opening"
const KIND_ENDING: StringName = &"quarterly_report.ending"

@export var stable_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its stable identifier.")
			return
		stable_id = value
@export var report_kind_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its kind identifier.")
			return
		report_kind_id = value
@export var quarter_index: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its quarter index.")
			return
		quarter_index = value
@export var month_step_index: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Month Step index.")
			return
		month_step_index = value
@export var cash_balance_musd: int = 0:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Cash balance.")
			return
		cash_balance_musd = value
@export var cash_changes: Array[QuarterlyReportCashChange] = []:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Cash changes.")
			return
		cash_changes = value
@export var projects: Array[QuarterlyReportProjectEntry] = []:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Project entries.")
			return
		projects = value
@export var models: Array[QuarterlyReportModelEntry] = []:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Model entries.")
			return
		models = value
@export var applications: Array[QuarterlyReportApplicationEntry] = []:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Application entries.")
			return
		applications = value
@export var competitor_forecasts: Array[CompetitorForecast] = []:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Competitor forecasts.")
			return
		competitor_forecasts = value
@export var competitor_stage_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its Competitor Stage.")
			return
		competitor_stage_id = value
@export var released_competitor_model_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its released Competitor Model.")
			return
		released_competitor_model_id = value
@export var released_competitor_evaluations: ModelEvaluationState:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its released Competitor evaluations.")
			return
		released_competitor_evaluations = value
@export var technical_frontier: ModelEvaluationState:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its technical frontier.")
			return
		technical_frontier = value
@export var previous_technical_frontier: ModelEvaluationState:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its previous technical frontier.")
			return
		previous_technical_frontier = value
@export var customer_expectation_coding_evaluation_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its customer expectation.")
			return
		customer_expectation_coding_evaluation_points = value
@export var previous_customer_expectation_coding_evaluation_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change its previous customer expectation.")
			return
		previous_customer_expectation_coding_evaluation_points = value
@export var public_trust_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change Public Trust.")
			return
		public_trust_points = value
@export var previous_public_trust_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change previous Public Trust.")
			return
		previous_public_trust_points = value
@export var government_trust_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change Government Trust.")
			return
		government_trust_points = value
@export var previous_government_trust_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cannot change previous Government Trust.")
			return
		previous_government_trust_points = value

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func is_immutable() -> bool:
	return _is_immutable


func immutable_copy() -> QuarterlyReportState:
	var copied_report: QuarterlyReportState = QuarterlyReportState.new()
	copied_report.stable_id = stable_id
	copied_report.report_kind_id = report_kind_id
	copied_report.quarter_index = quarter_index
	copied_report.month_step_index = month_step_index
	copied_report.cash_balance_musd = cash_balance_musd
	var copied_cash_changes: Array[QuarterlyReportCashChange] = []
	for cash_change: QuarterlyReportCashChange in cash_changes:
		if cash_change == null:
			copied_cash_changes.append(null)
			continue
		copied_cash_changes.append(cash_change.immutable_copy())
	copied_report.cash_changes = copied_cash_changes
	var copied_projects: Array[QuarterlyReportProjectEntry] = []
	for project_entry: QuarterlyReportProjectEntry in projects:
		if project_entry == null:
			copied_projects.append(null)
			continue
		copied_projects.append(project_entry.immutable_copy())
	copied_report.projects = copied_projects
	var copied_models: Array[QuarterlyReportModelEntry] = []
	for model_entry: QuarterlyReportModelEntry in models:
		if model_entry == null:
			copied_models.append(null)
			continue
		copied_models.append(model_entry.immutable_copy())
	copied_report.models = copied_models
	var copied_applications: Array[QuarterlyReportApplicationEntry] = []
	for application_entry: QuarterlyReportApplicationEntry in applications:
		if application_entry == null:
			copied_applications.append(null)
			continue
		copied_applications.append(application_entry.immutable_copy())
	copied_report.applications = copied_applications
	var copied_forecasts: Array[CompetitorForecast] = []
	for forecast: CompetitorForecast in competitor_forecasts:
		copied_forecasts.append(_copy_forecast(forecast))
	copied_report.competitor_forecasts = copied_forecasts
	copied_report.competitor_stage_id = competitor_stage_id
	copied_report.released_competitor_model_id = released_competitor_model_id
	copied_report.released_competitor_evaluations = _copy_evaluations(released_competitor_evaluations)
	copied_report.technical_frontier = _copy_evaluations(technical_frontier)
	copied_report.previous_technical_frontier = _copy_evaluations(previous_technical_frontier)
	copied_report.customer_expectation_coding_evaluation_points = (
		customer_expectation_coding_evaluation_points
	)
	copied_report.previous_customer_expectation_coding_evaluation_points = (
		previous_customer_expectation_coding_evaluation_points
	)
	copied_report.public_trust_points = public_trust_points
	copied_report.previous_public_trust_points = previous_public_trust_points
	copied_report.government_trust_points = government_trust_points
	copied_report.previous_government_trust_points = previous_government_trust_points
	copied_report._is_immutable = true
	return copied_report


static func _copy_evaluations(source: ModelEvaluationState) -> ModelEvaluationState:
	if source == null:
		return null
	var copied_evaluations: ModelEvaluationState = ModelEvaluationState.new()
	copied_evaluations.coding_evaluation_points = source.coding_evaluation_points
	copied_evaluations.reasoning_evaluation_points = source.reasoning_evaluation_points
	copied_evaluations.efficiency_evaluation_points = source.efficiency_evaluation_points
	return copied_evaluations


static func _copy_forecast(source: CompetitorForecast) -> CompetitorForecast:
	if source == null:
		return null
	var copied_forecast: CompetitorForecast = CompetitorForecast.new()
	copied_forecast.competitor_id = source.competitor_id
	copied_forecast.known_release_quarter_index = source.known_release_quarter_index
	copied_forecast.projected_coding_evaluation_min = source.projected_coding_evaluation_min
	copied_forecast.projected_coding_evaluation_max = source.projected_coding_evaluation_max
	copied_forecast.projected_reasoning_evaluation_min = source.projected_reasoning_evaluation_min
	copied_forecast.projected_reasoning_evaluation_max = source.projected_reasoning_evaluation_max
	copied_forecast.projected_efficiency_evaluation_min = source.projected_efficiency_evaluation_min
	copied_forecast.projected_efficiency_evaluation_max = source.projected_efficiency_evaluation_max
	return copied_forecast
