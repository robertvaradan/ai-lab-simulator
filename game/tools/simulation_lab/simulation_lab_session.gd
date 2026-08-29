class_name SimulationLabSession
extends RefCounted

const DEFAULT_SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"

var _definition: MarketingScenarioDefinition
var _core: SimulationCore
var _state: GameState
var _traces: Array[SimulationTrace] = []
var _staged_commands: Array[Command] = []
var _staged_attention_responses: Array[AttentionEventResponse] = []
var _exported_operations: Array[Dictionary] = []
var _last_result: SimulationOperationResult


static func create_marketing_scenario(path: String = DEFAULT_SCENARIO_PATH) -> SimulationLabSessionResult:
	var result: SimulationLabSessionResult = SimulationLabSessionResult.new()
	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(path)
	if definition == null:
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_lab.missing_scenario",
				"The Marketing Scenario definition did not load: %s" % path
			)
		)
		return result
	var state_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	if not state_result.succeeded():
		for error_message: String in state_result.errors:
			result.diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"simulation_lab.invalid_starting_state",
					error_message
				)
			)
		return result
	var construction: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		definition,
		state_result.state
	)
	if not construction.succeeded():
		result.diagnostics.append_array(construction.diagnostics)
		return result
	var session: SimulationLabSession = SimulationLabSession.new()
	session._definition = definition
	session._core = construction.core
	session._state = state_result.state
	result.session = session
	return result


func get_definition() -> MarketingScenarioDefinition:
	return _definition


func get_core() -> SimulationCore:
	return _core


func get_state() -> GameState:
	return _state


func get_cash_ledger() -> CashLedgerState:
	if _state == null:
		return null
	return _state.cash_ledger


func get_traces() -> Array[SimulationTrace]:
	var traces: Array[SimulationTrace] = []
	traces.assign(_traces)
	return traces


func get_last_result() -> SimulationOperationResult:
	return _last_result


func get_exported_operations() -> Array[Dictionary]:
	var operations: Array[Dictionary] = []
	operations.assign(_exported_operations)
	return operations


func stage_command(command: Command) -> void:
	if command == null:
		return
	_staged_commands.append(command)


func stage_attention_response(response: AttentionEventResponse) -> void:
	if response == null:
		return
	_staged_attention_responses.append(response)


func clear_staged_plan() -> void:
	_staged_commands.clear()
	_staged_attention_responses.clear()


func validate_staged_plan() -> PlanValidationResult:
	return _core.validate_plan(_state, _build_staged_plan())


func commit_staged_plan() -> SimulationOperationResult:
	var plan: Plan = _build_staged_plan()
	var result: SimulationOperationResult = _core.commit_plan(_state, plan)
	_record_operation(SimulationCore.COMMIT_PLAN_OPERATION_ID, plan, result)
	_apply_successful_result(result)
	if result.is_successful():
		clear_staged_plan()
	return result


func step_month() -> SimulationOperationResult:
	var result: SimulationOperationResult = _core.step_month(_state)
	_record_operation(SimulationCore.STEP_MONTH_OPERATION_ID, Plan.new(), result)
	_apply_successful_result(result)
	return result


func advance_until_attention_required() -> SimulationOperationResult:
	var result: SimulationOperationResult = _core.advance_until_attention_required(_state)
	_record_operation(SimulationCore.ADVANCE_UNTIL_ATTENTION_REQUIRED_OPERATION_ID, Plan.new(), result)
	_apply_successful_result(result)
	return result


func save_snapshot(path: String) -> GameStateSaveResult:
	return GameStateSnapshotStore.save_snapshot(
		_state,
		path,
		_definition.stable_id,
		_definition.content_version,
		_definition.rule_graph_id,
		_definition.rule_graph_version,
		_definition.build_content_reference_catalog()
	)


func load_snapshot(path: String) -> GameStateLoadResult:
	var load_result: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
		path,
		_definition.stable_id,
		_definition.content_version,
		_definition.rule_graph_id,
		_definition.rule_graph_version,
		_definition.build_content_reference_catalog()
	)
	if load_result.succeeded():
		_state = load_result.state
	return load_result


func replay_exported_operations() -> SimulationLabReplayResult:
	return replay_operations(_exported_operations)


func replay_operations(operations: Array[Dictionary]) -> SimulationLabReplayResult:
	var result: SimulationLabReplayResult = SimulationLabReplayResult.new()
	var reconstructed: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	if not reconstructed.succeeded():
		result.diagnostics.append_array(reconstructed.diagnostics)
		return result
	result.session = reconstructed.session
	for operation: Dictionary in operations:
		var operation_result: SimulationOperationResult = result.session._apply_exported_operation(operation)
		if operation_result == null:
			result.diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"simulation_lab.unknown_replay_operation",
					"The replay contains an unknown laboratory operation."
				)
			)
			return result
		if not operation_result.is_successful():
			result.diagnostics.append_array(operation_result.diagnostics)
			return result
	if var_to_bytes_with_objects(_state) != var_to_bytes_with_objects(result.session.get_state()):
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_lab.replay_state_mismatch",
				"The replay Game State does not match the original Game State."
			)
		)
		return result
	if var_to_bytes_with_objects(_state.cash_ledger) != var_to_bytes_with_objects(result.session.get_cash_ledger()):
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_lab.replay_ledger_mismatch",
				"The replay Cash Ledger does not match the original Cash Ledger."
			)
		)
		return result
	var original_traces: Array[SimulationTrace] = get_traces()
	var replay_traces: Array[SimulationTrace] = result.session.get_traces()
	if original_traces.size() != replay_traces.size():
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_lab.replay_trace_count_mismatch",
				"The replay Simulation Trace count does not match the original count."
			)
		)
		return result
	for trace_index: int in range(original_traces.size()):
		if original_traces[trace_index].to_canonical_data() != replay_traces[trace_index].to_canonical_data():
			result.diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"simulation_lab.replay_trace_mismatch",
					"Simulation Trace %d does not match the original trace." % trace_index
				)
			)
			return result
	result.matched = true
	return result


