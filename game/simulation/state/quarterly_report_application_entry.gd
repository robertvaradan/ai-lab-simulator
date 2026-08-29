class_name QuarterlyReportApplicationEntry
extends Resource

@export var application_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Application entry cannot change its Application identifier.")
			return
		application_id = value
@export var supporting_model_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Application entry cannot change its supporting Model.")
			return
		supporting_model_id = value
@export var active_customer_contract_count: int = 0:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Application entry cannot change its contract count.")
			return
		active_customer_contract_count = value
@export var price_musd_per_contract_month: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Application entry cannot change its price.")
			return
		price_musd_per_contract_month = value

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func is_immutable() -> bool:
	return _is_immutable


func immutable_copy() -> QuarterlyReportApplicationEntry:
	var copied_entry: QuarterlyReportApplicationEntry = QuarterlyReportApplicationEntry.new()
	copied_entry.application_id = application_id
	copied_entry.supporting_model_id = supporting_model_id
	copied_entry.active_customer_contract_count = active_customer_contract_count
	copied_entry.price_musd_per_contract_month = price_musd_per_contract_month
	copied_entry._is_immutable = true
	return copied_entry
