class_name SimulationStatePath
extends RefCounted

enum Accessor {
	INVALID,
	COMPANY_PUBLIC_TRUST_POINTS,
	COMPANY_GOVERNMENT_TRUST_POINTS,
	COMPANY_PROJECT_TEAM_COUNT,
	COMPANY_COMPUTE_CAPACITY,
	COMPANY_FIXED_OPERATING_COST,
	COMPANY_PROJECTS,
	COMPANY_MODELS,
	COMPANY_APPLICATIONS,
	COMPANY_CONTRACTS,
	WORLD_COMPETITORS,
	WORLD_MODELS,
	WORLD_MARKETS,
	WORLD_TECHNICAL_FRONTIER_CODING,
	WORLD_TECHNICAL_FRONTIER_REASONING,
	WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
	CASH_LEDGER_TRANSACTIONS,
	CALENDAR_MONTH_STEP_INDEX,
	CALENDAR_QUARTER_INDEX,
	PENDING_COMMAND_BATCH,
	ATTENTION_EVENTS,
	NOTIFICATIONS,
	QUARTERLY_REPORTS,
	RUNTIME_EVENT_SEQUENCE,
	RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
	RUNTIME_NOTIFICATION_SEQUENCE,
	RUNTIME_QUARTERLY_REPORT_SEQUENCE,
}