func _build_staged_plan() -> Plan:
	var plan: Plan = Plan.new()
	plan.commands.assign(_staged_commands)
	plan.attention_event_responses.assign(_staged_attention_responses)
	return plan


func _apply_successful_result(result: SimulationOperationResult) -> void:
	_last_result = result
	if result == null:
		return
	if result.trace != null:
		_traces.append(result.trace)
	if result.is_successful() and result.has_candidate_state():
		_state = result.candidate_state


func _record_operation(
		operation_id: StringName,
		plan: Plan,
		result: SimulationOperationResult
	) -> void:
	if result == null or not result.is_successful():
		return
	var record: Dictionary = {
		&"operation_id": operation_id,
		&"commands": _export_commands(plan.commands),
		&"attention_event_responses": _export_attention_responses(plan.attention_event_responses),
	}
	_exported_operations.append(record)


func _apply_exported_operation(operation: Dictionary) -> SimulationOperationResult:
	if not operation.has(&"operation_id"):
		return null
	var operation_id: StringName = StringName(str(operation[&"operation_id"]))
	if operation_id == SimulationCore.COMMIT_PLAN_OPERATION_ID:
		clear_staged_plan()
		var commands: Array[Command] = []
		if operation.has(&"commands"):
			commands = _import_commands(operation[&"commands"])
		for command: Command in commands:
			stage_command(command)
		var responses: Array[AttentionEventResponse] = []
		if operation.has(&"attention_event_responses"):
			responses = _import_attention_responses(operation[&"attention_event_responses"])
		for response: AttentionEventResponse in responses:
			stage_attention_response(response)
		return commit_staged_plan()
	if operation_id == SimulationCore.STEP_MONTH_OPERATION_ID:
		return step_month()
	if operation_id == SimulationCore.ADVANCE_UNTIL_ATTENTION_REQUIRED_OPERATION_ID:
		return advance_until_attention_required()
	return null


func _export_commands(commands: Array[Command]) -> Array:
	var exported: Array = []
	for command: Command in commands:
		if command == null:
			continue
		exported.append(
			{
				&"stable_id": command.stable_id,
				&"command_type_id": command.command_type_id,
				&"payload": command.payload.duplicate(true),
			}
		)
	return exported


func _export_attention_responses(responses: Array[AttentionEventResponse]) -> Array:
	var exported: Array = []
	for response: AttentionEventResponse in responses:
		if response == null:
			continue
		exported.append(
			{
				&"attention_event_id": response.attention_event_id,
				&"response_type_id": response.response_type_id,
				&"payload": response.payload.duplicate(true),
			}
		)
	return exported


func _import_commands(exported_value: Variant) -> Array[Command]:
	var commands: Array[Command] = []
	if typeof(exported_value) != TYPE_ARRAY:
		return commands
	var exported_commands: Array = exported_value
	for exported_command_value: Variant in exported_commands:
		if typeof(exported_command_value) != TYPE_DICTIONARY:
			continue
		var exported_command: Dictionary = exported_command_value
		var command: Command = Command.new()
		if exported_command.has(&"stable_id"):
			command.stable_id = StringName(str(exported_command[&"stable_id"]))
		if exported_command.has(&"command_type_id"):
			command.command_type_id = StringName(str(exported_command[&"command_type_id"]))
		var payload: Dictionary[StringName, Variant] = {}
		if exported_command.has(&"payload") and typeof(exported_command[&"payload"]) == TYPE_DICTIONARY:
			var exported_payload: Dictionary = exported_command[&"payload"]
			for payload_key: Variant in exported_payload.keys():
				payload[StringName(str(payload_key))] = exported_payload[payload_key]
		command.payload = payload
		commands.append(command)
	return commands


func _import_attention_responses(exported_value: Variant) -> Array[AttentionEventResponse]:
	var responses: Array[AttentionEventResponse] = []
	if typeof(exported_value) != TYPE_ARRAY:
		return responses
	var exported_responses: Array = exported_value
	for exported_response_value: Variant in exported_responses:
		if typeof(exported_response_value) != TYPE_DICTIONARY:
			continue
		var exported_response: Dictionary = exported_response_value
		var response: AttentionEventResponse = AttentionEventResponse.new()
		if exported_response.has(&"attention_event_id"):
			response.attention_event_id = StringName(str(exported_response[&"attention_event_id"]))
		if exported_response.has(&"response_type_id"):
			response.response_type_id = StringName(str(exported_response[&"response_type_id"]))
		var payload: Dictionary[StringName, Variant] = {}
		if exported_response.has(&"payload") and typeof(exported_response[&"payload"]) == TYPE_DICTIONARY:
			var exported_payload: Dictionary = exported_response[&"payload"]
			for payload_key: Variant in exported_payload.keys():
				payload[StringName(str(payload_key))] = exported_payload[payload_key]
		response.payload = payload
		responses.append(response)
	return responses
