class_name SimulationAdvanceAction
extends RefCounted

var _core: SimulationCore
var _game_state_service: GameStateService
var _session_traces: Array[SimulationTrace] = []


func _init(core: SimulationCore, game_state_service: GameStateService) -> void:
	_core = core
	_game_state_service = game_state_service


func execute(plan: Plan) -> SimulationOperationResult:
	var commit_result: SimulationOperationResult = _core.commit_plan(
		_game_state_service.get_current_state(),
		plan
	)
	_append_trace(commit_result)
	if not commit_result.is_successful():
		return commit_result
	var advance_result: SimulationOperationResult = _core.advance_until_attention_required(
		commit_result.candidate_state
	)
	_append_trace(advance_result)
	if not advance_result.is_successful():
		return advance_result
	var publication: GameStateValidationResult = _game_state_service.publish_operation_result(
		advance_result
	)
	if publication.is_valid():
		return advance_result
	var diagnostics: Array[SimulationDiagnostic] = []
	for publication_error: String in publication.errors:
		diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"advance_action.publication_failed",
				publication_error
			)
		)
	return SimulationOperationResult.new(
		SimulationOperationOutcome.Type.FAULTED,
		null,
		advance_result.trace,
		diagnostics
	)


func get_session_traces() -> Array[SimulationTrace]:
	var traces: Array[SimulationTrace] = []
	traces.assign(_session_traces)
	return traces


func _append_trace(operation_result: SimulationOperationResult) -> void:
	if operation_result == null or operation_result.trace == null:
		return
	_session_traces.append(operation_result.trace)