enum ValueType {
	INVALID,
	INTEGER,
	CASH_LEDGER,
	PENDING_COMMAND_BATCH,
	ATTENTION_EVENTS,
	NOTIFICATIONS,
	QUARTERLY_REPORTS,
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
		Accessor.RUNTIME_QUARTERLY_REPORT_SEQUENCE:
			if state.runtime_id_counters == null:
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counters are missing.")
				)
			if not state.runtime_id_counters.next_sequence_by_entity_type.has(&"quarterly_report"):
				return SimulationIntegerResult.failure(
					_access_error("Runtime identifier counter quarterly_report is missing.")
				)
			return SimulationIntegerResult.success(
				state.runtime_id_counters.next_sequence_by_entity_type[&"quarterly_report"]
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
		Accessor.COMPANY_FIXED_OPERATING_COST:
			if state.company == null:
				return SimulationIntegerResult.failure(_access_error("The Company State is missing."))
			return SimulationIntegerResult.success(state.company.fixed_operating_cost_musd_per_month_step)
		Accessor.WORLD_TECHNICAL_FRONTIER_CODING:
			return _read_frontier_integer(state, &"coding")
		Accessor.WORLD_TECHNICAL_FRONTIER_REASONING:
			return _read_frontier_integer(state, &"reasoning")
		Accessor.WORLD_TECHNICAL_FRONTIER_EFFICIENCY:
			return _read_frontier_integer(state, &"efficiency")
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
		Accessor.RUNTIME_QUARTERLY_REPORT_SEQUENCE:
			if state.runtime_id_counters == null:
				return _access_error("Runtime identifier counters are missing.")
			var report_counters: Dictionary[StringName, int] = {}
			report_counters.assign(state.runtime_id_counters.next_sequence_by_entity_type)
			report_counters[&"quarterly_report"] = value
			state.runtime_id_counters.next_sequence_by_entity_type = report_counters
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
		Accessor.WORLD_TECHNICAL_FRONTIER_CODING:
			return _write_frontier_integer(state, &"coding", value)
		Accessor.WORLD_TECHNICAL_FRONTIER_REASONING:
			return _write_frontier_integer(state, &"reasoning", value)
		Accessor.WORLD_TECHNICAL_FRONTIER_EFFICIENCY:
			return _write_frontier_integer(state, &"efficiency", value)
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


func read_quarterly_reports(state: GameState) -> Array[QuarterlyReportState]:
	var reports: Array[QuarterlyReportState] = []
	if state == null or accessor != Accessor.QUARTERLY_REPORTS:
		return reports
	reports.assign(state.quarterly_reports)
	return reports


func write_quarterly_reports(
		state: GameState,
		reports: Array[QuarterlyReportState]
	) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if accessor != Accessor.QUARTERLY_REPORTS:
		return _access_error("State path %s does not contain Quarterly Reports." % stable_id)
	var copied_reports: Array[QuarterlyReportState] = []
	copied_reports.assign(reports)
	state.quarterly_reports = copied_reports
	return null


func read_resource_dictionary(state: GameState) -> Dictionary:
	var resources: Dictionary = {}
	if state == null or value_type != ValueType.RESOURCE_DICTIONARY:
		return resources
	match accessor:
		Accessor.COMPANY_PROJECTS:
			if state.company == null:
				return resources
			resources.assign(state.company.projects)
		Accessor.COMPANY_MODELS:
			if state.company == null:
				return resources
			resources.assign(state.company.models)
		Accessor.COMPANY_APPLICATIONS:
			if state.company == null:
				return resources
			resources.assign(state.company.applications)
		Accessor.COMPANY_CONTRACTS:
			if state.company == null:
				return resources
			resources.assign(state.company.contracts)
		Accessor.WORLD_COMPETITORS:
			if state.world == null:
				return resources
			resources.assign(state.world.competitors)
		Accessor.WORLD_MODELS:
			if state.world == null:
				return resources
			resources.assign(state.world.models)
		Accessor.WORLD_MARKETS:
			if state.world == null:
				return resources
			resources.assign(state.world.markets)
	return resources


func write_resource_dictionary(state: GameState, resources: Dictionary) -> SimulationDiagnostic:
	if state == null:
		return _access_error("The Game State is missing.")
	if value_type != ValueType.RESOURCE_DICTIONARY:
		return _access_error("State path %s does not contain a resource dictionary." % stable_id)
	match accessor:
		Accessor.COMPANY_PROJECTS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			var projects: Dictionary[StringName, ProjectState] = {}
			projects.assign(resources)
			state.company.projects = projects
		Accessor.COMPANY_MODELS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			var models: Dictionary[StringName, ModelState] = {}
			models.assign(resources)
			state.company.models = models
		Accessor.COMPANY_APPLICATIONS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			var applications: Dictionary[StringName, ApplicationState] = {}
			applications.assign(resources)
			state.company.applications = applications
		Accessor.COMPANY_CONTRACTS:
			if state.company == null:
				return _access_error("The Company State is missing.")
			var contracts: Dictionary[StringName, ContractState] = {}
			contracts.assign(resources)
			state.company.contracts = contracts
		Accessor.WORLD_COMPETITORS:
			if state.world == null:
				return _access_error("The World State is missing.")
			var competitors: Dictionary[StringName, CompetitorState] = {}
			competitors.assign(resources)
			state.world.competitors = competitors
		Accessor.WORLD_MODELS:
			if state.world == null:
				return _access_error("The World State is missing.")
			var world_models: Dictionary[StringName, ModelState] = {}
			world_models.assign(resources)
			state.world.models = world_models
		Accessor.WORLD_MARKETS:
			if state.world == null:
				return _access_error("The World State is missing.")
			var markets: Dictionary[StringName, MarketState] = {}
			markets.assign(resources)
			state.world.markets = markets
		_:
			return _access_error("State path %s does not contain a resource dictionary." % stable_id)
	return null


func is_valid_contract() -> bool:
	match accessor:
		Accessor.COMPANY_PUBLIC_TRUST_POINTS, Accessor.COMPANY_GOVERNMENT_TRUST_POINTS:
			return value_type == ValueType.INTEGER
		Accessor.COMPANY_PROJECT_TEAM_COUNT, Accessor.COMPANY_COMPUTE_CAPACITY, Accessor.COMPANY_FIXED_OPERATING_COST:
			return value_type == ValueType.INTEGER
		Accessor.WORLD_TECHNICAL_FRONTIER_CODING, Accessor.WORLD_TECHNICAL_FRONTIER_REASONING, Accessor.WORLD_TECHNICAL_FRONTIER_EFFICIENCY:
			return value_type == ValueType.INTEGER
		Accessor.CALENDAR_MONTH_STEP_INDEX, Accessor.CALENDAR_QUARTER_INDEX:
			return value_type == ValueType.INTEGER
		Accessor.RUNTIME_EVENT_SEQUENCE, Accessor.RUNTIME_LEDGER_TRANSACTION_SEQUENCE, Accessor.RUNTIME_NOTIFICATION_SEQUENCE, Accessor.RUNTIME_QUARTERLY_REPORT_SEQUENCE:
			return value_type == ValueType.INTEGER
		Accessor.CASH_LEDGER_TRANSACTIONS:
			return value_type == ValueType.CASH_LEDGER
		Accessor.PENDING_COMMAND_BATCH:
			return value_type == ValueType.PENDING_COMMAND_BATCH
		Accessor.ATTENTION_EVENTS:
			return value_type == ValueType.ATTENTION_EVENTS
		Accessor.NOTIFICATIONS:
			return value_type == ValueType.NOTIFICATIONS
		Accessor.QUARTERLY_REPORTS:
			return value_type == ValueType.QUARTERLY_REPORTS
		Accessor.COMPANY_PROJECTS, Accessor.COMPANY_MODELS, Accessor.COMPANY_APPLICATIONS, Accessor.COMPANY_CONTRACTS:
			return value_type == ValueType.RESOURCE_DICTIONARY
		Accessor.WORLD_COMPETITORS, Accessor.WORLD_MODELS, Accessor.WORLD_MARKETS:
			return value_type == ValueType.RESOURCE_DICTIONARY
		_:
			return false


func _read_frontier_integer(state: GameState, dimension_id: StringName) -> SimulationIntegerResult:
	if state.world == null:
		return SimulationIntegerResult.failure(_access_error("The World State is missing."))
	if state.world.technical_frontier == null:
		return SimulationIntegerResult.failure(_access_error("The technical frontier is missing."))
	match dimension_id:
		&"coding":
			return SimulationIntegerResult.success(state.world.technical_frontier.coding_evaluation_points)
		&"reasoning":
			return SimulationIntegerResult.success(
				state.world.technical_frontier.reasoning_evaluation_points
			)
		&"efficiency":
			return SimulationIntegerResult.success(
				state.world.technical_frontier.efficiency_evaluation_points
			)
		_:
			return SimulationIntegerResult.failure(
				_access_error("State path %s does not contain an integer." % stable_id)
			)


func _write_frontier_integer(
		state: GameState,
		dimension_id: StringName,
		value: int
	) -> SimulationDiagnostic:
	if state.world == null:
		return _access_error("The World State is missing.")
	if state.world.technical_frontier == null:
		return _access_error("The technical frontier is missing.")
	match dimension_id:
		&"coding":
			state.world.technical_frontier.coding_evaluation_points = value
		&"reasoning":
			state.world.technical_frontier.reasoning_evaluation_points = value
		&"efficiency":
			state.world.technical_frontier.efficiency_evaluation_points = value
		_:
			return _access_error("State path %s does not contain an integer." % stable_id)
	return null


func _access_error(message: String) -> SimulationDiagnostic:
	return SimulationDiagnostic.new(
		SimulationDiagnostic.Severity.ERROR,
		&"state_path.accessor_contract",
		message,
		&"",
		stable_id
	)
