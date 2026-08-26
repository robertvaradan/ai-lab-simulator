class_name SimulationDiagnostic
extends RefCounted

enum Severity {
	ERROR,
	WARNING,
}

var severity: Severity
var code: StringName
var message: String
var rule_id: StringName
var state_path: StringName


func _init(
		p_severity: Severity,
		p_code: StringName,
		p_message: String,
		p_rule_id: StringName = &"",
		p_state_path: StringName = &""
	) -> void:
	severity = p_severity
	code = p_code
	message = p_message
	rule_id = p_rule_id
	state_path = p_state_path


func to_dictionary() -> Dictionary[StringName, Variant]:
	return {
		&"severity": severity,
		&"code": code,
		&"message": message,
		&"rule_id": rule_id,
		&"state_path": state_path,
	}
