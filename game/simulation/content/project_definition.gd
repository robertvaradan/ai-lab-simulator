class_name ProjectDefinition
extends Resource

const EFFECT_RESEARCH_MODEL: StringName = &"project_completion.research_model"
const EFFECT_BURST_COMPUTE: StringName = &"project_completion.burst_compute"
const EFFECT_CODING_AGENT: StringName = &"project_completion.coding_agent"
const PAYLOAD_PROJECT_ID: StringName = &"project_id"
const PAYLOAD_MODEL_DISPLAY_NAME: StringName = &"model_display_name"
const PAYLOAD_MODEL_VERSION_LABEL: StringName = &"model_version_label"
const PAYLOAD_RELEASE_STRATEGY_ID: StringName = &"release_strategy_id"
const PAYLOAD_SUPPORTING_MODEL_ID: StringName = &"supporting_model_id"

@export var stable_id: StringName = &""
@export var specification_reference: String = ""
@export var schema_version: int = -1
@export var start_cost_musd: int = -1
@export var duration_month_steps: int = -1
@export var reserved_project_teams: int = -1
@export var reserved_compute_unit_months: int = -1
@export var prerequisite_project_ids: Array[StringName] = []
@export var required_payload_keys: Array[StringName] = []
@export var completion_effect_id: StringName = &""
@export var completed_model_id: StringName = &""
@export var completed_model_coding_evaluation_points: int = -1
@export var completed_model_reasoning_evaluation_points: int = -1
@export var completed_model_efficiency_evaluation_points: int = -1
@export var completed_model_inference_compute_unit_months_per_contract: int = -1
@export var completed_contract_id: StringName = &""
@export var completed_contract_compute_unit_months: int = -1
@export var completed_application_id: StringName = &""
@export var completed_application_price_musd_per_contract_month: int = -1


func _init() -> void:
	pass
