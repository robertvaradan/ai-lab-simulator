class_name ModelState
extends Resource

@export var stable_id: StringName = &""
@export var display_name: String = ""
@export var version_label: String = ""
@export var release_state_id: StringName = &""
@export var release_strategy_id: StringName = &""
@export var evaluations: ModelEvaluationState
@export var training_compute_unit_months: int = -1
@export var inference_compute_unit_months_per_contract: int = -1


func _init() -> void:
	pass
