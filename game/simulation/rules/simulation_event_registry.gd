class_name SimulationEventRegistry
extends RefCounted

var _event_ids: Dictionary[StringName, bool] = {}
var _diagnostics: Array[SimulationDiagnostic] = []
var _is_sealed: bool = false


func register_event(event_id: StringName) -> bool:
	if _is_sealed:
		_add_error(&"event_registry.sealed", "The event registry is sealed.")
		return false
	if not StableIdentifier.is_valid(event_id):
		_add_error(&"event_registry.invalid_event_id", "Event identifier %s is invalid." % event_id)
		return false
	if _event_ids.has(event_id):
		_add_error(&"event_registry.duplicate_event_id", "Event identifier %s is duplicated." % event_id)
		return false
	_event_ids[event_id] = true
	return true


func seal() -> void:
	_is_sealed = true


func is_sealed() -> bool:
	return _is_sealed


func has_event(event_id: StringName) -> bool:
	return _event_ids.has(event_id)


func get_event_ids() -> Array[StringName]:
	var identifiers: Array[StringName] = []
	identifiers.assign(_event_ids.keys())
	identifiers.sort()
	return identifiers


func get_diagnostics() -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	diagnostics.assign(_diagnostics)
	return diagnostics


func _add_error(code: StringName, message: String) -> void:
	_diagnostics.append(
		SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, message)
	)
