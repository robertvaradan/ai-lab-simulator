class_name SimulationOperationResult
extends RefCounted

var outcome: SimulationOperationOutcome.Type:
	get:
		return _outcome
var candidate_state: GameState:
	get:
		return _candidate_state
var trace: SimulationTrace:
	get:
		return _trace
var diagnostics: Array[SimulationDiagnostic]:
	get:
		var copied_diagnostics: Array[SimulationDiagnostic] = []
		copied_diagnostics.assign(_diagnostics)
		return copied_diagnostics

var _outcome: SimulationOperationOutcome.Type
var _candidate_state: GameState
var _trace: SimulationTrace
var _diagnostics: Array[SimulationDiagnostic] = []


func _init(
		p_outcome: SimulationOperationOutcome.Type,
		p_candidate_state: GameState,
		p_trace: SimulationTrace,
		p_diagnostics: Array[SimulationDiagnostic]
	) -> void:
	_diagnostics.assign(p_diagnostics)
	if p_trace == null:
		_trace = SimulationTrace.new(&"operation.result_contract_fault", 0)
		_trace._append_contract_fault(&"operation_result.missing_trace")
		_trace._seal()
		_outcome = SimulationOperationOutcome.Type.FAULTED
		_candidate_state = null
		_diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"operation_result.missing_trace",
				"A Simulation Operation Result must contain a Simulation Trace."
			)
		)
		return
	_trace = p_trace
	_trace._seal()
	var can_expose_candidate: bool = (
		p_outcome == SimulationOperationOutcome.Type.COMPLETED
		or p_outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED
	)
	if can_expose_candidate != (p_candidate_state != null):
		_outcome = SimulationOperationOutcome.Type.FAULTED
		_candidate_state = null
		_diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"operation_result.candidate_contract",
				"The operation outcome and candidate Game State are inconsistent."
			)
		)
		return
	if p_outcome == SimulationOperationOutcome.Type.REJECTED and _diagnostics.is_empty():
		_outcome = SimulationOperationOutcome.Type.FAULTED
		_candidate_state = null
		_diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"operation_result.missing_rejection_diagnostic",
				"A rejected operation must identify its expected rejection."
			)
		)
		return
	if p_outcome == SimulationOperationOutcome.Type.FAULTED and _diagnostics.is_empty():
		_diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"operation_result.missing_fault_diagnostic",
				"A faulted operation must identify its contract fault."
			)
		)
	_outcome = p_outcome
	_candidate_state = p_candidate_state


func is_successful() -> bool:
	return (
		_outcome == SimulationOperationOutcome.Type.COMPLETED
		or _outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED
	)


func has_candidate_state() -> bool:
	return _candidate_state != null
