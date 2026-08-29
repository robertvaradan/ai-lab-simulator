class_name QuarterlyReportProjectEntry
extends Resource

@export var project_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Project entry cannot change its Project identifier.")
			return
		project_id = value
@export var status_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Project entry cannot change its status identifier.")
			return
		status_id = value
@export var remaining_month_steps: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Project entry cannot change remaining Month Steps.")
			return
		remaining_month_steps = value

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func is_immutable() -> bool:
	return _is_immutable


func immutable_copy() -> QuarterlyReportProjectEntry:
	var copied_entry: QuarterlyReportProjectEntry = QuarterlyReportProjectEntry.new()
	copied_entry.project_id = project_id
	copied_entry.status_id = status_id
	copied_entry.remaining_month_steps = remaining_month_steps
	copied_entry._is_immutable = true
	return copied_entry
