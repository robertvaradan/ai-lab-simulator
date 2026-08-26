class_name SimulationStatePath
extends RefCounted

enum Accessor {
	INVALID,
	COMPANY_PUBLIC_TRUST_POINTS,
	COMPANY_GOVERNMENT_TRUST_POINTS,
	CASH_LEDGER_TRANSACTIONS,
}

enum ValueType {
	INVALID,
	INTEGER,
	CASH_LEDGER,
}

var stable_id: StringName:
	get:
		return _stable_id
var accessor: Accessor:
	get:
		return _accessor
var value_type: ValueType:
	get:
		return _value_type

var _stable_id: StringName
var _accessor: Accessor
var _value_type: ValueType


func _init(p_stable_id: StringName, p_accessor: Accessor, p_value_type: ValueType) -> void:
	_stable_id = p_stable_id
	_accessor = p_accessor
	_value_type = p_value_type


func read_integer(state: GameState) -> SimulationIntegerResult:
	if state == null or state.company == null:
		return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
	match accessor:
		Accessor.COMPANY_PUBLIC_TRUST_POINTS:
			return SimulationIntegerResult.success(state.company.public_trust_points)
		Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			return SimulationIntegerResult.success(state.company.government_trust_points)
		_:
			return SimulationIntegerResult.failure(
				_access_error("State path %s does not contain an integer." % stable_id)
			)


func write_integer(state: GameState, value: int) -> SimulationDiagnostic:
	if state == null or state.company == null:
		return _access_error("The Company State is missing.")
	match accessor:
		Accessor.COMPANY_PUBLIC_TRUST_POINTS:
			state.company.public_trust_points = value
		Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			state.company.government_trust_points = value
		_:
			return _access_error("State path %s does not contain an integer." % stable_id)
	return null


func read_cash_ledger(state: GameState) -> CashLedgerState:
	if state == null or accessor != Accessor.CASH_LEDGER_TRANSACTIONS:
		return null
	return state.cash_ledger


func write_cash_ledger(state: GameState, ledger: CashLedgerState) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if accessor != Accessor.CASH_LEDGER_TRANSACTIONS:
		return _access_error("State path %s does not contain the Cash Ledger." % stable_id)
	if ledger == null:
		return _access_error("The replacement Cash Ledger is missing.")
	state.cash_ledger = ledger
	return null


func is_valid_contract() -> bool:
	match accessor:
		Accessor.COMPANY_PUBLIC_TRUST_POINTS, Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			return value_type == ValueType.INTEGER
		Accessor.CASH_LEDGER_TRANSACTIONS:
			return value_type == ValueType.CASH_LEDGER
		_:
			return false


func _access_error(message: String) -> SimulationDiagnostic:
	return SimulationDiagnostic.new(
		SimulationDiagnostic.Severity.ERROR,
		&"state_path.accessor_contract",
		message,
		&"",
		stable_id
	)
