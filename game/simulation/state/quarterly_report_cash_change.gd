class_name QuarterlyReportCashChange
extends Resource

@export var category_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cash change cannot change its category identifier.")
			return
		category_id = value
@export var amount_musd: int = 0:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report cash change cannot change its amount.")
			return
		amount_musd = value

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func is_immutable() -> bool:
	return _is_immutable


func immutable_copy() -> QuarterlyReportCashChange:
	var copied_change: QuarterlyReportCashChange = QuarterlyReportCashChange.new()
	copied_change.category_id = category_id
	copied_change.amount_musd = amount_musd
	copied_change._is_immutable = true
	return copied_change
