class_name PlanValidator
extends RefCounted


static func validate(
		state: GameState,
		plan: Plan,
		content_registry: SimulationContentRegistry
	) -> PlanValidationResult:
	var result: PlanValidationResult = PlanValidationResult.new()
	if plan == null:
		result._add_rejection(&"plan.missing", "The Plan is missing.")
		return result
	if state.pending_command_batch != null:
		result._add_rejection(
			&"plan.pending_command_batch_exists",
			"A Plan cannot commit while a Pending Command Batch exists."
		)

	_validate_commands(state, plan.commands, content_registry, result)
	_validate_attention_event_responses(
		state.attention_events,
		plan.attention_event_responses,
		content_registry,
		result
	)
	return result


static func _validate_commands(
		state: GameState,
		commands: Array[Command],
		content_registry: SimulationContentRegistry,
		result: PlanValidationResult
	) -> void:
	var seen_command_ids: Dictionary[StringName, bool] = {}
	var next_command_sequence: int = state.runtime_id_counters.next_sequence_by_entity_type[&"command"]
	for command_index: int in range(commands.size()):
		var command: Command = commands[command_index]
		if command == null:
			result._add_rejection(
				&"plan.command_missing",
				"Plan Command at index %d is missing." % command_index
			)
			continue
		if not StableIdentifier.is_valid(command.stable_id):
			result._add_rejection(
				&"plan.command_invalid_id",
				"Plan Command identifier %s is invalid." % command.stable_id
			)
		elif seen_command_ids.has(command.stable_id):
			result._add_rejection(
				&"plan.command_duplicate_id",
				"Plan Command identifier %s is duplicated." % command.stable_id
			)
		seen_command_ids[command.stable_id] = true
		var expected_command_id: StringName = StableIdentifier.format_runtime_identifier(
			&"command",
			next_command_sequence + command_index
		)
		if command.stable_id != expected_command_id:
			result._add_rejection(
				&"plan.command_id_sequence",
				"Plan Command at index %d must use identifier %s."
				% [command_index, expected_command_id]
			)
		if not StableIdentifier.is_valid(command.command_type_id):
			result._add_rejection(
				&"plan.command_type_invalid_id",
				"Plan Command %s type identifier %s is invalid."
				% [command.stable_id, command.command_type_id]
			)
		elif not content_registry.has_command_type(command.command_type_id):
			result._add_rejection(
				&"plan.command_type_unknown",
				"Plan Command %s type identifier %s is unknown."
				% [command.stable_id, command.command_type_id]
			)
		_validate_payload(
			command.payload,
			"Plan Command %s" % command.stable_id,
			&"plan.command_payload_invalid",
			result
		)


static func _validate_attention_event_responses(
		events: Array[AttentionEventState],
		responses: Array[AttentionEventResponse],
		content_registry: SimulationContentRegistry,
		result: PlanValidationResult
	) -> void:
	var events_by_id: Dictionary[StringName, AttentionEventState] = {}
	for event: AttentionEventState in events:
		events_by_id[event.stable_id] = event

	var satisfied_event_ids: Dictionary[StringName, bool] = {}
	var seen_target_ids: Dictionary[StringName, bool] = {}
	for response_index: int in range(responses.size()):
		var response: AttentionEventResponse = responses[response_index]
		if response == null:
			result._add_rejection(
				&"plan.attention_event_response_missing",
				"Plan Attention Event response at index %d is missing." % response_index
			)
			continue
		var target_is_valid: bool = StableIdentifier.is_valid(response.attention_event_id)
		if not target_is_valid:
			result._add_rejection(
				&"plan.attention_event_target_invalid_id",
				"Plan Attention Event target identifier %s is invalid."
				% response.attention_event_id
			)
		if seen_target_ids.has(response.attention_event_id):
			result._add_rejection(
				&"plan.attention_event_target_duplicate",
				"Plan Attention Event target identifier %s is duplicated."
				% response.attention_event_id
			)
		seen_target_ids[response.attention_event_id] = true
		if not StableIdentifier.is_valid(response.response_type_id):
			result._add_rejection(
				&"plan.attention_event_response_type_invalid_id",
				"Plan response type identifier %s is invalid for Attention Event %s."
				% [response.response_type_id, response.attention_event_id]
			)
		_validate_payload(
			response.payload,
			"Plan response for Attention Event %s" % response.attention_event_id,
			&"plan.attention_event_response_payload_invalid",
			result
		)
		if not target_is_valid:
			continue
		if not events_by_id.has(response.attention_event_id):
			result._add_rejection(
				&"plan.attention_event_target_unknown",
				"Plan Attention Event target identifier %s is unknown."
				% response.attention_event_id
			)
			continue
		var event: AttentionEventState = events_by_id[response.attention_event_id]
		var validator: AttentionEventResponseValidator = (
			content_registry.get_attention_event_response_validator(event.event_type_id)
		)
		if validator == null:
			result._add_fault(
				&"plan.attention_event_type_unregistered",
				"Attention Event type %s has no registered Plan response validator."
				% event.event_type_id
			)
			continue
		var response_diagnostics: Array[SimulationDiagnostic] = validator.validate_response(
			event,
			response
		)
		for diagnostic: SimulationDiagnostic in response_diagnostics:
			result._add_rejection_diagnostic(diagnostic)
		if response_diagnostics.is_empty():
			satisfied_event_ids[event.stable_id] = true

	for event: AttentionEventState in events:
		if satisfied_event_ids.has(event.stable_id):
			continue
		result._add_rejection(
			&"plan.attention_event_response_required",
			"Plan must contain a valid response for Attention Event %s." % event.stable_id
		)


static func _validate_payload(
		payload: Dictionary[StringName, Variant],
		owner_name: String,
		diagnostic_code: StringName,
		result: PlanValidationResult
	) -> void:
	var keys: Array[StringName] = []
	keys.assign(payload.keys())
	keys.sort()
	for key: StringName in keys:
		if not StableIdentifier.is_valid_entity_type(key):
			result._add_rejection(
				diagnostic_code,
				"%s payload key %s is invalid." % [owner_name, key]
			)
		var value: Variant = payload[key]
		if value == null or value is Object or typeof(value) == TYPE_CALLABLE or typeof(value) == TYPE_SIGNAL:
			result._add_rejection(
				diagnostic_code,
				"%s payload value for key %s is not deterministic data." % [owner_name, key]
			)
