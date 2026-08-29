class_name QuarterlyReportModelEntry
extends Resource

@export var model_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Model entry cannot change its Model identifier.")
			return
		model_id = value
@export var coding_evaluation_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Model entry cannot change its coding evaluation.")
			return
		coding_evaluation_points = value
@export var reasoning_evaluation_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Model entry cannot change its reasoning evaluation.")
			return
		reasoning_evaluation_points = value
@export var efficiency_evaluation_points: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable Quarterly Report Model entry cannot change its efficiency evaluation.")
			return
		efficiency_evaluation_points = value

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func is_immutable() -> bool:
	return _is_immutable


func immutable_copy() -> QuarterlyReportModelEntry:
	var copied_entry: QuarterlyReportModelEntry = QuarterlyReportModelEntry.new()
	copied_entry.model_id = model_id
	copied_entry.coding_evaluation_points = coding_evaluation_points
	copied_entry.reasoning_evaluation_points = reasoning_evaluation_points
	copied_entry.efficiency_evaluation_points = efficiency_evaluation_points
	copied_entry._is_immutable = true
	return copied_entry
