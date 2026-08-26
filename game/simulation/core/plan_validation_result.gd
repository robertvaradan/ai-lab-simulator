class_name PlanValidationResult
extends RefCounted

var diagnostics: Array[SimulationDiagnostic]:
	get:
		var copied_diagnostics: Array[SimulationDiagnostic] = []
		copied_diagnostics.assign(_diagnostics)
		return copied_diagnostics

var _diagnostics: Array[SimulationDiagnostic] = []
var _has_contract_fault: bool = false


func is_valid() -> bool:
	return _diagnostics.is_empty()


func has_contract_fault() -> bool:
	return _has_contract_fault


func format_diagnostics() -> String:
	var messages: Array[String] = []
	for diagnostic: SimulationDiagnostic in _diagnostics:
		messages.append("%s: %s" % [diagnostic.code, diagnostic.message])
	return "\n".join(messages)


func _add_rejection(code: StringName, message: String) -> void:
	_diagnostics.append(
		SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, message)
	)


func _add_rejection_diagnostic(diagnostic: SimulationDiagnostic) -> void:
	_diagnostics.append(diagnostic)


func _add_fault(code: StringName, message: String) -> void:
	_has_contract_fault = true
	_diagnostics.append(
		SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, message)
	)
