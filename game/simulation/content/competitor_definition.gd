class_name CompetitorDefinition
extends Resource

const RELEASE_EVENT_ID: StringName = &"event.competitor.northstar_flagship_release"
const RELEASED_MODEL_ID: StringName = &"model.competitor.northstar.flagship"
const CODING_AGENT_MARKET_ID: StringName = &"market.coding_agent"

@export var stable_id: StringName = &""
@export var specification_reference: String = ""
@export var schema_version: int = -1
@export var announced_stage_id: StringName = &""
@export var released_stage_id: StringName = &""
@export var release_month_step_index: int = -1
@export var known_release_quarter_index: int = -1
@export var projected_coding_evaluation_min: int = -1
@export var projected_coding_evaluation_max: int = -1
@export var projected_reasoning_evaluation_min: int = -1
@export var projected_reasoning_evaluation_max: int = -1
@export var projected_efficiency_evaluation_min: int = -1
@export var projected_efficiency_evaluation_max: int = -1
@export var actual_coding_evaluation_points: int = -1
@export var actual_reasoning_evaluation_points: int = -1
@export var actual_efficiency_evaluation_points: int = -1
@export var released_model_id: StringName = &""
@export var released_model_display_name: String = ""
@export var released_model_version_label: String = ""
@export var released_model_release_strategy_id: StringName = &""
@export var released_model_training_compute_unit_months: int = -1
@export var released_model_inference_compute_unit_months_per_contract: int = -1
@export var customer_expectation_market_id: StringName = &""
@export var released_customer_expectation_coding_evaluation_points: int = -1
@export var release_event_id: StringName = &""


func _init() -> void:
	pass


func create_forecast() -> CompetitorForecast:
	var forecast: CompetitorForecast = CompetitorForecast.new()
	forecast.competitor_id = stable_id
	forecast.known_release_quarter_index = known_release_quarter_index
	forecast.projected_coding_evaluation_min = projected_coding_evaluation_min
	forecast.projected_coding_evaluation_max = projected_coding_evaluation_max
	forecast.projected_reasoning_evaluation_min = projected_reasoning_evaluation_min
	forecast.projected_reasoning_evaluation_max = projected_reasoning_evaluation_max
	forecast.projected_efficiency_evaluation_min = projected_efficiency_evaluation_min
	forecast.projected_efficiency_evaluation_max = projected_efficiency_evaluation_max
	return forecast
