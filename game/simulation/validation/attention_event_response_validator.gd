class_name AttentionEventResponseValidator
extends RefCounted

var event_type_id: StringName:
	get:
		return _event_type_id
var response_type_id: StringName:
	get:
		return _response_type_id

var _event_type_id: StringName
var _response_type_id: StringName


func _init(p_event_type_id: StringName, p_response_type_id: StringName) -> void:
	_event_type_id = p_event_type_id
	_response_type_id = p_response_type_id


func validate_response(
		event: AttentionEventState,
		response: AttentionEventResponse
	) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	diagnostics.append(
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"attention_response.validator_not_implemented",
			"Attention Event type %s does not implement response validation." % _event_type_id
		)
	)
	return diagnostics
