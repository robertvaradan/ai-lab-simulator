class_name AcknowledgmentAttentionEventResponseValidator
extends AttentionEventResponseValidator

const ACKNOWLEDGMENT_RESPONSE_TYPE_ID: StringName = &"attention_response.acknowledgment"


func _init(p_event_type_id: StringName) -> void:
	super(p_event_type_id, ACKNOWLEDGMENT_RESPONSE_TYPE_ID)


func validate_response(
		event: AttentionEventState,
		response: AttentionEventResponse
	) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	if event.event_type_id != event_type_id:
		diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"attention_response.event_type_mismatch",
				"Attention Event %s has type %s, but validator %s owns type %s."
				% [event.stable_id, event.event_type_id, event_type_id, event_type_id]
			)
		)
		return diagnostics
	if response.response_type_id != response_type_id:
		diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"plan.attention_event_response_type_mismatch",
				"Attention Event %s requires response type %s."
				% [event.stable_id, response_type_id]
			)
		)
	if not response.payload.is_empty():
		diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"plan.attention_event_acknowledgment_payload_not_empty",
				"The acknowledgment response for Attention Event %s must have an empty payload."
				% event.stable_id
			)
		)
	return diagnostics
