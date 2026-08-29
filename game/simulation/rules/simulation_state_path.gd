class_name SimulationStatePath
extends RefCounted

enum Accessor {
	INVALID,
	COMPANY_PUBLIC_TRUST_POINTS,
	COMPANY_GOVERNMENT_TRUST_POINTS,
	COMPANY_PROJECT_TEAM_COUNT,
	COMPANY_COMPUTE_CAPACITY,
	COMPANY_PROJECTS,
	COMPANY_MODELS,
	COMPANY_APPLICATIONS,
	COMPANY_CONTRACTS,
	CASH_LEDGER_TRANSACTIONS,
	CALENDAR_MONTH_STEP_INDEX,
	CALENDAR_QUARTER_INDEX,
	PENDING_COMMAND_BATCH,
	ATTENTION_EVENTS,
	NOTIFICATIONS,
	RUNTIME_EVENT_SEQUENCE,
	RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	RUNTIME_NOTIFICATION_SEQUENCE,
}

enum ValueType {
	INVALID,
	INTEGER,
	CASH_LEDGER,
	PENDING_COMMAND_BATCH,
	ATTENTION_EVENTS,
	NOTIFICATIONS,
	RESOURCE_DICTIONARY,
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
		Accessor.RUNTIME_LEDGER_TRANSACTION_SEQUENCE:
			if state.runtime_id_counters == null:
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counters are missing.")
				)
			if not state.runtime_id_counters.next_sequence_by_entity_type.has(&"ledger_transaction"):
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counter ledger_transaction is missing.")
				)
			return SimulationIntegerResult.success(
				state.runtime_id_counters.next_sequence_by_entity_type[&"ledger_transaction"]
			)
		Accessor.RUNTIME_NOTIFICATION_SEQUENCE:
			if state.runtime_id_counters == null:
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counters are missing.")
				)
			if not state.runtime_id_counters.next_sequence_by_entity_type.has(&"notification"):
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counter notification is missing.")
				)
			return SimulationIntegerResult.success(
				state.runtime_id_counters.next_sequence_by_entity_type[&"notification"]
			)
		Accessor.COMPANY_PUBLIC_TRUST_POINTS:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.public_trust_points)
		Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.government_trust_points)
		Accessor.COMPANY_PROJECT_TEAM_COUNT:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.project_team_count)
		Accessor.COMPANY_COMPUTE_CAPACITY:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.compute_capacity_unit_months)
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
		Accessor.RUNTIME_LEDGER_TRANSACTION_SEQUENCE:
			if state.runtime_id_counters == null:
				return _access_error("Runtime identifier counters are missing.")
			var ledger_counters: Dictionary[StringName, int] = {}
			ledger_counters.assign(state.runtime_id_counters.next_sequence_by_entity_type)
			ledger_counters[&"ledger_transaction"] = value
			state.runtime_id_counters.next_sequence_by_entity_type = ledger_counters
		Accessor.RUNTIME_NOTIFICATION_SEQUENCE:
			if state.runtime_id_counters == null:
				return _access_error("Runtime identifier counters are missing.")
			var notification_counters: Dictionary[StringName, int] = {}
			notification_counters.assign(state.runtime_id_counters.next_sequence_by_entity_type)
			notification_counters[&"notification"] = value
			state.runtime_id_counters.next_sequence_by_entity_type = notification_counters
		Accessor.COMPANY_PUBLIC_TRUST_POINTS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			state.company.public_trust_points = value
		Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			state.company.government_trust_points = value
		Accessor.COMPANY_COMPUTE_CAPACITY:
			if state.company == null:
				return _access_error("The Company State is missing.")
			state.company.compute_capacity_unit_months = value
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


func read_notifications(state: GameState) -> Array[NotificationState]:
	var notifications: Array[NotificationState] = []
	if state == null or accessor != Accessor.NOTIFICATIONS:
		return notifications
	notifications.assign(state.notifications)
	return notifications


func write_notifications(
		state: GameState,
		notifications: Array[NotificationState]
	) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if accessor != Accessor.NOTIFICATIONS:
		return _access_error("State path %s does not contain Notifications." % stable_id)
	var copied_notifications: Array[NotificationState] = []
	copied_notifications.assign(notifications)
	state.notifications = copied_notifications
	return null


func read_resource_dictionary(state: GameState) -> Dictionary:
	var resources: Dictionary = {}
	if state == null or state.company == null or value_type != ValueType.RESOURCE_DICTIONARY:
		return resources
	match accessor:
		Accessor.COMPANY_PROJECTS:
			resources.assign(state.company.projects)
		Accessor.COMPANY_MODELS:
			resources.assign(state.company.models)
		Accessor.COMPANY_APPLICATIONS:
			resources.assign(state.company.applications)
		Accessor.COMPANY_CONTRACTS:
			resources.assign(state.company.contracts)
	return resources


func write_resource_dictionary(state: GameState, resources: Dictionary) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if state.company == null:
		return _access_error("The Company State is missing.")
	if value_type != ValueType.RESOURCE_DICTIONARY:
		return _access_error("State path %s does not contain a resource dictionary." % stable_id)
	match accessor:
		Accessor.COMPANY_PROJECTS:
			var projects: Dictionary[StringName, ProjectState] = {}
			projects.assign(resources)
			state.company.projects = projects
		Accessor.COMPANY_MODELS:
			var models: Dictionary[StringName, ModelState] = {}
			models.assign(resources)
			state.company.models = models
		Accessor.COMPANY_APPLICATIONS:
			var applications: Dictionary[StringName, ApplicationState] = {}
			applications.assign(resources)
			state.company.applications = applications
		Accessor.COMPANY_CONTRACTS:
			var contracts: Dictionary[StringName, ContractState] = {}
			contracts.assign(resources)
			state.company.contracts = contracts
		_:
			return _access_error("State path %s does not contain a resource dictionary." % stable_id)
	return null


func is_valid_contract() -> bool:
	match accessor:
		Accessor.COMPANY_PUBLIC_TRUST_POINTS, Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			return value_type == ValueType.INTEGER
		Accessor.COMPANY_PROJECT_TEAM_COUNT, Accessor.COMPANY_COMPUTE_CAPACITY:
			return value_type == ValueType.INTEGER
		Accessor.CALENDAR_MONTH_STEP_INDEX, Accessor.CALENDAR_QUARTER_INDEX:
			return value_type == ValueType.INTEGER
		Accessor.RUNTIME_EVENT_SEQUENCE, Accessor.RUNTIME_LEDGER_TRANSACTION_SEQUENCE, Accessor.RUNTIME_NOTIFICATION_SEQUENCE:
			return value_type == ValueType.INTEGER
		Accessor.CASH_LEDGER_TRANSACTIONS:
			return value_type == ValueType.CASH_LEDGER
		Accessor.PENDING_COMMAND_BATCH:
			return value_type == ValueType.PENDING_COMMAND_BATCH
		Accessor.ATTENTION_EVENTS:
			return value_type == ValueType.ATTENTION_EVENTS
		Accessor.NOTIFICATIONS:
			return value_type == ValueType.NOTIFICATIONS
		Accessor.COMPANY_PROJECTS, Accessor.COMPANY_MODELS, Accessor.COMPANY_APPLICATIONS, Accessor.COMPANY_CONTRACTS:
			return value_type == ValueType.RESOURCE_DICTIONARY
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
