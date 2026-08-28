class_name SimulationStatePath
extends RefCounted

enum Accessor {
	INVALID,
	COMPANY_PUBLIC_TRUST_POINTS,
	COMPANY_GOVERNMENT_TRUST_POINTS,
	CASH_LEDGER_TRANSACTIONS,
	CALENDAR_MONTH_STEP_INDEX,
	CALENDAR_QUARTER_INDEX,
	PENDING_COMMAND_BATCH,
	ATTENTION_EVENTS,
	RUNTIME_EVENT_SEQUENCE,
}

enum ValueType {
	INVALID,
	INTEGER,
	CASH_LEDGER,
	PENDING_COMMAND_BATCH,
	ATTENTION_EVENTS,
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
	if state == null:
		return SimulationIntegerResult.failure(_access_error("The Game State is missing."))
	match accessor:
		Accessor.CALENDAR_MONTH_STEP_INDEX:
			if state.calendar == null:
				return SimulationIntegerResult.failure(_access_error("The Calendar State is missing."))
			return SimulationIntegerResult.success(state.calendar.current_month_step_index)
		Accessor.CALENDAR_QUARTER_INDEX:
			if state.calendar == null:
				return SimulationIntegerResult.failure(_access_error("The Calendar State is missing."))
			return SimulationIntegerResult.success(state.calendar.current_quarter_index)
		Accessor.RUNTIME_EVENT_SEQUENCE:
			if state.runtime_id_counters == null:
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counters are missing.")
				)
			if not state.runtime_id_counters.next_sequence_by_entity_type.has(&"event"):
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counter event is missing.")
				)
			return SimulationIntegerResult.success(
				state.runtime_id_counters.next_sequence_by_entity_type[&"event"]
			)
		Accessor.COMPANY_PUBLIC_TRUST_POINTS:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.public_trust_points)
		Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.government_trust_points)
		_:
			return SimulationIntegerResult.failure(
				_access_error("State path %s does not contain an integer." % stable_id)
			)


func write_integer(state: GameState, value: int) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	match accessor:
		Accessor.CALENDAR_MONTH_STEP_INDEX:
			if state.calendar == null:
				return _access_error("The Calendar State is missing.")
			state.calendar.current_month_step_index = value
		Accessor.CALENDAR_QUARTER_INDEX:
			if state.calendar == null:
				return _access_error("The Calendar State is missing.")
			state.calendar.current_quarter_index = value
		Accessor.RUNTIME_EVENT_SEQUENCE:
			if state.runtime_id_counters == null:
				return _access_error("Runtime identifier counters are missing.")
			var next_counters: Dictionary[StringName, int] = {}
			next_counters.assign(state.runtime_id_counters.next_sequence_by_entity_type)
			next_counters[&"event"] = value
			state.runtime_id_counters.next_sequence_by_entity_type = next_counters
		Accessor.COMPANY_PUBLIC_TRUST_POINTS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			state.company.public_trust_points = value
		Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			if state.company == null:
				return _access_error("The Company State is missing.")
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


func read_pending_command_batch(state: GameState) -> PendingCommandBatchState:
	if state == null or accessor != Accessor.PENDING_COMMAND_BATCH:
		return null
	return state.pending_command_batch


func write_pending_command_batch(
		state: GameState,
		batch: PendingCommandBatchState
	) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if accessor != Accessor.PENDING_COMMAND_BATCH:
		return _access_error("State path %s does not contain the Pending Command Batch." % stable_id)
	state.pending_command_batch = batch
	return null


func read_attention_events(state: GameState) -> Array[AttentionEventState]:
	var events: Array[AttentionEventState] = []
	if state == null or accessor != Accessor.ATTENTION_EVENTS:
		return events
	events.assign(state.attention_events)
	return events


func write_attention_events(
		state: GameState,
		events: Array[AttentionEventState]
	) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if accessor != Accessor.ATTENTION_EVENTS:
		return _access_error("State path %s does not contain Attention Events." % stable_id)
	var copied_events: Array[AttentionEventState] = []
	copied_events.assign(events)
	state.attention_events = copied_events
	return null


func is_valid_contract() -> bool:
	match accessor:
		Accessor.COMPANY_PUBLIC_TRUST_POINTS, Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			return value_type == ValueType.INTEGER
		Accessor.CALENDAR_MONTH_STEP_INDEX, Accessor.CALENDAR_QUARTER_INDEX, Accessor.RUNTIME_EVENT_SEQUENCE:
			return value_type == ValueType.INTEGER
		Accessor.CASH_LEDGER_TRANSACTIONS:
			return value_type == ValueType.CASH_LEDGER
		Accessor.PENDING_COMMAND_BATCH:
			return value_type == ValueType.PENDING_COMMAND_BATCH
		Accessor.ATTENTION_EVENTS:
			return value_type == ValueType.ATTENTION_EVENTS
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
