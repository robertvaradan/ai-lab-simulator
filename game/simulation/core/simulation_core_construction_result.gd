class_name SimulationCoreConstructionResult
extends RefCounted

var core: SimulationCore
var diagnostics: Array[SimulationDiagnostic] = []


func succeeded() -> bool:
	return core != null and diagnostics.is_empty()


func format_diagnostics() -> String:
	var messages: Array[String] = []
	for diagnostic: SimulationDiagnostic in diagnostics:
		messages.append("%s: %s" % [diagnostic.code, diagnostic.message])
	return "\n".join(messages)
