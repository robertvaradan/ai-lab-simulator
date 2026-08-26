class_name SimulationRuleEvaluation
extends RefCounted

enum Status {
	FIRED,
	DID_NOT_FIRE,
	FAILED,
}

var status: Status
var diagnostic: SimulationDiagnostic


func _init(p_status: Status, p_diagnostic: SimulationDiagnostic = null) -> void:
	status = p_status
	diagnostic = p_diagnostic


static func fired() -> SimulationRuleEvaluation:
	return SimulationRuleEvaluation.new(Status.FIRED)


static func did_not_fire() -> SimulationRuleEvaluation:
	return SimulationRuleEvaluation.new(Status.DID_NOT_FIRE)


static func failed(p_diagnostic: SimulationDiagnostic) -> SimulationRuleEvaluation:
	return SimulationRuleEvaluation.new(Status.FAILED, p_diagnostic)
