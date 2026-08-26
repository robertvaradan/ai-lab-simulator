class_name SimulationIntegerResult
extends RefCounted

var has_value: bool = false
var value: int
var diagnostic: SimulationDiagnostic


static func success(p_value: int) -> SimulationIntegerResult:
	var result: SimulationIntegerResult = SimulationIntegerResult.new()
	result.has_value = true
	result.value = p_value
	return result


static func failure(p_diagnostic: SimulationDiagnostic) -> SimulationIntegerResult:
	var result: SimulationIntegerResult = SimulationIntegerResult.new()
	result.diagnostic = p_diagnostic
	return result
