class_name ProjectState
extends Resource

const STATUS_ACTIVE: StringName = &"project_status.active"
const STATUS_COMPLETED: StringName = &"project_status.completed"

@export var stable_id: StringName = &""
@export var content_definition_id: StringName = &""
@export var status_id: StringName = &""
@export var remaining_month_steps: int = 0
@export var reserved_project_teams: int = 0
@export var reserved_compute_unit_months: int = 0
@export var started_month_step_index: int = 0
@export var completed_month_step_index: int = 0
@export var start_payload: Dictionary[StringName, Variant] = {}


func _init() -> void:
	pass


func is_active() -> bool:
	return status_id == STATUS_ACTIVE
