class_name RuleGraphArtifactResult
extends RefCounted

var artifact: RuleGraphArtifact
var diagnostics: Array[SimulationDiagnostic] = []


func succeeded() -> bool:
	return artifact != null and diagnostics.is_empty()


func format_diagnostics() -> String:
	var messages: Array[String] = []
	for diagnostic: SimulationDiagnostic in diagnostics:
		messages.append("%s: %s" % [diagnostic.code, diagnostic.message])
	return "\n".join(messages)
