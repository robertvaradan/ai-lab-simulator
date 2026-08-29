class_name ApplicationState
extends Resource

const STATUS_ACTIVE: StringName = &"application_status.active"

@export var stable_id: StringName = &""
@export var content_definition_id: StringName = &""
@export var status_id: StringName = &""
@export var supporting_model_id: StringName = &""
@export var price_musd_per_contract_month: int = -1
@export var active_customer_contract_count: int = 0


func _init() -> void:
	pass
