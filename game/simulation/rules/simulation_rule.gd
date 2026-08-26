class_name SimulationRule
extends RefCounted

var stable_id: StringName:
	get:
		return _stable_id
	set(value):
		if _reject_metadata_change("stable identifier"):
			return
		_stable_id = value
var display_name: String:
	get:
		return _display_name
	set(value):
		if _reject_metadata_change("display name"):
			return
		_display_name = value
var phase_id: StringName:
	get:
		return _phase_id
	set(value):
		if _reject_metadata_change("phase identifier"):
			return
		_phase_id = value
var execution_order: int:
	get:
		return _execution_order
	set(value):
		if _reject_metadata_change("execution order"):
			return
		_execution_order = value
var order_after_rule_ids: Array[StringName]:
	get:
		return _copy_string_names(_order_after_rule_ids)
	set(value):
		if _reject_metadata_change("order dependencies"):
			return
		_order_after_rule_ids.assign(value)
var read_state_paths: Array[StringName]:
	get:
		return _copy_string_names(_read_state_paths)
	set(value):
		if _reject_metadata_change("read state paths"):
			return
		_read_state_paths.assign(value)
var write_state_paths: Array[StringName]:
	get:
		return _copy_string_names(_write_state_paths)
	set(value):
		if _reject_metadata_change("write state paths"):
			return
		_write_state_paths.assign(value)
var consumed_event_ids: Array[StringName]:
	get:
		return _copy_string_names(_consumed_event_ids)
	set(value):
		if _reject_metadata_change("consumed events"):
			return
		_consumed_event_ids.assign(value)
var emitted_event_ids: Array[StringName]:
	get:
		return _copy_string_names(_emitted_event_ids)
	set(value):
		if _reject_metadata_change("emitted events"):
			return
		_emitted_event_ids.assign(value)
var condition_ids: Array[StringName]:
	get:
		return _copy_string_names(_condition_ids)
	set(value):
		if _reject_metadata_change("conditions"):
			return
		_condition_ids.assign(value)
var graph_group_id: StringName:
	get:
		return _graph_group_id
	set(value):
		if _reject_metadata_change("graph group"):
			return
		_graph_group_id = value
var specification_references: Array[String]:
	get:
		var references: Array[String] = []
		references.assign(_specification_references)
		return references
	set(value):
		if _reject_metadata_change("specification references"):
			return
		_specification_references.assign(value)

var _stable_id: StringName = &""
var _display_name: String = ""
var _phase_id: StringName = &""
var _execution_order: int = -1
var _order_after_rule_ids: Array[StringName] = []
var _read_state_paths: Array[StringName] = []
var _write_state_paths: Array[StringName] = []
var _consumed_event_ids: Array[StringName] = []
var _emitted_event_ids: Array[StringName] = []
var _condition_ids: Array[StringName] = []
var _graph_group_id: StringName = &""
var _specification_references: Array[String] = []
var _metadata_is_sealed: bool = false


func evaluate(_context: SimulationContext) -> SimulationRuleEvaluation:
	return SimulationRuleEvaluation.failed(
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.evaluator_missing",
			"Rule %s does not implement an evaluator." % stable_id,
			stable_id
		)
	)


func is_metadata_sealed() -> bool:
	return _metadata_is_sealed


func _seal_metadata() -> void:
	_metadata_is_sealed = true


func _reject_metadata_change(field_name: String) -> bool:
	if not _metadata_is_sealed:
		return false
	push_error("Sealed Rule %s cannot change its %s." % [_stable_id, field_name])
	return true


func _copy_string_names(source: Array[StringName]) -> Array[StringName]:
	var copied_values: Array[StringName] = []
	copied_values.assign(source)
	return copied_values
